import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const _kBackupVersion = 3;

/// Device-specific SharedPreferences that must never travel in a backup
/// (Google account, schedule state, last-run status).
const _kExcludedPrefPrefixes = ['cloud_backup_'];

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
  const BackupService(this._isar, this._prefs);

  final Isar _isar;
  final SharedPreferences _prefs;

  // ─── Export ─────────────────────────────────────────────────────────────────

  Future<BackupResult> export() async {
    try {
      final jsonStr = await buildBackupJson();
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

  /// Full backup as a JSON string (same format as the manual `.hsbackup`).
  Future<String> buildBackupJson() async {
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
      'recurringTransactions': recurring.map((e) => e.toBackupJson()).toList(),
      'journalEntries': journals.map((e) => e.toBackupJson()).toList(),
      'wishlist': wishlist.map((e) => e.toBackupJson()).toList(),
      'liabilities': liabilities.map((e) => e.toBackupJson()).toList(),
      'accountTransfers': transfers.map((e) => e.toBackupJson()).toList(),
      'todos': todos.map((e) => e.toBackupJson()).toList(),
      'workouts': workouts.map((e) => e.toBackupJson()).toList(),
      'incomeCategories': _prefs.getStringList('configured_income_categories'),
      'expenseCategories':
          _prefs.getStringList('configured_expense_categories'),
      // Every other app setting (income sources, expense accounts, custom
      // timers, …). Generic so new settings are covered automatically.
      'preferences': exportPreferences(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @visibleForTesting
  Map<String, dynamic> exportPreferences() {
    final out = <String, dynamic>{};
    final keys = _prefs.getKeys().toList()..sort();
    for (final key in keys) {
      if (_kExcludedPrefPrefixes.any(key.startsWith)) continue;
      final v = _prefs.get(key);
      if (v is bool) {
        out[key] = {'type': 'bool', 'value': v};
      } else if (v is int) {
        out[key] = {'type': 'int', 'value': v};
      } else if (v is double) {
        out[key] = {'type': 'double', 'value': v};
      } else if (v is String) {
        out[key] = {'type': 'string', 'value': v};
      } else if (v is List) {
        out[key] = {'type': 'stringList', 'value': v.map((e) => '$e').toList()};
      }
    }
    return out;
  }

  /// Restores settings that don't exist on this device yet. Existing values
  /// are never overwritten, matching how records are merged.
  @visibleForTesting
  Future<int> importPreferences(Map<String, dynamic> prefs) async {
    var restored = 0;
    for (final entry in prefs.entries) {
      final key = entry.key;
      if (_kExcludedPrefPrefixes.any(key.startsWith)) continue;
      if (_prefs.containsKey(key)) continue;
      final spec = entry.value;
      if (spec is! Map) continue;
      final value = spec['value'];
      switch (spec['type']) {
        case 'bool':
          if (value is bool) await _prefs.setBool(key, value);
        case 'int':
          if (value is int) await _prefs.setInt(key, value);
        case 'double':
          if (value is num) await _prefs.setDouble(key, value.toDouble());
        case 'string':
          if (value is String) await _prefs.setString(key, value);
        case 'stringList':
          if (value is List) {
            await _prefs.setStringList(key, value.map((e) => '$e').toList());
          }
        default:
          continue;
      }
      restored++;
    }
    return restored;
  }

  /// Income, expenses and account transfers as one CSV, newest first.
  /// Starts with a UTF-8 BOM so Excel reads non-ASCII text correctly.
  Future<String> buildTransactionsCsv() async {
    final incomes = await _isar.incomeEntrys.where().findAll();
    final expenses = await _isar.expenseEntrys.where().findAll();
    final transfers = await _isar.accountTransfers.where().findAll();
    final funds = await _isar.fundAccounts.where().findAll();
    final fundNames = {for (final f in funds) f.uuid: f.name};
    String fund(String? uuid) => fundNames[uuid] ?? '';

    final rows = <({DateTime at, List<Object?> cells})>[
      for (final e in incomes)
        (
          at: e.loggedAt,
          cells: [
            'income', e.loggedAt.toIso8601String(), e.amount, e.amount,
            e.category, e.source, fund(e.fundUuid), e.uuid,
          ],
        ),
      for (final e in expenses)
        (
          at: e.loggedAt,
          cells: [
            'expense', e.loggedAt.toIso8601String(), e.amount, -e.amount,
            e.category, e.purpose, fund(e.fundUuid), e.uuid,
          ],
        ),
      for (final t in transfers)
        (
          at: t.transferAt,
          cells: [
            'transfer', t.transferAt.toIso8601String(), t.amount, 0,
            null, t.note, '${fund(t.fromFundUuid)} -> ${fund(t.toFundUuid)}',
            t.uuid,
          ],
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    final buf = StringBuffer('\uFEFF')
      ..writeln(
          'type,date,amount,signed_amount,category,description,account,uuid');
    for (final r in rows) {
      buf.writeln(r.cells.map(_csvCell).join(','));
    }
    return buf.toString();
  }

  static String _csvCell(Object? v) {
    if (v == null) return '';
    final s = v.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
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
        'preferences': 0,
      };

      // Import SharedPreferences categories if present
      if (json.containsKey('incomeCategories') && json['incomeCategories'] != null) {
        final List<dynamic> incCats = json['incomeCategories'];
        await _prefs.setStringList('configured_income_categories', incCats.map((e) => e.toString()).toList());
      }
      if (json.containsKey('expenseCategories') && json['expenseCategories'] != null) {
        final List<dynamic> expCats = json['expenseCategories'];
        await _prefs.setStringList('configured_expense_categories', expCats.map((e) => e.toString()).toList());
      }

      if (json['preferences'] is Map) {
        counts['preferences'] = await importPreferences(
            Map<String, dynamic>.from(json['preferences'] as Map));
      }

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
