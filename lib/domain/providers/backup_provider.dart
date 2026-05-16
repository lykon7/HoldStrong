import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup/backup_service.dart';
import 'goal_providers.dart'; // re-exports isarProvider

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(isarProvider));
});
