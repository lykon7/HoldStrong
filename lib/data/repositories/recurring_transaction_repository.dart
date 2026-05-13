import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../models/recurring_transaction.dart';

class RecurringTransactionRepository {
  RecurringTransactionRepository(this._isar);

  final Isar _isar;
  final _uuid = const Uuid();

  Stream<List<RecurringTransaction>> watchAllRecurring() {
    return _isar.recurringTransactions
        .where()
        .sortByStartAtDesc()
        .watch(fireImmediately: true);
  }

  Future<void> saveRecurring(RecurringTransaction recurring) async {
    await _isar.writeTxn(() async {
      await _isar.recurringTransactions.put(recurring);
    });
  }

  Future<void> updateRecurring(RecurringTransaction recurring) async {
    await _isar.writeTxn(() async {
      await _isar.recurringTransactions.put(recurring);
    });
  }

  Future<void> setActive(String uuid, bool isActive) async {
    await _isar.writeTxn(() async {
      final rule = await _isar.recurringTransactions
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      if (rule != null) {
        rule.isActive = isActive;
        await _isar.recurringTransactions.put(rule);
      }
    });
  }

  Future<void> deleteRecurring(String uuid) async {
    await _isar.writeTxn(() async {
      final rule = await _isar.recurringTransactions
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      if (rule != null) {
        await _isar.recurringTransactions.delete(rule.id);
      }
    });
  }

  Future<void> materializeDueEntries({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final recurring = await _isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    if (recurring.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final rule in recurring) {
        final occurrences = _collectOccurrences(rule, current);
        if (occurrences.isEmpty) continue;

        if (rule.type == RecurringTransactionType.income.index) {
          final entries = occurrences
              .map(
                (time) => IncomeEntry()
                  ..uuid = _uuid.v4()
                  ..amount = rule.amount
                  ..source = rule.title
                  ..fundUuid = rule.fundUuid
                  ..loggedAt = time,
              )
              .toList();
          await _isar.incomeEntrys.putAll(entries);
        } else {
          final entries = occurrences
              .map(
                (time) => ExpenseEntry()
                  ..uuid = _uuid.v4()
                  ..amount = rule.amount
                  ..purpose = rule.title
                  ..fundUuid = rule.fundUuid
                  ..loggedAt = time,
              )
              .toList();
          await _isar.expenseEntrys.putAll(entries);
        }

        rule.lastGeneratedAt = occurrences.last;
        await _isar.recurringTransactions.put(rule);
      }
    });
  }

  List<DateTime> _collectOccurrences(
    RecurringTransaction rule,
    DateTime now,
  ) {
    final occurrences = <DateTime>[];
    if (!rule.isActive) return occurrences;

    DateTime next;
    if (rule.lastGeneratedAt == null) {
      next = rule.startAt;
    } else {
      next = _addFrequency(rule.lastGeneratedAt!, rule.frequency);
    }

    if (next.isAfter(now)) return occurrences;

    while (!next.isAfter(now)) {
      occurrences.add(next);
      next = _addFrequency(next, rule.frequency);
    }

    return occurrences;
  }

  DateTime _addFrequency(DateTime from, int frequencyCode) {
    final frequency = _frequencyFromCode(frequencyCode);
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return _addMonths(from, 1);
      case RecurrenceFrequency.yearly:
        return _addMonths(from, 12);
    }
  }

  RecurrenceFrequency _frequencyFromCode(int code) {
    if (code < 0 || code >= RecurrenceFrequency.values.length) {
      return RecurrenceFrequency.monthly;
    }
    return RecurrenceFrequency.values[code];
  }

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final targetYear = date.year + (monthIndex ~/ 12);
    final targetMonth = (monthIndex % 12) + 1;
    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = date.day <= lastDayOfMonth ? date.day : lastDayOfMonth;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
