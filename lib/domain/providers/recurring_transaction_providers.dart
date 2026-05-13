import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/recurring_transaction.dart';
import '../../data/repositories/recurring_transaction_repository.dart';
import 'goal_providers.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
  return RecurringTransactionRepository(ref.watch(isarProvider));
});

final allRecurringTransactionsProvider =
    StreamProvider<List<RecurringTransaction>>((ref) {
  return ref.watch(recurringTransactionRepositoryProvider).watchAllRecurring();
});
