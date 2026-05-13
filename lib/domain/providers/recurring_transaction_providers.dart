import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recurring_transaction_repository.dart';
import 'goal_providers.dart';

final recurringTransactionRepositoryProvider =
    Provider<RecurringTransactionRepository>((ref) {
  return RecurringTransactionRepository(ref.watch(isarProvider));
});
