import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:uuid/uuid.dart';

import 'app.dart';
import 'core/constants.dart';
import 'data/models/goal.dart';
import 'data/models/resist_entry.dart';
import 'data/models/craving_label.dart';
import 'data/models/expense_entry.dart';
import 'data/models/income_entry.dart';
import 'data/models/fund_account.dart';
import 'data/models/recurring_transaction.dart';
import 'data/models/journal_entry.dart';
import 'data/models/wishlist_item.dart';
import 'data/models/workout_entry.dart';
import 'data/models/todo_item.dart';
import 'domain/providers/goal_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
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
    ],
    directory: dir.path,
    name: AppConstants.kIsarDbName,
  );

  if (isar.fundAccounts.countSync() == 0) {
    isar.writeTxnSync(() {
      isar.fundAccounts.putSync(
        FundAccount()
          ..uuid = const Uuid().v4()
          ..name = 'Cash'
          ..openingBalance = 0.0
          ..createdAt = DateTime.now(),
      );
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const HoldStrongApp(),
    ),
  );
}
