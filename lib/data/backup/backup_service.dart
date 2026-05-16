import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/goal.dart';
import '../models/resist_entry.dart';
import '../models/craving_label.dart';
import '../models/income_entry.dart';
import '../models/expense_entry.dart';
import '../models/fund_account.dart';
import '../models/recurring_transaction.dart';
import 'backup_extensions.dart';

const _kBackupVersion = 1;

class BackupResult {
  const BackupResult.success(this.file) : error = null;
  const BackupResult.failure(this.error) : file = null;

  final File? file;
  final String? error;

  bool get isSuccess => file != null;
}

class ImportResult {
  const ImportResult.success(this.counts) : error = null;
  const ImportResult.failure(this.error) : counts = const {};

  final Map<String, int>? counts;
  final String? error;

  bool get isSuccess => counts != null;

  int get total => counts?.values.fold<int>(0, (a, b) => a + b) ?? 0;
}

class BackupService {
  const BackupService(this._isar);

  final Isar _isar;

  // ─── Export ─────────────────────────────────────────────────────────────────

  Future<BackupResult> export() async {
    try {
      final goals = await _isar.goals.where().findAll();
      final resists = await _isar.resistEntrys.where().findAll();
      final labels = await _isar.cravingLabels.where().findAll();
      final incomes = await _isar.incomeEntrys.where().findAll();
      final expenses = await _isar.expenseEntrys.where().findAll();
      final funds = await _isar.fundAccounts.where().findAll();
      final recurring = await _isar.recurringTransactions.where().findAll();

      final payload = <String, dynamic>{
        'version': _kBackupVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'goals': goals.map((e) => e.toBackupJson()).toList(),
        'resistEntries': resists.map((e) => e.toBackupJson()).toList(),
        'cravingLabels': labels.map((e) => e.toBackupJson()).toList(),
        'incomeEntries': incomes.map((e) => e.toBackupJson()).toList(),
        'expenseEntries': expenses.map((e) => e.toBackupJson()).toList(),
        'fundAccounts': funds.map((e) => e.toBackupJson()).toList(),
        'recurringTransactions':
            recurring.map((e) => e.toBackupJson()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp =
          '${now.year}${_z(now.month)}${_z(now.day)}_${_z(now.hour)}${_z(now.minute)}';
      final file = File('${dir.path}/holdstrong_$stamp.hsbackup');
      await file.writeAsString(jsonStr, encoding: utf8);

      return BackupResult.success(file);
    } catch (e) {
      return BackupResult.failure(e.toString());
    }
  }

  // ─── Import (merge-by-UUID) ──────────────────────────────────────────────────

  Future<ImportResult> importFile(File file) async {
    try {
      final raw = await file.readAsString(encoding: utf8);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final version = json['version'] as int?;
      if (version == null || version > _kBackupVersion) {
        return const ImportResult.failure(
            'Unsupported backup version. Please update HoldStrong.');
      }

      final counts = <String, int>{
        'goals': 0,
        'resistEntries': 0,
        'cravingLabels': 0,
        'incomeEntries': 0,
        'expenseEntries': 0,
        'fundAccounts': 0,
        'recurringTransactions': 0,
      };

      await _isar.writeTxn(() async {
        // Goals — merge by uuid
        final goalList = (json['goals'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in goalList) {
          final uuid = j['uuid'] as String;
          final existing = await _isar.goals.filter().uuidEqualTo(uuid).findFirst();
          if (existing == null) {
            await _isar.goals.put(goalFromBackupJson(j));
            counts['goals'] = counts['goals']! + 1;
          }
        }

        // Resist entries
        final resistList = (json['resistEntries'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in resistList) {
          final uuid = j['uuid'] as String;
          final existing =
              await _isar.resistEntrys.filter().uuidEqualTo(uuid).findFirst();
          if (existing == null) {
            await _isar.resistEntrys.put(resistEntryFromBackupJson(j));
            counts['resistEntries'] = counts['resistEntries']! + 1;
          }
        }

        // Craving labels
        final labelList = (json['cravingLabels'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in labelList) {
          final uuid = j['uuid'] as String;
          final existing =
              await _isar.cravingLabels.filter().uuidEqualTo(uuid).findFirst();
          if (existing == null) {
            await _isar.cravingLabels.put(cravingLabelFromBackupJson(j));
            counts['cravingLabels'] = counts['cravingLabels']! + 1;
          }
        }

        // Income entries
        final incomeList = (json['incomeEntries'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in incomeList) {
          final uuid = j['uuid'] as String;
          final existing =
              await _isar.incomeEntrys.filter().uuidEqualTo(uuid).findFirst();
          if (existing == null) {
            await _isar.incomeEntrys.put(incomeEntryFromBackupJson(j));
            counts['incomeEntries'] = counts['incomeEntries']! + 1;
          }
        }

        // Expense entries
        final expenseList = (json['expenseEntries'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in expenseList) {
          final uuid = j['uuid'] as String;
          final existing =
              await _isar.expenseEntrys.filter().uuidEqualTo(uuid).findFirst();
          if (existing == null) {
            await _isar.expenseEntrys.put(expenseEntryFromBackupJson(j));
            counts['expenseEntries'] = counts['expenseEntries']! + 1;
          }
        }

        // Fund accounts
        final fundList = (json['fundAccounts'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in fundList) {
          final uuid = j['uuid'] as String;
          final existing =
              await _isar.fundAccounts.filter().uuidEqualTo(uuid).findFirst();
          if (existing == null) {
            await _isar.fundAccounts.put(fundAccountFromBackupJson(j));
            counts['fundAccounts'] = counts['fundAccounts']! + 1;
          }
        }

        // Recurring transactions
        final recurringList =
            (json['recurringTransactions'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();
        for (final j in recurringList) {
          final uuid = j['uuid'] as String;
          final existing = await _isar.recurringTransactions
              .filter()
              .uuidEqualTo(uuid)
              .findFirst();
          if (existing == null) {
            await _isar.recurringTransactions
                .put(recurringTransactionFromBackupJson(j));
            counts['recurringTransactions'] =
                counts['recurringTransactions']! + 1;
          }
        }
      });

      return ImportResult.success(counts);
    } catch (e) {
      return ImportResult.failure(e.toString());
    }
  }

  String _z(int n) => n.toString().padLeft(2, '0');
}
