import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme.dart';
import '../../../data/cloud/cloud_backup_config.dart';
import '../../../data/cloud/cloud_backup_scheduler.dart';
import '../../../data/cloud/drive_backup_service.dart';
import '../../../domain/providers/recalibration_provider.dart';

/// Settings block for the daily Google Drive backup.
class CloudBackupSection extends ConsumerStatefulWidget {
  const CloudBackupSection({super.key});

  @override
  ConsumerState<CloudBackupSection> createState() => _CloudBackupSectionState();
}

class _CloudBackupSectionState extends ConsumerState<CloudBackupSection> {
  bool _busy = false;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  void initState() {
    super.initState();
    // The background worker writes status from another isolate.
    _prefs.reload().then((_) {
      if (mounted) setState(() {});
    });
  }

  bool get _enabled => _prefs.getBool(CloudBackupPrefs.enabled) ?? false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _guard(() async {
        try {
          final email = await DriveBackupService.instance.connect();
          await _prefs.setString(CloudBackupPrefs.account, email);
          await CloudBackupScheduler.enable(_prefs);
          _snack('Connected as $email');
          // First backup straight away so you can see it work.
          final r = await CloudBackupScheduler.runNow(_prefs);
          _snack(r.isSuccess ? r.message! : 'Backup failed: ${r.error}');
        } catch (e) {
          _snack('Could not connect: $e');
        }
      });

  Future<void> _disconnect() => _guard(() async {
        try {
          await CloudBackupScheduler.disable(_prefs);
          await DriveBackupService.instance.disconnect();
          await _prefs.remove(CloudBackupPrefs.account);
          _snack('Disconnected. Existing Drive files were left untouched.');
        } catch (e) {
          _snack('Disconnect failed: $e');
        }
      });

  Future<void> _backupNow() => _guard(() async {
        final r = await CloudBackupScheduler.runNow(_prefs);
        _snack(r.isSuccess ? r.message! : 'Backup failed: ${r.error}');
      });

  Future<void> _pickTime() async {
    final t = CloudBackupScheduler.timeOf(_prefs);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
    );
    if (picked == null) return;
    await _prefs.setInt(CloudBackupPrefs.hour, picked.hour);
    await _prefs.setInt(CloudBackupPrefs.minute, picked.minute);
    if (_enabled) await CloudBackupScheduler.enable(_prefs);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!CloudBackupConfig.isConfigured) {
      return _Tile(
        icon: Icons.cloud_off_outlined,
        label: 'GOOGLE DRIVE BACKUP',
        sublabel: 'Not set up — tap for details',
        onTap: () => _snack(
            'Add your Google web client ID to webClientId in '
            'lib/data/cloud/cloud_backup_config.dart, then rebuild the app.'),
      );
    }

    final enabled = _enabled;
    final account = _prefs.getString(CloudBackupPrefs.account);
    final t = CloudBackupScheduler.timeOf(_prefs);
    final timeLabel = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay(hour: t.hour, minute: t.minute));
    final lastOk =
        DateTime.tryParse(_prefs.getString(CloudBackupPrefs.lastSuccess) ?? '');
    final failure = _prefs.getString(CloudBackupPrefs.lastFailure);

    final status = StringBuffer();
    if (lastOk != null) {
      status.write('Last backup: ${DateFormat('d MMM, h:mm a').format(lastOk)}');
      final msg = _prefs.getString(CloudBackupPrefs.lastStatus);
      if (msg != null) status.write('\n$msg');
    } else {
      status.write('No backup yet');
    }
    if (failure != null) status.write('\nLast attempt failed: $failure');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Tile(
          icon: enabled ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
          label: enabled ? 'DRIVE BACKUP: ON' : 'CONNECT GOOGLE DRIVE',
          sublabel: enabled
              ? 'Signed in as ${account ?? 'Google account'} · tap to disconnect'
              : 'Back up daily to your Drive so your PC can read it',
          loading: _busy,
          onTap: enabled ? _disconnect : _connect,
        ),
        if (enabled) ...[
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.schedule_outlined,
            label: 'DAILY AT $timeLabel',
            sublabel: 'Android may run it a few minutes late. '
                'Missed runs are caught up when you open the app.',
            onTap: _pickTime,
          ),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.backup_outlined,
            label: 'BACK UP NOW',
            sublabel: status.toString(),
            loading: _busy,
            onTap: _backupNow,
          ),
          const SizedBox(height: 8),
          const Text(
            'Drive folder "${CloudBackupConfig.rootFolderName}": transactions.csv '
            '(updated daily), last ${CloudBackupConfig.maxDailyBackups} daily '
            'JSON backups, plus one permanent snapshot per month.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.sublabel,
    this.loading = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentGold, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.accentGold),
              )
            else if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
