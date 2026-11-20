import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../backup/backup_service.dart';
import '../isar_open.dart';
import 'cloud_backup_config.dart';
import 'drive_backup_service.dart';

/// SharedPreferences keys for the cloud backup feature.
class CloudBackupPrefs {
  CloudBackupPrefs._();
  static const enabled = 'cloud_backup_enabled';
  static const account = 'cloud_backup_account';
  static const hour = 'cloud_backup_hour';
  static const minute = 'cloud_backup_minute';
  static const lastSuccess = 'cloud_backup_last_success'; // ISO local time
  static const lastStatus = 'cloud_backup_last_status';
  static const lastFailure = 'cloud_backup_last_failure';
}

const _kTaskName = 'holdstrong_cloud_backup';
const _kTag = 'holdstrong_cloud_backup';

/// Entry point for the background isolate. Must be a top-level function.
@pragma('vm:entry-point')
void cloudBackupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // pick up values written by the UI isolate
    if (!(prefs.getBool(CloudBackupPrefs.enabled) ?? false)) return true;

    // Queue tomorrow's run FIRST so one failure can never end the chain.
    await CloudBackupScheduler.scheduleNext(prefs);

    final result = await CloudBackupScheduler.runNow(prefs);
    // false => WorkManager retries with backoff (e.g. transient network error).
    return result.isSuccess;
  });
}

class CloudBackupScheduler {
  CloudBackupScheduler._();

  /// Call once from `main()`.
  static Future<void> initialize() =>
      Workmanager().initialize(cloudBackupCallbackDispatcher);

  static ({int hour, int minute}) timeOf(SharedPreferences prefs) => (
        hour: prefs.getInt(CloudBackupPrefs.hour) ?? 23,
        minute: prefs.getInt(CloudBackupPrefs.minute) ?? 59,
      );

  /// The next wall-clock occurrence of the configured time, strictly after [from].
  static DateTime nextRunAfter(SharedPreferences prefs, DateTime from) {
    final t = timeOf(prefs);
    var next = DateTime(from.year, from.month, from.day, t.hour, t.minute);
    if (!next.isAfter(from)) next = next.add(const Duration(days: 1));
    // DateTime(…) rather than +24h keeps the time stable across DST changes.
    return DateTime(next.year, next.month, next.day, t.hour, t.minute);
  }

  /// The most recent scheduled moment at or before [now].
  static DateTime lastScheduledBefore(SharedPreferences prefs, DateTime now) {
    final t = timeOf(prefs);
    var last = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    if (last.isAfter(now)) last = last.subtract(const Duration(days: 1));
    return DateTime(last.year, last.month, last.day, t.hour, t.minute);
  }

  /// Queue the next daily run. Unique name is per target date with `keep`, so
  /// calling this repeatedly (every app open) never duplicates or cancels a
  /// run that is currently executing.
  static Future<void> scheduleNext(SharedPreferences prefs) async {
    final now = DateTime.now();
    final target = nextRunAfter(prefs, now);
    final name = '${_kTaskName}_${target.year}-${target.month}-${target.day}';
    await Workmanager().registerOneOffTask(
      name,
      _kTaskName,
      tag: _kTag,
      initialDelay: target.difference(now),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  /// Enable/reschedule (e.g. after the time changed).
  static Future<void> enable(SharedPreferences prefs) async {
    await prefs.setBool(CloudBackupPrefs.enabled, true);
    await Workmanager().cancelByTag(_kTag);
    await scheduleNext(prefs);
  }

  static Future<void> disable(SharedPreferences prefs) async {
    await prefs.setBool(CloudBackupPrefs.enabled, false);
    await Workmanager().cancelByTag(_kTag);
  }

  /// Run a backup immediately in this isolate and record the outcome.
  static Future<CloudBackupResult> runNow(SharedPreferences prefs) async {
    CloudBackupResult result;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final isar = await openHoldStrongIsar(dir.path);
      result = await DriveBackupService.instance
          .runBackup(BackupService(isar, prefs));
    } catch (e) {
      result = CloudBackupResult.failure(e.toString());
    }
    if (result.isSuccess) {
      await prefs.setString(
          CloudBackupPrefs.lastSuccess, DateTime.now().toIso8601String());
      await prefs.setString(CloudBackupPrefs.lastStatus, result.message!);
      await prefs.remove(CloudBackupPrefs.lastFailure);
    } else {
      await prefs.setString(CloudBackupPrefs.lastFailure, result.error!);
    }
    return result;
  }

  /// App-open safety net. Makes sure a run is queued, and if the last
  /// scheduled time passed without a successful backup (phone off, battery
  /// saver killed the job, no network…), uploads right now.
  static Future<void> onAppOpen(SharedPreferences prefs) async {
    if (!CloudBackupConfig.isConfigured) return;
    if (!(prefs.getBool(CloudBackupPrefs.enabled) ?? false)) return;

    await scheduleNext(prefs);

    final now = DateTime.now();
    final lastOk = DateTime.tryParse(
        prefs.getString(CloudBackupPrefs.lastSuccess) ?? '');
    final due = lastOk == null ||
        lastOk.isBefore(lastScheduledBefore(prefs, now));
    if (due) {
      await runNow(prefs); // intentionally not awaited by caller
    }
  }
}
