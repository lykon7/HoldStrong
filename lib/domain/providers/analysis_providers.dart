import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_entry.dart';
import '../../data/models/income_entry.dart';
import 'expense_providers.dart';
import 'income_providers.dart';
import 'package:flutter/material.dart';

enum AnalysisDateRange { thisWeek, lastWeek, thisMonth, lastMonth, last3Months, allTime, custom }

enum AnalysisSortOption { dateNewToOld, dateOldToNew, valueHighToLow, valueLowToHigh }

class AnalysisFilterState {
  final AnalysisDateRange dateRangePreset;
  final DateTimeRange? customDateRange;
  final Set<String> expenseCategories;
  final Set<String> incomeCategories;
  final String searchQuery;
  final AnalysisSortOption sortOption;

  AnalysisFilterState({
    this.dateRangePreset = AnalysisDateRange.thisMonth,
    this.customDateRange,
    this.expenseCategories = const {},
    this.incomeCategories = const {},
    this.searchQuery = '',
    this.sortOption = AnalysisSortOption.dateNewToOld,
  });

  AnalysisFilterState copyWith({
    AnalysisDateRange? dateRangePreset,
    DateTimeRange? customDateRange,
    Set<String>? expenseCategories,
    Set<String>? incomeCategories,
    String? searchQuery,
    AnalysisSortOption? sortOption,
  }) {
    return AnalysisFilterState(
      dateRangePreset: dateRangePreset ?? this.dateRangePreset,
      customDateRange: customDateRange ?? this.customDateRange,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class AnalysisFilterNotifier extends StateNotifier<AnalysisFilterState> {
  AnalysisFilterNotifier() : super(AnalysisFilterState());

  void setDateRangePreset(AnalysisDateRange preset) {
    state = state.copyWith(dateRangePreset: preset);
  }

  void setCustomDateRange(DateTimeRange? range) {
    state = state.copyWith(
      dateRangePreset: AnalysisDateRange.custom,
      customDateRange: range,
    );
  }

  void toggleExpenseCategory(String category) {
    final newSet = Set<String>.from(state.expenseCategories);
    if (newSet.contains(category)) {
      newSet.remove(category);
    } else {
      newSet.add(category);
    }
    state = state.copyWith(expenseCategories: newSet);
  }

  void clearExpenseCategories() {
    state = state.copyWith(expenseCategories: const {});
  }

  void toggleIncomeCategory(String category) {
    final newSet = Set<String>.from(state.incomeCategories);
    if (newSet.contains(category)) {
      newSet.remove(category);
    } else {
      newSet.add(category);
    }
    state = state.copyWith(incomeCategories: newSet);
  }

  void clearIncomeCategories() {
    state = state.copyWith(incomeCategories: const {});
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOption(AnalysisSortOption option) {
    state = state.copyWith(sortOption: option);
  }
}

final analysisFilterProvider =
    StateNotifierProvider<AnalysisFilterNotifier, AnalysisFilterState>((ref) {
  return AnalysisFilterNotifier();
});

DateTimeRange? _getDateRange(AnalysisFilterState state) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  switch (state.dateRangePreset) {
    case AnalysisDateRange.thisWeek:
      final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
      return DateTimeRange(start: weekStart, end: now);
    case AnalysisDateRange.lastWeek:
      final thisWeekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
      final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
      return DateTimeRange(start: lastWeekStart, end: thisWeekStart);
    case AnalysisDateRange.thisMonth:
      final monthStart = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: monthStart, end: now);
    case AnalysisDateRange.lastMonth:
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: lastMonthStart, end: lastMonthEnd);
    case AnalysisDateRange.last3Months:
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
      return DateTimeRange(start: threeMonthsAgo, end: currentMonthStart);
    case AnalysisDateRange.custom:
      return state.customDateRange;
    case AnalysisDateRange.allTime:
      return null; // Null means no date filter
  }
}

final filteredExpensesProvider = Provider<List<ExpenseEntry>>((ref) {
  final allExpenses = ref.watch(allExpensesProvider).valueOrNull ?? [];
  final filterState = ref.watch(analysisFilterProvider);

  final dateRange = _getDateRange(filterState);

  return allExpenses.where((entry) {
    if (dateRange != null) {
      if (entry.loggedAt.isBefore(dateRange.start) ||
          entry.loggedAt.isAfter(dateRange.end)) {
        return false;
      }
    }
    if (filterState.expenseCategories.isNotEmpty) {
      final matches = filterState.expenseCategories.contains(entry.category) ||
          (entry.category == null && filterState.expenseCategories.contains('Uncategorized'));
      if (!matches) return false;
    }
    if (filterState.searchQuery.isNotEmpty) {
      if (!entry.purpose
          .toLowerCase()
          .contains(filterState.searchQuery.toLowerCase())) {
        return false;
      }
    }
    return true;
  }).toList()
    ..sort((a, b) {
      switch (filterState.sortOption) {
        case AnalysisSortOption.dateNewToOld:
          return b.loggedAt.compareTo(a.loggedAt);
        case AnalysisSortOption.dateOldToNew:
          return a.loggedAt.compareTo(b.loggedAt);
        case AnalysisSortOption.valueHighToLow:
          return b.amount.compareTo(a.amount);
        case AnalysisSortOption.valueLowToHigh:
          return a.amount.compareTo(b.amount);
      }
    });
});

final filteredIncomeProvider = Provider<List<IncomeEntry>>((ref) {
  final allIncome = ref.watch(allIncomeProvider).valueOrNull ?? [];
  final filterState = ref.watch(analysisFilterProvider);

  final dateRange = _getDateRange(filterState);

  return allIncome.where((entry) {
    if (dateRange != null) {
      if (entry.loggedAt.isBefore(dateRange.start) ||
          entry.loggedAt.isAfter(dateRange.end)) {
        return false;
      }
    }
    if (filterState.incomeCategories.isNotEmpty) {
      final matches = filterState.incomeCategories.contains(entry.category) ||
          (entry.category == null && filterState.incomeCategories.contains('Uncategorized'));
      if (!matches) return false;
    }
    if (filterState.searchQuery.isNotEmpty) {
      if (!entry.source
          .toLowerCase()
          .contains(filterState.searchQuery.toLowerCase())) {
        return false;
      }
    }
    return true;
  }).toList()
    ..sort((a, b) {
      switch (filterState.sortOption) {
        case AnalysisSortOption.dateNewToOld:
          return b.loggedAt.compareTo(a.loggedAt);
        case AnalysisSortOption.dateOldToNew:
          return a.loggedAt.compareTo(b.loggedAt);
        case AnalysisSortOption.valueHighToLow:
          return b.amount.compareTo(a.amount);
        case AnalysisSortOption.valueLowToHigh:
          return a.amount.compareTo(b.amount);
      }
    });
});

final expenseCategoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(filteredExpensesProvider);
  final map = <String, double>{};
  for (final e in expenses) {
    final cat = e.category ?? 'Uncategorized';
    map[cat] = (map[cat] ?? 0.0) + e.amount;
  }
  return map;
});

final incomeCategoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final income = ref.watch(filteredIncomeProvider);
  final map = <String, double>{};
  for (final i in income) {
    final cat = i.category ?? 'Uncategorized';
    map[cat] = (map[cat] ?? 0.0) + i.amount;
  }
  return map;
});
