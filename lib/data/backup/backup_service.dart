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
import '../models/journal_entry.dart';
import '../models/wishlist_item.dart';
import '../models/liability_item.dart';
import '../models/account_transfer.dart';
import '../models/todo_item.dart';
import '../models/workout_entry.dart';
import 'backup_extensions.dart';

const _kBackupVersion = 2;

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
      final journals = await _isar.journalEntrys.where().findAll();
      final wishlist = await _isar.wishlistItems.where().findAll();
      final liabilities = await _isar.liabilityItems.where().findAll();
      final transfers = await _isar.accountTransfers.where().findAll();
      final todos = await _isar.todoItems.where().findAll();
      final workouts = await _isar.workoutEntrys.where().findAll();

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
        'journalEntries': journals.map((e) => e.toBackupJson()).toList(),
        'wishlist': wishlist.map((e) => e.toBackupJson()).toList(),
        'liabilities': liabilities.map((e) => e.toBackupJson()).toList(),
        'accountTransfers': transfers.map((e) => e.toBackupJson()).toList(),
        'todos': todos.map((e) => e.toBackupJson()).toList(),
        'workouts': workouts.map((e) => e.toBackupJson()).toList(),
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
        'journalEntries': 0,
        'wishlist': 0,
        'liabilities': 0,
        'accountTransfers': 0,
        'todos': 0,
        'workouts': 0,
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

        // Journal entries
        final journalList = (json['journalEntries'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in journalList) {
          final uuid = j['uuid'] as String;
          final existing =
              await _isar.journalEntrys.filter().uuidEqualTo(uuid).findFirst();
          if (existing == null) {
            await _isar.journalEntrys.put(journalEntryFromBackupJson(j));
            counts['journalEntries'] = counts['journalEntries']! + 1;
          }
        }

        // Wishlist
        final wishlistList = (json['wishlist'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in wishlistList) {
          final name = j['name'] as String;
          final createdAt = DateTime.parse(j['createdAt'] as String);
          final existing = await _isar.wishlistItems
              .filter()
              .nameEqualTo(name)
              .createdAtEqualTo(createdAt)
              .findFirst();
          if (existing == null) {
            await _isar.wishlistItems.put(wishlistItemFromBackupJson(j));
            counts['wishlist'] = counts['wishlist']! + 1;
          }
        }

        // Liabilities
        final liabilityList = (json['liabilities'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in liabilityList) {
          final uuid = j['uuid'] as String;
          final existing = await _isar.liabilityItems
              .filter()
              .uuidEqualTo(uuid)
              .findFirst();
          if (existing == null) {
            await _isar.liabilityItems.put(liabilityItemFromBackupJson(j));
            counts['liabilities'] = counts['liabilities']! + 1;
          }
        }

        // Account transfers
        final transferList = (json['accountTransfers'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in transferList) {
          final uuid = j['uuid'] as String;
          final existing = await _isar.accountTransfers
              .filter()
              .uuidEqualTo(uuid)
              .findFirst();
          if (existing == null) {
            await _isar.accountTransfers.put(accountTransferFromBackupJson(j));
            counts['accountTransfers'] = counts['accountTransfers']! + 1;
          }
        }

        // Todos
        final todoList = (json['todos'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in todoList) {
          final title = j['title'] as String;
          final createdAt = DateTime.parse(j['createdAt'] as String);
          final existing = await _isar.todoItems
              .filter()
              .titleEqualTo(title)
              .createdAtEqualTo(createdAt)
              .findFirst();
          if (existing == null) {
            await _isar.todoItems.put(todoItemFromBackupJson(j));
            counts['todos'] = counts['todos']! + 1;
          }
        }

        // Workouts
        final workoutList = (json['workouts'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final j in workoutList) {
          final date = DateTime.parse(j['date'] as String);
          final existing = await _isar.workoutEntrys
              .filter()
              .dateEqualTo(date)
              .findFirst();
          if (existing == null) {
            await _isar.workoutEntrys.put(workoutEntryFromBackupJson(j));
            counts['workouts'] = counts['workouts']! + 1;
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
