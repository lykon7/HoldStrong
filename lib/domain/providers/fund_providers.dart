import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fund_account.dart';
import '../../data/repositories/fund_repository.dart';
import 'goal_providers.dart';
import 'expense_providers.dart';
import 'income_providers.dart';
import 'account_transfer_providers.dart';

final fundRepositoryProvider = Provider<FundRepository>((ref) {
  return FundRepository(ref.watch(isarProvider));
});

final allFundAccountsProvider = StreamProvider<List<FundAccount>>((ref) {
  return ref.watch(fundRepositoryProvider).watchAllAccounts();
});

/// Live map of fundUuid → computed balance.
/// Riverpod re-runs this provider whenever accounts, incomes, expenses, or transfers change.
final fundBalancesProvider = Provider<Map<String, double>>((ref) {
  final accounts = ref.watch(allFundAccountsProvider).value ?? [];
  final incomes = ref.watch(allIncomeProvider).value ?? [];
  final expenses = ref.watch(allExpensesProvider).value ?? [];
  final transfers = ref.watch(allAccountTransfersProvider).value ?? [];

  final Map<String, double> balances = {};
  for (final acc in accounts) {
    final credited = incomes
        .where((e) => e.fundUuid == acc.uuid)
        .fold<double>(0.0, (s, e) => s + e.amount);
    final debited = expenses
        .where((e) => e.fundUuid == acc.uuid)
        .fold<double>(0.0, (s, e) => s + e.amount);
    final transferredIn = transfers
        .where((t) => t.toFundUuid == acc.uuid)
        .fold<double>(0.0, (s, t) => s + t.amount);
    final transferredOut = transfers
        .where((t) => t.fromFundUuid == acc.uuid)
        .fold<double>(0.0, (s, t) => s + t.amount);
    balances[acc.uuid] = acc.openingBalance + credited - debited + transferredIn - transferredOut;
  }
  return balances;
});


