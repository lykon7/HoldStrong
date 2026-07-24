import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'ALL'),
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
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AnalysisDateRange>(
                        value: filterState.dateRangePreset,
                        dropdownColor: AppColors.backgroundElevated,
                        isExpanded: true,
                        isDense: true,
                        style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
                        icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                        onChanged: (val) {
                          if (val != null) _selectDateRange(context, val);
                        },
                        items: const [
                          DropdownMenuItem(value: AnalysisDateRange.thisWeek, child: Text('This Week')),
                          DropdownMenuItem(value: AnalysisDateRange.lastWeek, child: Text('Last Week')),
                          DropdownMenuItem(value: AnalysisDateRange.thisMonth, child: Text('This Month')),
                          DropdownMenuItem(value: AnalysisDateRange.lastMonth, child: Text('Last Month')),
                          DropdownMenuItem(value: AnalysisDateRange.last3Months, child: Text('Last 3 Months')),
                          DropdownMenuItem(value: AnalysisDateRange.allTime, child: Text('All Time')),
                          DropdownMenuItem(value: AnalysisDateRange.custom, child: Text('Custom Range...')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final isAll = _tabController.index == 0;
                      final isExpense = _tabController.index == 1;
                      
                      if (isAll) {
                        return Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundElevated.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: const Text('All Categories', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textSecondary)),
                        );
                      }
                      
                      return Consumer(
                        builder: (context, ref, _) {
                          final expenseCategories = ref.watch(expenseCategoriesProvider);
                          final incomeCategories = ref.watch(incomeCategoriesProvider);
                          
                          final categories = isExpense ? expenseCategories : incomeCategories;
                          final selectedSet = isExpense ? filterState.expenseCategories : filterState.incomeCategories;
                          final label = selectedSet.isEmpty ? 'All' : '${selectedSet.length} selected';

                          return InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppColors.backgroundSurface,
                                builder: (ctx) {
                                  return Consumer(
                                    builder: (context, ref, _) {
                                      final currentState = ref.watch(analysisFilterProvider);
                                      final currentSet = isExpense ? currentState.expenseCategories : currentState.incomeCategories;
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Select Categories', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                                TextButton(
                                                  onPressed: () {
                                                    if (isExpense) {
                                                      notifier.clearExpenseCategories();
                                                    } else {
                                                      notifier.clearIncomeCategories();
                                                    }
                                                  },
                                                  child: const Text('Clear All', style: TextStyle(color: AppColors.accentGold)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          Expanded(
                                            child: ListView(
                                              children: ['Uncategorized', ...categories].map((c) {
                                                return CheckboxListTile(
                                                  title: Text(c, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary)),
                                                  value: currentSet.contains(c),
                                                  activeColor: AppColors.accentGold,
                                                  checkColor: Colors.black,
                                                  onChanged: (val) {
                                                    if (isExpense) {
                                                      notifier.toggleExpenseCategory(c);
                                                    } else {
                                                      notifier.toggleIncomeCategory(c);
                                                    }
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<AnalysisSortOption>(
                  icon: const Icon(Icons.sort, color: AppColors.textSecondary, size: 20),
                  color: AppColors.backgroundElevated,
                  initialValue: filterState.sortOption,
                  onSelected: (val) => notifier.setSortOption(val),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: AnalysisSortOption.dateNewToOld,
                      child: Text('Date: Newest First', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary)),
                    ),
                    PopupMenuItem(
                      value: AnalysisSortOption.dateOldToNew,
                      child: Text('Date: Oldest First', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary)),
                    ),
                    PopupMenuItem(
                      value: AnalysisSortOption.valueHighToLow,
                      child: Text('Value: High to Low', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary)),
                    ),
                    PopupMenuItem(
                      value: AnalysisSortOption.valueLowToHigh,
                      child: Text('Value: Low to High', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary)),
                    ),
                  ],
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
                _AllAnalysisView(),
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

class _AllAnalysisView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(filteredExpensesProvider);
    final income = ref.watch(filteredIncomeProvider);
    final filterState = ref.watch(analysisFilterProvider);

    final List<dynamic> allTransactions = [...expenses, ...income];
    
    allTransactions.sort((a, b) {
       final dateA = a is ExpenseEntry ? a.loggedAt : (a as IncomeEntry).loggedAt;
       final dateB = b is ExpenseEntry ? b.loggedAt : (b as IncomeEntry).loggedAt;
       final amountA = a is ExpenseEntry ? a.amount : (a as IncomeEntry).amount;
       final amountB = b is ExpenseEntry ? b.amount : (b as IncomeEntry).amount;
       
       switch (filterState.sortOption) {
          case AnalysisSortOption.dateNewToOld:
            return dateB.compareTo(dateA);
          case AnalysisSortOption.dateOldToNew:
            return dateA.compareTo(dateB);
          case AnalysisSortOption.valueHighToLow:
            return amountB.compareTo(amountA);
          case AnalysisSortOption.valueLowToHigh:
            return amountA.compareTo(amountB);
       }
    });

    final totalExpense = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final totalIncome = income.fold<double>(0, (sum, item) => sum + item.amount);

    return _AnalysisContentView(
      transactions: allTransactions,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      isExpense: null,
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
  final Map<String, double>? categoryTotals;
  final double? totalAmount;
  final double? totalExpense;
  final double? totalIncome;
  final bool? isExpense;

  const _AnalysisContentView({
    required this.transactions,
    this.categoryTotals,
    this.totalAmount,
    this.totalExpense,
    this.totalIncome,
    this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No data for this period.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final fmt = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Summary Card
        if (isExpense != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (isExpense! ? _kExpenseRed : _kIncomeGreen).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  isExpense! ? 'TOTAL EXPENSES' : 'TOTAL INCOME',
                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, letterSpacing: 2, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs ${fmt.format(totalAmount)}',
                  style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 32, color: isExpense! ? _kExpenseRed : _kIncomeGreen),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INCOME', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, letterSpacing: 2, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Rs ${fmt.format(totalIncome)}', style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 24, color: _kIncomeGreen)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('EXPENSES', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, letterSpacing: 2, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Rs ${fmt.format(totalExpense)}', style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 24, color: _kExpenseRed)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NET BALANCE', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, letterSpacing: 2, color: AppColors.textSecondary)),
                    Text('Rs ${fmt.format(totalIncome! - totalExpense!)}', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 20, color: (totalIncome! - totalExpense!) >= 0 ? _kIncomeGreen : _kExpenseRed)),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        
        // Horizontal Bar Chart
        if (categoryTotals != null && categoryTotals!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (() {
              final entries = categoryTotals!.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              final maxVal = entries.isEmpty ? 1.0 : entries.first.value;
              final color = isExpense! ? _kExpenseRed : _kIncomeGreen;
              return entries.map((entry) {
                final widthFactor = maxVal == 0 ? 0.0 : entry.value / maxVal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  children: [
                                    Container(
                                      height: 12,
                                      width: constraints.maxWidth * widthFactor,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rs ${fmt.format(entry.value)}',
                            style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList();
            })(),
          ),
        if (categoryTotals != null && categoryTotals!.isNotEmpty) const SizedBox(height: 24),

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
          final itemColor = isE ? _kExpenseRed : _kIncomeGreen;

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
                  '${isExpense == null ? (isE ? '-' : '+') : ''}Rs ${fmt.format(amount)}',
                  style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.w600, fontSize: 14, color: itemColor),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
