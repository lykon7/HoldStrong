import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/expense_entry.dart';
import '../../data/repositories/expense_repository.dart';
import 'goal_providers.dart';
import 'recalibration_provider.dart';

final deductibleFundAccountsProvider =
    StateNotifierProvider<DeductibleFundAccountsNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DeductibleFundAccountsNotifier(prefs);
});

class DeductibleFundAccountsNotifier extends StateNotifier<List<String>> {
  DeductibleFundAccountsNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'configured_expense_accounts';

  static List<String> _load(SharedPreferences prefs) {
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> updateAccounts(List<String> accounts) async {
    await _prefs.setStringList(_key, accounts);
    state = accounts;
  }

  Future<void> toggleAccount(String uuid) async {
    if (state.contains(uuid)) {
      final newAccounts = state.where((id) => id != uuid).toList();
      await updateAccounts(newAccounts);
    } else {
      final newAccounts = [...state, uuid];
      await updateAccounts(newAccounts);
    }
  }
}

final expenseCategoriesProvider =
    StateNotifierProvider<ExpenseCategoriesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ExpenseCategoriesNotifier(prefs);
});

class ExpenseCategoriesNotifier extends StateNotifier<List<String>> {
  ExpenseCategoriesNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'configured_expense_categories';
  static const _defaultCategories = [
    'Fuel',
    'Junk',
    'Food',
    'Gym',
    'Bike',
    'Grocery',
    'Subscriptions',
  ];

  static List<String> _load(SharedPreferences prefs) {
    return prefs.getStringList(_key) ?? _defaultCategories;
  }

  Future<void> updateCategories(List<String> categories) async {
    await _prefs.setStringList(_key, categories);
    state = categories;
  }

  Future<void> addCategory(String category) async {
    if (!state.contains(category)) {
      final newCategories = [...state, category];
      await updateCategories(newCategories);
    }
  }

  Future<void> removeCategory(String category) async {
    final newCategories = state.where((c) => c != category).toList();
    await updateCategories(newCategories);
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(isarProvider));
});

final allExpensesProvider = StreamProvider<List<ExpenseEntry>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAllEntries();
});

/// Total for today: midnight → now
final dailyExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allExpensesProvider).whenData((entries) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return entries
        .where((e) =>
            e.loggedAt.isAfter(todayStart) &&
            e.loggedAt.isBefore(todayEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});

/// Total for the current Mon–Sun week
final weeklyExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allExpensesProvider).whenData((entries) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(weekStart) && e.loggedAt.isBefore(weekEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});

/// Total for the current calendar month
final monthlyExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allExpensesProvider).whenData((entries) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(monthStart) && e.loggedAt.isBefore(monthEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});

/// Total for the previous Mon–Sun week
final lastWeekExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allExpensesProvider).whenData((entries) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final thisWeekStart =
        todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart;
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(lastWeekStart) &&
            e.loggedAt.isBefore(lastWeekEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});

/// Total for the previous calendar month
final lastMonthExpenseTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allExpensesProvider).whenData((entries) {
    final now = DateTime.now();
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 1);
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(lastMonthStart) &&
            e.loggedAt.isBefore(lastMonthEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});
