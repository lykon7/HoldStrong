import '../../data/models/goal.dart';
import '../../data/models/resist_entry.dart';
import '../../data/models/craving_label.dart';
import '../../data/models/income_entry.dart';
import '../../data/models/expense_entry.dart';
import '../../data/models/fund_account.dart';
import '../../data/models/recurring_transaction.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/wishlist_item.dart';
import '../../data/models/liability_item.dart';
import '../../data/models/account_transfer.dart';

// ─── Goal ────────────────────────────────────────────────────────────────────

extension GoalBackup on Goal {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'name': name,
        'type': type.index,
        'targetAmountLkr': targetAmountLkr,
        'currency': currency,
        'fitnessMilestone': fitnessMilestone,
        'createdAt': createdAt.toIso8601String(),
        'targetDate': targetDate?.toIso8601String(),
        'isActive': isActive,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };
}

Goal goalFromBackupJson(Map<String, dynamic> j) {
  return Goal()
    ..uuid = j['uuid'] as String
    ..name = j['name'] as String
    ..type = GoalType.values[j['type'] as int]
    ..targetAmountLkr = (j['targetAmountLkr'] as num).toDouble()
    ..currency = j['currency'] as String? ?? 'LKR'
    ..fitnessMilestone = j['fitnessMilestone'] as String?
    ..createdAt = DateTime.parse(j['createdAt'] as String)
    ..targetDate = j['targetDate'] != null
        ? DateTime.parse(j['targetDate'] as String)
        : null
    ..isActive = j['isActive'] as bool? ?? false
    ..isCompleted = j['isCompleted'] as bool? ?? false
    ..completedAt = j['completedAt'] != null
        ? DateTime.parse(j['completedAt'] as String)
        : null;
}

// ─── ResistEntry ─────────────────────────────────────────────────────────────

extension ResistEntryBackup on ResistEntry {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'goalUuid': goalUuid,
        'amountLkr': amountLkr,
        'label': label,
        'caloriesAvoided': caloriesAvoided,
        'note': note,
        'loggedAt': loggedAt.toIso8601String(),
      };
}

ResistEntry resistEntryFromBackupJson(Map<String, dynamic> j) {
  return ResistEntry()
    ..uuid = j['uuid'] as String
    ..goalUuid = j['goalUuid'] as String
    ..amountLkr = (j['amountLkr'] as num).toDouble()
    ..label = j['label'] as String?
    ..caloriesAvoided = j['caloriesAvoided'] as int?
    ..note = j['note'] as String?
    ..loggedAt = DateTime.parse(j['loggedAt'] as String);
}

// ─── CravingLabel ─────────────────────────────────────────────────────────────

extension CravingLabelBackup on CravingLabel {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'name': name,
        'defaultCalories': defaultCalories,
        'useCount': useCount,
        'lastUsed': lastUsed.toIso8601String(),
      };
}

CravingLabel cravingLabelFromBackupJson(Map<String, dynamic> j) {
  return CravingLabel()
    ..uuid = j['uuid'] as String
    ..name = j['name'] as String
    ..defaultCalories = j['defaultCalories'] as int?
    ..useCount = j['useCount'] as int? ?? 0
    ..lastUsed = DateTime.parse(j['lastUsed'] as String);
}

// ─── IncomeEntry ─────────────────────────────────────────────────────────────

extension IncomeEntryBackup on IncomeEntry {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'amount': amount,
        'source': source,
        'fundUuid': fundUuid,
        'loggedAt': loggedAt.toIso8601String(),
      };
}

IncomeEntry incomeEntryFromBackupJson(Map<String, dynamic> j) {
  return IncomeEntry()
    ..uuid = j['uuid'] as String
    ..amount = (j['amount'] as num).toDouble()
    ..source = j['source'] as String
    ..fundUuid = j['fundUuid'] as String?
    ..loggedAt = DateTime.parse(j['loggedAt'] as String);
}

// ─── ExpenseEntry ─────────────────────────────────────────────────────────────

extension ExpenseEntryBackup on ExpenseEntry {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'amount': amount,
        'purpose': purpose,
        'fundUuid': fundUuid,
        'loggedAt': loggedAt.toIso8601String(),
      };
}

ExpenseEntry expenseEntryFromBackupJson(Map<String, dynamic> j) {
  return ExpenseEntry()
    ..uuid = j['uuid'] as String
    ..amount = (j['amount'] as num).toDouble()
    ..purpose = j['purpose'] as String
    ..fundUuid = j['fundUuid'] as String?
    ..loggedAt = DateTime.parse(j['loggedAt'] as String);
}

// ─── FundAccount ─────────────────────────────────────────────────────────────

extension FundAccountBackup on FundAccount {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'name': name,
        'openingBalance': openingBalance,
        'createdAt': createdAt.toIso8601String(),
      };
}

