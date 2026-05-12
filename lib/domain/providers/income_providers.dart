import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/income_entry.dart';
import '../../data/repositories/income_repository.dart';
import 'goal_providers.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository(ref.watch(isarProvider));
});

final allIncomeProvider = StreamProvider<List<IncomeEntry>>((ref) {
  return ref.watch(incomeRepositoryProvider).watchAllEntries();
});

/// Total for today: midnight → midnight
final dailyIncomeTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allIncomeProvider).whenData((entries) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return entries
        .where((e) =>
            e.loggedAt.isAfter(todayStart) && e.loggedAt.isBefore(todayEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});

/// Total for the current Mon–Sun week
final weeklyIncomeTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allIncomeProvider).whenData((entries) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart =
        todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(weekStart) && e.loggedAt.isBefore(weekEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});

/// Total for the current calendar month
final monthlyIncomeTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allIncomeProvider).whenData((entries) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    return entries
        .where((e) =>
            !e.loggedAt.isBefore(monthStart) && e.loggedAt.isBefore(monthEnd))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  });
});
