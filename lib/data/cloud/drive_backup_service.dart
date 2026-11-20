import 'dart:async';
import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../backup/backup_service.dart';
import 'cloud_backup_config.dart';

class CloudBackupResult {
  const CloudBackupResult.success(this.message) : error = null;
  const CloudBackupResult.failure(this.error) : message = null;

  final String? message;
  final String? error;

  bool get isSuccess => error == null;
}

/// Thrown when there is no usable Google authorization (never connected,
/// access revoked, or it needs the user to interact).
class CloudAuthRequired implements Exception {
  const CloudAuthRequired([this.detail]);
  final String? detail;
  @override
  String toString() => 'Google Drive is not connected${detail == null ? '' : ' ($detail)'}';
}

class _AuthClient extends http.BaseClient {
  _AuthClient(this._headers);
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

/// Uploads backups to Google Drive using the narrow `drive.file` scope — the
/// app can only see files/folders it created itself.
///
/// Layout in Drive:
/// ```
/// HoldStrong Backups/
///   transactions.csv                 (overwritten each run)
///   daily/holdstrong_2026-11-20.json (newest N kept)
///   monthly/holdstrong_2026-11.json  (first backup of each month, never pruned)
/// ```
class DriveBackupService {
  DriveBackupService._();
  static final DriveBackupService instance = DriveBackupService._();

  static const _scopes = [drive.DriveApi.driveFileScope];
  static const _folderMime = 'application/vnd.google-apps.folder';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: CloudBackupConfig.webClientId,
    );
    _initialized = true;
  }

  // ─── Connect (foreground only — shows UI) ───────────────────────────────────

  /// Interactive sign-in + Drive consent. Returns the account email.
  Future<String> connect() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: _scopes,
    );
    await account.authorizationClient.authorizeScopes(_scopes);
    return account.email;
  }

  Future<void> disconnect() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.disconnect();
  }

  // ─── Run (works in the background isolate — no UI) ──────────────────────────

  /// Silent auth: only succeeds if the user already granted Drive access.
  Future<drive.DriveApi> _api() async {
    await _ensureInitialized();
    final headers = await GoogleSignIn.instance.authorizationClient
        .authorizationHeaders(_scopes, promptIfNecessary: false);
    if (headers == null) throw const CloudAuthRequired();
    return drive.DriveApi(_AuthClient(headers));
  }

  Future<CloudBackupResult> runBackup(BackupService backup,
      {DateTime? now}) async {
    now ??= DateTime.now();
    try {
      if (!CloudBackupConfig.isConfigured) {
        return const CloudBackupResult.failure('Google client ID not configured');
      }
      final api = await _api();

      // Build the payloads first so a local failure never leaves Drive half-written.
      final jsonBytes = utf8.encode(await backup.buildBackupJson());
      final csvBytes = utf8.encode(await backup.buildTransactionsCsv());

      final root = await _ensureFolder(api, CloudBackupConfig.rootFolderName, 'root');
      final daily = await _ensureFolder(api, CloudBackupConfig.dailyFolderName, root);
      final monthly = await _ensureFolder(api, CloudBackupConfig.monthlyFolderName, root);

      final day = '${now.year}-${_z(now.month)}-${_z(now.day)}';
      final month = '${now.year}-${_z(now.month)}';

      // 1. CSV — one file, overwritten.
      await _upsert(api, CloudBackupConfig.csvFileName, root, csvBytes, 'text/csv');

      // 2. Dated JSON — one per day (re-running on the same day replaces it).
      await _upsert(api, 'holdstrong_$day.json', daily, jsonBytes, 'application/json');

      // 3. Monthly — first backup seen in a calendar month, never deleted.
      final monthlyName = 'holdstrong_$month.json';
      var madeMonthly = false;
      if (await _find(api, monthlyName, monthly) == null) {
        await _upsert(api, monthlyName, monthly, jsonBytes, 'application/json');
        madeMonthly = true;
      }

      // 4. Prune dailies beyond the limit (monthly folder is never touched).
      final pruned = await _pruneDaily(api, daily);

      final extras = [
        if (madeMonthly) 'monthly snapshot saved',
        if (pruned > 0) '$pruned old backup${pruned == 1 ? '' : 's'} removed',
      ];
      return CloudBackupResult.success(
          'Uploaded $day${extras.isEmpty ? '' : ' · ${extras.join(', ')}'}');
    } on CloudAuthRequired catch (e) {
      return CloudBackupResult.failure(
          '${e.toString()} — open Settings and reconnect');
    } on GoogleSignInException catch (e) {
      return CloudBackupResult.failure('Google sign-in: ${e.code.name}');
    } on drive.DetailedApiRequestError catch (e) {
      return CloudBackupResult.failure('Drive error ${e.status}: ${e.message}');
    } catch (e) {
      return CloudBackupResult.failure(e.toString());
    }
  }

  // ─── Drive helpers ──────────────────────────────────────────────────────────

  static String _z(int n) => n.toString().padLeft(2, '0');

  // All names here are app constants/dates, but escape anyway.
  static String _q(String s) => s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

  Future<String?> _find(drive.DriveApi api, String name, String parentId,
      {bool folder = false}) async {
    final res = await api.files.list(
      q: "name = '${_q(name)}' and '$parentId' in parents and trashed = false"
          "${folder ? " and mimeType = '$_folderMime'" : " and mimeType != '$_folderMime'"}",
      spaces: 'drive',
      $fields: 'files(id)',
      pageSize: 1,
    );
    final files = res.files;
    return (files == null || files.isEmpty) ? null : files.first.id;
  }

  Future<String> _ensureFolder(
      drive.DriveApi api, String name, String parentId) async {
    final existing = await _find(api, name, parentId, folder: true);
    if (existing != null) return existing;
    final created = await api.files.create(
      drive.File()
        ..name = name
        ..mimeType = _folderMime
        ..parents = [parentId],
      $fields: 'id',
    );
    return created.id!;
  }

  Future<void> _upsert(drive.DriveApi api, String name, String parentId,
      List<int> bytes, String mime) async {
    final media = drive.Media(Stream.value(bytes), bytes.length, contentType: mime);
    final existingId = await _find(api, name, parentId);
    if (existingId != null) {
      await api.files.update(drive.File(), existingId,
          uploadMedia: media, $fields: 'id');
    } else {
      await api.files.create(
        drive.File()
          ..name = name
          ..parents = [parentId]
          ..mimeType = mime,
        uploadMedia: media,
        $fields: 'id',
      );
    }
  }

  Future<int> _pruneDaily(drive.DriveApi api, String dailyId) async {
    final pattern = RegExp(r'^holdstrong_\d{4}-\d{2}-\d{2}\.json$');
    final all = <drive.File>[];
    String? token;
    do {
      final res = await api.files.list(
        q: "'$dailyId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'nextPageToken, files(id, name)',
        pageSize: 200,
        pageToken: token,
      );
      all.addAll((res.files ?? []).where((f) => pattern.hasMatch(f.name ?? '')));
      token = res.nextPageToken;
    } while (token != null);

    // ISO dates sort lexicographically; newest first.
    all.sort((a, b) => b.name!.compareTo(a.name!));
    final stale = all.skip(CloudBackupConfig.maxDailyBackups).toList();
    for (final f in stale) {
      await api.files.delete(f.id!);
    }
    return stale.length;
  }
}
