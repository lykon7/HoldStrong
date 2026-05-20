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
  // Mutations — single item (non-BNPL or editing one instalment)
  // -------------------------------------------------------------------------

  Future<void> save(LiabilityItem item) async {
    if (item.uuid.isEmpty) item.uuid = _uuid.v4();
    if (item.createdAt.year < 2000) item.createdAt = DateTime.now();
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
      if (item != null) await _isar.liabilityItems.delete(item.id);
    });
  }

  // -------------------------------------------------------------------------
  // BNPL — create N individual instalment entries
  // -------------------------------------------------------------------------

  /// Creates [count] separate LiabilityItem entries, one per instalment.
  /// Each is linked by a shared [groupUuid] and carries its own due date,
  /// computed by advancing the [startDate] by [frequency] for each step.
  Future<void> saveBnplInstalments({
    required String title,
    required double amount,
    required DateTime startDate,
    required int count,
    required LiabilityFrequency frequency,
    String? notes,
  }) async {
    final groupId = _uuid.v4();
    final now = DateTime.now();

    await _isar.writeTxn(() async {
      DateTime due = startDate;
      for (int i = 1; i <= count; i++) {
        final item = LiabilityItem()
          ..uuid = _uuid.v4()
          ..title = title
          ..notes = notes
          ..type = LiabilityType.bnpl.index
          ..amount = amount
          ..dueDate = due
          ..isPaid = false
          ..isRecurring = false
          ..recurrenceFrequency = frequency.index
          ..totalInstalments = count
          ..instalmentNumber = i
          ..groupUuid = groupId
          ..isArchived = false
          ..createdAt = now;
        await _isar.liabilityItems.put(item);
        due = _advanceDueDate(due, frequency);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Mark paid — archives entry + creates expense ledger entry
  // -------------------------------------------------------------------------

  /// Marks this specific liability (or instalment) as paid:
  /// - Creates an [ExpenseEntry] in the transaction ledger.
  /// - Archives the item (removes it from the active list).
  /// - For recurring non-BNPL items: advances the due date and keeps active.
  Future<void> markPaid(String uuid) async {
    await _isar.writeTxn(() async {
      final item = await _isar.liabilityItems
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      if (item == null) return;

      // Always log to expense ledger.
      final expense = ExpenseEntry()
        ..uuid = _uuid.v4()
        ..amount = item.amount
        ..purpose = item.title
        ..fundUuid = null
        ..loggedAt = DateTime.now();
      await _isar.expenseEntrys.put(expense);

      final isBnpl = item.type == LiabilityType.bnpl.index;

      if (isBnpl) {
        // Individual BNPL instalment — just archive it.
        item.isArchived = true;
      } else if (item.isRecurring) {
        // Recurring non-BNPL — advance due date, stay active.
        final freq = item.recurrenceFrequency != null
            ? LiabilityFrequency.values[
                item.recurrenceFrequency! % LiabilityFrequency.values.length]
            : LiabilityFrequency.monthly;
        item.dueDate = _advanceDueDate(item.dueDate, freq);
        item.isPaid = false;
      } else {
        // One-off — archive.
        item.isArchived = true;
      }

      await _isar.liabilityItems.put(item);
    });
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  DateTime _advanceDueDate(DateTime from, LiabilityFrequency freq) {
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

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final targetYear = date.year + (monthIndex ~/ 12);
    final targetMonth = (monthIndex % 12) + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = date.day <= lastDay ? date.day : lastDay;
    return DateTime(targetYear, targetMonth, targetDay,
        date.hour, date.minute);
  }
}
