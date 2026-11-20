import 'package:isar/isar.dart';

import '../core/constants.dart';
import 'models/account_transfer.dart';
import 'models/craving_label.dart';
import 'models/expense_entry.dart';
import 'models/fund_account.dart';
import 'models/goal.dart';
import 'models/income_entry.dart';
import 'models/journal_entry.dart';
import 'models/liability_item.dart';
import 'models/recurring_transaction.dart';
import 'models/resist_entry.dart';
import 'models/todo_item.dart';
import 'models/wishlist_item.dart';
import 'models/workout_entry.dart';

/// Opens (or returns the already-open) HoldStrong database.
///
/// Shared by `main()` and the background backup worker, which runs in its own
/// isolate and must open the same database by name.
Future<Isar> openHoldStrongIsar(String directory) async {
  final existing = Isar.getInstance(AppConstants.kIsarDbName);
  if (existing != null) return existing;
  return Isar.open(
    [
      GoalSchema,
      ResistEntrySchema,
      CravingLabelSchema,
      ExpenseEntrySchema,
      IncomeEntrySchema,
      FundAccountSchema,
      RecurringTransactionSchema,
      JournalEntrySchema,
      WishlistItemSchema,
      WorkoutEntrySchema,
      TodoItemSchema,
      LiabilityItemSchema,
      AccountTransferSchema,
    ],
    directory: directory,
    name: AppConstants.kIsarDbName,
  );
}
