import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_entry.dart';
import '../../data/repositories/expense_repository.dart';
import 'goal_providers.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(isarProvider));
});

final allExpensesProvider = StreamProvider<List<ExpenseEntry>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAllEntries();
});

/// Total for today: midnight → now
final dailyExpenseTotalProvider = StreamProvider<double>((ref) {
  return ref.watch(allExpensesProvider.stream).map((entries) {
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
final weeklyExpenseTotalProvider = StreamProvider<double>((ref) {
  return ref.watch(allExpensesProvider.stream).map((entries) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    // weekday: Mon=1 … Sun=7
    final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(weekStart) && e.loggedAt.isBefore(weekEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});

/// Total for the current calendar month
final monthlyExpenseTotalProvider = StreamProvider<double>((ref) {
  return ref.watch(allExpensesProvider.stream).map((entries) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(monthStart) && e.loggedAt.isBefore(monthEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});
