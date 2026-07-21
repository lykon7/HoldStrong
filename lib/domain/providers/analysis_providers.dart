import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_entry.dart';
import '../../data/models/income_entry.dart';
import 'expense_providers.dart';
import 'income_providers.dart';
import 'package:flutter/material.dart';

enum AnalysisDateRange { thisWeek, lastWeek, thisMonth, lastMonth, allTime, custom }

class AnalysisFilterState {
  final AnalysisDateRange dateRangePreset;
  final DateTimeRange? customDateRange;
  final String? expenseCategory;
  final String? incomeCategory;
  final String searchQuery;

  AnalysisFilterState({
    this.dateRangePreset = AnalysisDateRange.thisMonth,
    this.customDateRange,
    this.expenseCategory,
    this.incomeCategory,
    this.searchQuery = '',
  });

  AnalysisFilterState copyWith({
    AnalysisDateRange? dateRangePreset,
    DateTimeRange? customDateRange,
    String? expenseCategory,
    bool clearExpenseCategory = false,
    String? incomeCategory,
    bool clearIncomeCategory = false,
    String? searchQuery,
  }) {
    return AnalysisFilterState(
      dateRangePreset: dateRangePreset ?? this.dateRangePreset,
      customDateRange: customDateRange ?? this.customDateRange,
      expenseCategory: clearExpenseCategory ? null : (expenseCategory ?? this.expenseCategory),
      incomeCategory: clearIncomeCategory ? null : (incomeCategory ?? this.incomeCategory),
      searchQuery: searchQuery ?? this.searchQuery,
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

  void setExpenseCategory(String? category) {
    state = state.copyWith(
      expenseCategory: category,
      clearExpenseCategory: category == null,
    );
  }

  void setIncomeCategory(String? category) {
    state = state.copyWith(
      incomeCategory: category,
      clearIncomeCategory: category == null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
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
    if (filterState.expenseCategory != null &&
        filterState.expenseCategory != 'All' &&
        entry.category != filterState.expenseCategory) {
      return false;
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
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
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
    if (filterState.incomeCategory != null &&
        filterState.incomeCategory != 'All' &&
        entry.category != filterState.incomeCategory) {
      return false;
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
    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
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
