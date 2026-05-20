import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_entry.dart';
import '../models/liability_item.dart';

class LiabilityRepository {
  LiabilityRepository(this._isar);

  final Isar _isar;
  final _uuid = const Uuid();

  // -------------------------------------------------------------------------
  // Streams
  // -------------------------------------------------------------------------

  /// Watches all non-archived liabilities, sorted by due date ascending.
  Stream<List<LiabilityItem>> watchAll() {
    return _isar.liabilityItems
        .where()
        .filter()
        .isArchivedEqualTo(false)
        .watch(fireImmediately: true)
        .map((items) {
      items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return items;
    });
  }

  // -------------------------------------------------------------------------
  // Mutations
  // -------------------------------------------------------------------------

  Future<void> save(LiabilityItem item) async {
    if (item.uuid.isEmpty) item.uuid = _uuid.v4();
    await _isar.writeTxn(() async {
      await _isar.liabilityItems.put(item);
    });
  }

  Future<void> update(LiabilityItem item) async {
    await _isar.writeTxn(() async {
      await _isar.liabilityItems.put(item);
    });
  }

  Future<void> delete(String uuid) async {
    await _isar.writeTxn(() async {
      final item = await _isar.liabilityItems
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      if (item != null) {
        await _isar.liabilityItems.delete(item.id);
      }
    });
  }

  /// Marks a liability occurrence as paid.
  ///
  /// - Increments [instalmentsPaid] if it is a BNPL type.
  /// - Archives the item if it is a fully-paid BNPL or a non-recurring one-off.
  /// - Advances [dueDate] and resets [isPaid] if it is recurring.
  /// - Creates a corresponding [ExpenseEntry] in the ledger for financial tracking.
  Future<void> markPaid(String uuid) async {
    await _isar.writeTxn(() async {
      final item = await _isar.liabilityItems
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      if (item == null) return;

      // 1) Create an expense entry in the ledger.
      final expense = ExpenseEntry()
        ..uuid = _uuid.v4()
        ..amount = item.amount
        ..purpose = item.title
        ..fundUuid = null
        ..loggedAt = DateTime.now();
      await _isar.expenseEntrys.put(expense);

      // 2) Handle BNPL instalment tracking.
      if (item.type == LiabilityType.bnpl.index) {
        item.instalmentsPaid = item.instalmentsPaid + 1;
        final total = item.totalInstalments ?? 0;
        if (total > 0 && item.instalmentsPaid >= total) {
          // All instalments paid — archive.
          item.isArchived = true;
          await _isar.liabilityItems.put(item);
          return;
        }
      }

      // 3) Recurring: advance due date and reset paid flag.
      if (item.isRecurring) {
        item.dueDate = _advanceDueDate(item.dueDate, item.recurrenceFrequency);
        item.isPaid = false;
      } else {
        // Non-recurring one-off — archive it.
        item.isArchived = true;
      }

      await _isar.liabilityItems.put(item);
    });
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  DateTime _advanceDueDate(DateTime from, int? frequencyCode) {
    final freq = _frequencyFromCode(frequencyCode ?? LiabilityFrequency.monthly.index);
    switch (freq) {
      case LiabilityFrequency.daily:
        return from.add(const Duration(days: 1));
      case LiabilityFrequency.weekly:
        return from.add(const Duration(days: 7));
      case LiabilityFrequency.monthly:
        return _addMonths(from, 1);
      case LiabilityFrequency.yearly:
        return _addMonths(from, 12);
    }
  }

  LiabilityFrequency _frequencyFromCode(int code) {
    if (code < 0 || code >= LiabilityFrequency.values.length) {
      return LiabilityFrequency.monthly;
    }
    return LiabilityFrequency.values[code];
  }

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final targetYear = date.year + (monthIndex ~/ 12);
    final targetMonth = (monthIndex % 12) + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = date.day <= lastDay ? date.day : lastDay;
    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
    );
  }
}
