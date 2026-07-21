import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/backup/backup_service.dart';
import 'goal_providers.dart'; // re-exports isarProvider
import 'recalibration_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(isarProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
