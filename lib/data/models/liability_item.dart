import 'package:isar/isar.dart';

part 'liability_item.g.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum LiabilityType { bnpl, subscription, bill, loan, other }

extension LiabilityTypeLabel on LiabilityType {
  String get label {
    switch (this) {
      case LiabilityType.bnpl:
        return 'BNPL';
      case LiabilityType.subscription:
        return 'Subscription';
      case LiabilityType.bill:
        return 'Bill';
      case LiabilityType.loan:
        return 'Loan';
      case LiabilityType.other:
        return 'Other';
    }
  }
}

enum LiabilityFrequency { daily, weekly, monthly, yearly }

extension LiabilityFrequencyLabel on LiabilityFrequency {
  String get label {
    switch (this) {
      case LiabilityFrequency.daily:
        return 'Daily';
      case LiabilityFrequency.weekly:
        return 'Weekly';
      case LiabilityFrequency.monthly:
        return 'Monthly';
      case LiabilityFrequency.yearly:
        return 'Yearly';
    }
  }
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

@collection
class LiabilityItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String title;

  String? notes;

  /// Stored as int — index of [LiabilityType]
  late int type;

  late double amount;

  @Index()
  late DateTime dueDate;

  bool isPaid = false;

  bool isRecurring = false;

  /// Stored as int — index of [LiabilityFrequency]. Null if not recurring.
  int? recurrenceFrequency;

  /// BNPL: total number of instalments in this group. Set on every entry in the group.
  int? totalInstalments;

  /// BNPL: which instalment this entry represents (1-based).
  int? instalmentNumber;

  /// BNPL: shared UUID linking all instalment entries of the same BNPL.
  @Index()
  String? groupUuid;

  /// Whether the liability is fully settled (BNPL paid in full, or deleted).
  bool isArchived = false;

  @Index()
  late DateTime createdAt;
}