FundAccount fundAccountFromBackupJson(Map<String, dynamic> j) {
  return FundAccount()
    ..uuid = j['uuid'] as String
    ..name = j['name'] as String
    ..openingBalance = (j['openingBalance'] as num).toDouble()
    ..createdAt = DateTime.parse(j['createdAt'] as String);
}

// ─── RecurringTransaction ─────────────────────────────────────────────────────

extension RecurringTransactionBackup on RecurringTransaction {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'type': type,
        'amount': amount,
        'title': title,
        'fundUuid': fundUuid,
        'startAt': startAt.toIso8601String(),
        'lastGeneratedAt': lastGeneratedAt?.toIso8601String(),
        'frequency': frequency,
        'isActive': isActive,
      };
}

RecurringTransaction recurringTransactionFromBackupJson(Map<String, dynamic> j) {
  return RecurringTransaction()
    ..uuid = j['uuid'] as String
    ..type = j['type'] as int
    ..amount = (j['amount'] as num).toDouble()
    ..title = j['title'] as String
    ..fundUuid = j['fundUuid'] as String?
    ..startAt = DateTime.parse(j['startAt'] as String)
    ..lastGeneratedAt = j['lastGeneratedAt'] != null
        ? DateTime.parse(j['lastGeneratedAt'] as String)
        : null
    ..frequency = j['frequency'] as int
    ..isActive = j['isActive'] as bool? ?? true;
}

// ─── JournalEntry ─────────────────────────────────────────────────────────────

extension JournalEntryBackup on JournalEntry {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'content': content,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

JournalEntry journalEntryFromBackupJson(Map<String, dynamic> j) {
  return JournalEntry()
    ..uuid = j['uuid'] as String
    ..content = j['content'] as String
    ..date = DateTime.parse(j['date'] as String)
    ..createdAt = DateTime.parse(j['createdAt'] as String)
    ..updatedAt = DateTime.parse(j['updatedAt'] as String);
}

// ─── WishlistItem ────────────────────────────────────────────────────────────

extension WishlistItemBackup on WishlistItem {
  Map<String, dynamic> toBackupJson() => {
        'name': name,
        'estimatedCost': estimatedCost,
        'createdAt': createdAt.toIso8601String(),
        'sortOrder': sortOrder,
        'isBought': isBought,
      };
}

WishlistItem wishlistItemFromBackupJson(Map<String, dynamic> j) {
  return WishlistItem()
    ..name = j['name'] as String
    ..estimatedCost = (j['estimatedCost'] as num).toDouble()
    ..createdAt = DateTime.parse(j['createdAt'] as String)
    ..sortOrder = j['sortOrder'] as int? ?? 0
    ..isBought = j['isBought'] as bool? ?? false;
}

// ─── LiabilityItem ───────────────────────────────────────────────────────────

extension LiabilityItemBackup on LiabilityItem {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'title': title,
        'notes': notes,
        'type': type,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'isRecurring': isRecurring,
        'recurrenceFrequency': recurrenceFrequency,
        'totalInstalments': totalInstalments,
        'instalmentNumber': instalmentNumber,
        'groupUuid': groupUuid,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'linkedFundUuid': linkedFundUuid,
      };
}

LiabilityItem liabilityItemFromBackupJson(Map<String, dynamic> j) {
  return LiabilityItem()
    ..uuid = j['uuid'] as String
    ..title = j['title'] as String
    ..notes = j['notes'] as String?
    ..type = j['type'] as int
    ..amount = (j['amount'] as num).toDouble()
    ..dueDate = DateTime.parse(j['dueDate'] as String)
    ..isPaid = j['isPaid'] as bool? ?? false
    ..isRecurring = j['isRecurring'] as bool? ?? false
    ..recurrenceFrequency = j['recurrenceFrequency'] as int?
    ..totalInstalments = j['totalInstalments'] as int?
    ..instalmentNumber = j['instalmentNumber'] as int?
    ..groupUuid = j['groupUuid'] as String?
    ..isArchived = j['isArchived'] as bool? ?? false
    ..createdAt = DateTime.parse(j['createdAt'] as String)
    ..linkedFundUuid = j['linkedFundUuid'] as String?;
}

// ─── AccountTransfer ─────────────────────────────────────────────────────────

extension AccountTransferBackup on AccountTransfer {
  Map<String, dynamic> toBackupJson() => {
        'uuid': uuid,
        'fromFundUuid': fromFundUuid,
        'toFundUuid': toFundUuid,
        'amount': amount,
        'note': note,
        'transferAt': transferAt.toIso8601String(),
      };
}

AccountTransfer accountTransferFromBackupJson(Map<String, dynamic> j) {
  return AccountTransfer()
    ..uuid = j['uuid'] as String
    ..fromFundUuid = j['fromFundUuid'] as String
    ..toFundUuid = j['toFundUuid'] as String
    ..amount = (j['amount'] as num).toDouble()
    ..note = j['note'] as String?
    ..transferAt = DateTime.parse(j['transferAt'] as String);
}

