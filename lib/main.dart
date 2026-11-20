import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

import 'app.dart';
import 'data/cloud/cloud_backup_scheduler.dart';
import 'data/isar_open.dart';
import 'data/models/fund_account.dart';
import 'domain/providers/goal_providers.dart';
import 'domain/providers/recalibration_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  final isar = await openHoldStrongIsar(dir.path);

  if (isar.fundAccounts.countSync() == 0) {
    isar.writeTxnSync(() {
      isar.fundAccounts.putSync(
        FundAccount()
          ..uuid = const Uuid().v4()
          ..name = 'Cash'
          ..openingBalance = 0.0
          ..createdAt = DateTime.now(),
      );
    });
  }

  // Daily Google Drive backup: register the background worker, and catch up
  // right away if a scheduled run was missed. Never blocks app start.
  CloudBackupScheduler.initialize().then((_) {
    CloudBackupScheduler.onAppOpen(prefs);
  }).catchError((Object e) {
    debugPrint('Cloud backup scheduler init failed: $e');
  });

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HoldStrongApp(),
    ),
  );
}

