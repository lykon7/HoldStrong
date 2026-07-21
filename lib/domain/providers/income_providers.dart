import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/income_entry.dart';
import '../../data/repositories/income_repository.dart';
import 'goal_providers.dart';
import 'recalibration_provider.dart';

final incomeSourcesProvider =
    StateNotifierProvider<IncomeSourcesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return IncomeSourcesNotifier(prefs);
});

class IncomeSourcesNotifier extends StateNotifier<List<String>> {
  IncomeSourcesNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'configured_income_sources';
  static const _defaultSources = ['DA', 'PM', 'UB'];

  static List<String> _load(SharedPreferences prefs) {
    return prefs.getStringList(_key) ?? _defaultSources;
  }

  Future<void> updateSources(List<String> sources) async {
    await _prefs.setStringList(_key, sources);
    state = sources;
  }

  Future<void> addSource(String source) async {
    if (!state.contains(source)) {
      final newSources = [...state, source];
      await updateSources(newSources);
    }
  }

  Future<void> removeSource(String source) async {
    final newSources = state.where((s) => s != source).toList();
    await updateSources(newSources);
  }
}

final incomeCategoriesProvider =
    StateNotifierProvider<IncomeCategoriesNotifier, List<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return IncomeCategoriesNotifier(prefs);
});

class IncomeCategoriesNotifier extends StateNotifier<List<String>> {
  IncomeCategoriesNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'configured_income_categories';
  static const _defaultCategories = [
    'Passive Yield',
    'Active Yield 1',
    'Active Yield 2',
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

/// Total for the previous Mon–Sun week
final lastWeekIncomeTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allIncomeProvider).whenData((entries) {
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
final lastMonthIncomeTotalProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(allIncomeProvider).whenData((entries) {
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
