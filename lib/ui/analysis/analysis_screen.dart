import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../domain/providers/analysis_providers.dart';
import '../../domain/providers/expense_providers.dart';
import '../../domain/providers/income_providers.dart';
import '../../data/models/expense_entry.dart';
import '../../data/models/income_entry.dart';

const _kIncomeGreen = Color(0xFF3DAA6E);
const _kExpenseRed = AppColors.destructive;

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Reset filters on init
    Future.microtask(() {
      ref.read(analysisFilterProvider.notifier).setDateRangePreset(AnalysisDateRange.thisMonth);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectDateRange(BuildContext context, AnalysisDateRange preset) async {
    final notifier = ref.read(analysisFilterProvider.notifier);
    if (preset == AnalysisDateRange.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accentGold,
                onPrimary: Colors.black,
                surface: AppColors.backgroundSurface,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (range != null) {
        notifier.setCustomDateRange(range);
      }
    } else {
      notifier.setDateRangePreset(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(analysisFilterProvider);
    final notifier = ref.read(analysisFilterProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('ANALYSIS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: AppColors.accentGold,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'EXPENSES'),
            Tab(text: 'INCOME'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.backgroundSurface,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AnalysisDateRange>(
                      value: filterState.dateRangePreset,
                      dropdownColor: AppColors.backgroundElevated,
                      isExpanded: true,
                      style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
                      icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      onChanged: (val) {
                        if (val != null) _selectDateRange(context, val);
                      },
                      items: const [
                        DropdownMenuItem(value: AnalysisDateRange.thisWeek, child: Text('This Week')),
                        DropdownMenuItem(value: AnalysisDateRange.lastWeek, child: Text('Last Week')),
                        DropdownMenuItem(value: AnalysisDateRange.thisMonth, child: Text('This Month')),
                        DropdownMenuItem(value: AnalysisDateRange.lastMonth, child: Text('Last Month')),
                        DropdownMenuItem(value: AnalysisDateRange.allTime, child: Text('All Time')),
                        DropdownMenuItem(value: AnalysisDateRange.custom, child: Text('Custom Range...')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final isExpense = _tabController.index == 0;
                      return Consumer(
                        builder: (context, ref, _) {
                          final expenseCategories = ref.watch(expenseCategoriesProvider);
                          final incomeCategories = ref.watch(incomeCategoriesProvider);
                          
                          final categories = isExpense ? expenseCategories : incomeCategories;
                          final currentValue = isExpense ? filterState.expenseCategory : filterState.incomeCategory;

                          return DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentValue,
                              hint: const Text('Category', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textSecondary)),
                              dropdownColor: AppColors.backgroundElevated,
                              isExpanded: true,
                              style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
                              icon: const Icon(Icons.filter_list, size: 16, color: AppColors.textSecondary),
                              onChanged: (val) {
                                if (isExpense) {
                                  notifier.setExpenseCategory(val == 'All' ? null : val);
                                } else {
                                  notifier.setIncomeCategory(val == 'All' ? null : val);
                                }
                              },
                              items: [
                                const DropdownMenuItem(value: 'All', child: Text('All')),
                                ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => notifier.setSearchQuery(val.trim()),
              style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by keyword...',
                hintStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppColors.backgroundElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
            ),
          ),
          const Divider(height: 1),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExpenseAnalysisView(),
                _IncomeAnalysisView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseAnalysisView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(filteredExpensesProvider);
    final categoryTotals = ref.watch(expenseCategoryTotalsProvider);
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);

    return _AnalysisContentView(
      transactions: expenses.cast<dynamic>(),
      categoryTotals: categoryTotals,
      totalAmount: total,
      isExpense: true,
    );
  }
}

class _IncomeAnalysisView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(filteredIncomeProvider);
    final categoryTotals = ref.watch(incomeCategoryTotalsProvider);
    final total = income.fold<double>(0, (sum, item) => sum + item.amount);

    return _AnalysisContentView(
      transactions: income.cast<dynamic>(),
      categoryTotals: categoryTotals,
      totalAmount: total,
      isExpense: false,
    );
  }
}

class _AnalysisContentView extends StatelessWidget {
  final List<dynamic> transactions;
  final Map<String, double> categoryTotals;
  final double totalAmount;
  final bool isExpense;

  const _AnalysisContentView({
    required this.transactions,
    required this.categoryTotals,
    required this.totalAmount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No data for this period.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final color = isExpense ? _kExpenseRed : _kIncomeGreen;
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                isExpense ? 'TOTAL EXPENSES' : 'TOTAL INCOME',
                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, letterSpacing: 2, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Rs ${fmt.format(totalAmount)}',
                style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 32, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Bar Chart
        if (categoryTotals.isNotEmpty)
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: categoryTotals.values.isEmpty ? 100 : categoryTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final keys = categoryTotals.keys.toList();
                        if (value.toInt() < 0 || value.toInt() >= keys.length) return const SizedBox.shrink();
                        final title = keys[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            title.length > 5 ? title.substring(0, 5) : title,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'IBMPlexMono'),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: categoryTotals.entries.toList().asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: color,
                        width: 16,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        const SizedBox(height: 24),

        // Transactions List
        const Text(
          'TRANSACTIONS',
          style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, letterSpacing: 2, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...transactions.map((t) {
          final isE = t is ExpenseEntry;
          final title = isE ? t.purpose : (t as IncomeEntry).source;
          final cat = isE ? t.category : (t as IncomeEntry).category;
          final amount = isE ? t.amount : (t as IncomeEntry).amount;
          final date = isE ? t.loggedAt : (t as IncomeEntry).loggedAt;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (cat != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cat,
                                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          if (cat != null) const SizedBox(width: 8),
                          Text(
                            dateFmt.format(date),
                            style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs ${fmt.format(amount)}',
                  style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.w600, fontSize: 14, color: color),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
