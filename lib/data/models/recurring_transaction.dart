import 'package:isar/isar.dart';

part 'recurring_transaction.g.dart';

enum RecurringTransactionType { income, expense }

extension RecurringTransactionTypeLabel on RecurringTransactionType {
  String get label {
    switch (this) {
      case RecurringTransactionType.income:
        return 'Income';
      case RecurringTransactionType.expense:
        return 'Expense';
    }
  }
}

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

extension RecurrenceFrequencyLabel on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }
}

@collection
class RecurringTransaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late int type;
  late double amount;
  late String title;
  String? category;

  @Index()
  String? fundUuid;

  @Index()
  late DateTime startAt;

  DateTime? lastGeneratedAt;

  late int frequency;

  bool isActive = true;
}
