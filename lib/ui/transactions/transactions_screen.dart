import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/expense_entry.dart';
import '../../data/models/income_entry.dart';
import '../../data/models/recurring_transaction.dart';
import '../../domain/providers/expense_providers.dart';
import '../../domain/providers/income_providers.dart';
import '../../domain/providers/fund_providers.dart';
import '../../domain/providers/recurring_transaction_providers.dart';

const _kDefaultSources = ['DA', 'PM', 'UB'];
const _kIncomeGreen = Color(0xFF3DAA6E);
const _kExpenseRed = AppColors.destructive;

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(recurringTransactionRepositoryProvider)
        .materializeDueEntries());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allIncome = ref.watch(allIncomeProvider);
    final allExpenses = ref.watch(allExpensesProvider);
    final dailyIncome = ref.watch(dailyIncomeTotalProvider);
    final dailyExpense = ref.watch(dailyExpenseTotalProvider);
    final weeklyIncome = ref.watch(weeklyIncomeTotalProvider);
    final weeklyExpense = ref.watch(weeklyExpenseTotalProvider);
    final lastWeekIncome = ref.watch(lastWeekIncomeTotalProvider);
    final lastWeekExpense = ref.watch(lastWeekExpenseTotalProvider);
    final monthlyIncome = ref.watch(monthlyIncomeTotalProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final lastMonthIncome = ref.watch(lastMonthIncomeTotalProvider);
    final lastMonthExpense = ref.watch(lastMonthExpenseTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('TRANSACTIONS'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search, size: 20),
            tooltip: _showSearch ? 'Close Search' : 'Search Transactions',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.repeat, size: 20),
            tooltip: 'Recurring',
            onPressed: () => context.push('/recurring'),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Transaction',
            onPressed: () => _showAddPicker(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryStrip(
            dailyIncome: dailyIncome,
            dailyExpense: dailyExpense,
            weeklyIncome: weeklyIncome,
            weeklyExpense: weeklyExpense,
            lastWeekIncome: lastWeekIncome,
            lastWeekExpense: lastWeekExpense,
            monthlyIncome: monthlyIncome,
            monthlyExpense: monthlyExpense,
            lastMonthIncome: lastMonthIncome,
            lastMonthExpense: lastMonthExpense,
          ),
          const Divider(height: 1),
          if (_showSearch)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: AppColors.backgroundSurface,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by keyword (source, purpose, amount)...',
                  hintStyle: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.backgroundElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: const BorderSide(color: AppColors.accentGold),
                  ),
                ),
              ),
            ),
          if (_showSearch) const Divider(height: 1),
          Expanded(
            child: allIncome.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (incomeEntries) => allExpenses.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (expenseEntries) => _buildTransactionList(
                  context,
                  ref,
                  incomeEntries,
                  expenseEntries,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    WidgetRef ref,
    List<IncomeEntry> incomeEntries,
    List<ExpenseEntry> expenseEntries,
  ) {
    var items = <_TransactionItem>[
      for (final entry in incomeEntries) _TransactionItem.income(entry),
      for (final entry in expenseEntries) _TransactionItem.expense(entry),
    ];

    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final title = item.title.toLowerCase();
        final amountStr = item.amount.toString();
        final typeStr = item.isIncome ? 'income' : 'expense';
        return title.contains(_searchQuery) ||
            amountStr.contains(_searchQuery) ||
            typeStr.contains(_searchQuery);
      }).toList();
    }

    if (items.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return _SearchEmptyState(query: _searchQuery);
      }
      return const _EmptyState();
    }

    items.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    final incomeTotals = <DateTime, double>{};
    for (final entry in incomeEntries) {
      final day = DateTime(
        entry.loggedAt.year,
        entry.loggedAt.month,
        entry.loggedAt.day,
      );
      incomeTotals[day] = (incomeTotals[day] ?? 0) + entry.amount;
    }

    final expenseTotals = <DateTime, double>{};
    for (final entry in expenseEntries) {
      final day = DateTime(
        entry.loggedAt.year,
        entry.loggedAt.month,
        entry.loggedAt.day,
      );
      expenseTotals[day] = (expenseTotals[day] ?? 0) + entry.amount;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final listItems = <Object>[];
    DateTime? lastDay;
    for (final item in items) {
      final entryDay = DateTime(
        item.loggedAt.year,
        item.loggedAt.month,
        item.loggedAt.day,
      );
      if (lastDay == null || entryDay != lastDay) {
        String label;
        if (entryDay == today) {
          label = 'TODAY';
        } else if (entryDay == yesterday) {
          label = 'YESTERDAY';
        } else {
          label =
              DateFormat('EEEE, d MMM yyyy').format(entryDay).toUpperCase();
        }
        listItems.add(_DayHeader(
          label: label,
          incomeTotal: incomeTotals[entryDay] ?? 0,
          expenseTotal: expenseTotals[entryDay] ?? 0,
        ));
        lastDay = entryDay;
      }
      listItems.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item is _DayHeader) {
          return _DayHeaderTile(header: item);
        }
        final entry = item as _TransactionItem;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _TransactionRow(
            item: entry,
            onDelete: () {
              if (entry.isIncome) {
                ref
                    .read(incomeRepositoryProvider)
                    .deleteEntry(entry.income!.uuid);
              } else {
                ref
                    .read(expenseRepositoryProvider)
                    .deleteEntry(entry.expense!.uuid);
              }
            },
            onEdit: () {
              if (entry.isIncome) {
                _showEditIncomeSheet(context, ref, entry.income!);
              } else {
                _showEditExpenseSheet(context, ref, entry.expense!);
              }
            },
          ),
        );
      },
    );
  }

  void _showAddPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _AddOption(
              label: 'ADD INCOME',
              icon: Icons.arrow_downward,
              color: _kIncomeGreen,
              onTap: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(() => _showAddIncomeSheet(context, ref));
              },
            ),
            _AddOption(
              label: 'ADD EXPENSE',
              icon: Icons.arrow_upward,
              color: _kExpenseRed,
              onTap: () {
                Navigator.of(sheetContext).pop();
                Future.microtask(() => _showAddExpenseSheet(context, ref));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddIncomeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _AddIncomeSheet(),
      ),
    );
  }

  void _showEditIncomeSheet(
    BuildContext context,
    WidgetRef ref,
    IncomeEntry entry,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _EditIncomeSheet(entry: entry),
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _AddExpenseSheet(),
      ),
    );
  }

  void _showEditExpenseSheet(
    BuildContext context,
    WidgetRef ref,
    ExpenseEntry entry,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _EditExpenseSheet(entry: entry),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 12,
          letterSpacing: 2,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textSecondary, size: 18),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.dailyIncome,
    required this.dailyExpense,
    required this.weeklyIncome,
    required this.weeklyExpense,
    required this.lastWeekIncome,
    required this.lastWeekExpense,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.lastMonthIncome,
    required this.lastMonthExpense,
  });

  final AsyncValue<double> dailyIncome;
  final AsyncValue<double> dailyExpense;
  final AsyncValue<double> weeklyIncome;
  final AsyncValue<double> weeklyExpense;
  final AsyncValue<double> lastWeekIncome;
  final AsyncValue<double> lastWeekExpense;
  final AsyncValue<double> monthlyIncome;
  final AsyncValue<double> monthlyExpense;
  final AsyncValue<double> lastMonthIncome;
  final AsyncValue<double> lastMonthExpense;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart =
        todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    // Last week bounds
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(days: 1));
    // Last month bounds
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final dayFmt = DateFormat('d MMM');
    final monthFmt = DateFormat('MMMM yyyy');

    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _SummaryCard(
            label: 'TODAY',
            sublabel: dayFmt.format(now),
            incomeValue: dailyIncome,
            expenseValue: dailyExpense,
            accentColor: _kIncomeGreen,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'THIS WEEK',
            sublabel: '${dayFmt.format(weekStart)} - ${dayFmt.format(weekEnd)}',
            incomeValue: weeklyIncome,
            expenseValue: weeklyExpense,
            accentColor: const Color(0xFF4A90D9),
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'LAST WEEK',
            sublabel:
                '${dayFmt.format(lastWeekStart)} - ${dayFmt.format(lastWeekEnd)}',
            incomeValue: lastWeekIncome,
            expenseValue: lastWeekExpense,
            accentColor: const Color(0xFF2E6098),
            muted: true,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'THIS MONTH',
            sublabel: monthFmt.format(now),
            incomeValue: monthlyIncome,
            expenseValue: monthlyExpense,
            accentColor: const Color(0xFF7B68EE),
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'LAST MONTH',
            sublabel: monthFmt.format(lastMonthDate),
            incomeValue: lastMonthIncome,
            expenseValue: lastMonthExpense,
            accentColor: const Color(0xFF5148A8),
            muted: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.sublabel,
    required this.incomeValue,
    required this.expenseValue,
    required this.accentColor,
    this.muted = false,
  });

  final String label;
  final String sublabel;
  final AsyncValue<double> incomeValue;
  final AsyncValue<double> expenseValue;
  final Color accentColor;
  /// When true, renders with a slightly dimmed background to visually
  /// distinguish historical (past) cards from current-period cards.
  final bool muted;

  Widget _buildNetValue() {
    if (incomeValue.hasValue && expenseValue.hasValue) {
      final net = incomeValue.value! - expenseValue.value!;
      final color = net >= 0 ? _kIncomeGreen : _kExpenseRed;
      final prefix = net >= 0 ? '+' : '';
      final fmt = NumberFormat('#,##0', 'en_US');
      return Text(
        'NET $prefix${fmt.format(net)}',
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 12,
          color: color,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.backgroundElevated.withOpacity(0.6)
            : AppColors.backgroundElevated,
        border: Border.all(
          color: muted
              ? AppColors.cardBorder.withOpacity(0.5)
              : AppColors.cardBorder,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(muted ? 0.6 : 1.0),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: muted
                      ? AppColors.textSecondary.withOpacity(0.7)
                      : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                sublabel,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  color: muted
                      ? AppColors.textSecondary.withOpacity(0.6)
                      : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryValueLine(
                label: 'IN',
                value: incomeValue,
                color: _kIncomeGreen.withOpacity(muted ? 0.7 : 1.0),
              ),
              const SizedBox(height: 4),
              _SummaryValueLine(
                label: 'OUT',
                value: expenseValue,
                color: _kExpenseRed.withOpacity(muted ? 0.7 : 1.0),
              ),
            ],
          ),
          _buildNetValue(),
        ],
      ),
    );
  }
}

class _SummaryValueLine extends StatelessWidget {
  const _SummaryValueLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final AsyncValue<double> value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final labelStyle = const TextStyle(
      fontFamily: 'IBMPlexMono',
      fontSize: 9,
      letterSpacing: 1,
      color: AppColors.textSecondary,
    );

    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        value.when(
          loading: () => const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.accentGold,
            ),
          ),
          error: (_, __) => const Text(
            '-',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          data: (total) => Text(
            'Rs ${fmt.format(total)}',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHeader {
  const _DayHeader({
    required this.label,
    required this.incomeTotal,
    required this.expenseTotal,
  });

  final String label;
  final double incomeTotal;
  final double expenseTotal;
}

class _DayHeaderTile extends StatelessWidget {
  const _DayHeaderTile({required this.header});
  final _DayHeader header;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final net = header.incomeTotal - header.expenseTotal;
    final netColor = net >= 0 ? _kIncomeGreen : _kExpenseRed;
    final netPrefix = net >= 0 ? '+Rs ' : '-Rs ';

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header.label,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'NET $netPrefix${fmt.format(net.abs())}',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  letterSpacing: 1,
                  color: netColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.cardBorder,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+Rs ${fmt.format(header.incomeTotal)}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1,
                  color: _kIncomeGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '-Rs ${fmt.format(header.expenseTotal)}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1,
                  color: _kExpenseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TransactionType { income, expense }

class _TransactionItem {
  const _TransactionItem._({
    required this.type,
    required this.loggedAt,
    required this.amount,
    required this.title,
    required this.income,
    required this.expense,
  });

  factory _TransactionItem.income(IncomeEntry entry) {
    return _TransactionItem._(
      type: _TransactionType.income,
      loggedAt: entry.loggedAt,
      amount: entry.amount,
      title: entry.source,
      income: entry,
      expense: null,
    );
  }

  factory _TransactionItem.expense(ExpenseEntry entry) {
    return _TransactionItem._(
      type: _TransactionType.expense,
      loggedAt: entry.loggedAt,
      amount: entry.amount,
      title: entry.purpose,
      income: null,
      expense: entry,
    );
  }

  final _TransactionType type;
  final DateTime loggedAt;
  final double amount;
  final String title;
  final IncomeEntry? income;
  final ExpenseEntry? expense;

  bool get isIncome => type == _TransactionType.income;
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  final _TransactionItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final timeFmt = DateFormat('HH:mm');
    final isIncome = item.isIncome;
    final amountColor = isIncome ? _kIncomeGreen : _kExpenseRed;
    final typeLabel = isIncome ? 'INCOME' : 'EXPENSE';

    return Dismissible(
      key: ValueKey('${item.type}:${isIncome ? item.income!.uuid : item.expense!.uuid}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.15),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Icon(Icons.edit_outlined,
            color: AppColors.accentBlue, size: 20),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.destructive.withOpacity(0.15),
          border: Border.all(color: AppColors.destructive.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.destructive, size: 20),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        final title = isIncome ? 'DELETE INCOME ENTRY?' : 'DELETE EXPENSE?';
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.backgroundElevated,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  side: BorderSide(color: AppColors.cardBorder),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 1,
                    color: AppColors.textPrimary,
                  ),
                ),
                content: const Text(
                  'This cannot be undone.',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('CANCEL',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('DELETE',
                        style: TextStyle(color: AppColors.destructive)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: timeFmt.format(item.loggedAt),
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      children: [
                        const TextSpan(text: ' | '),
                        TextSpan(
                          text: typeLabel,
                          style: TextStyle(color: amountColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs ${fmt.format(item.amount)}',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_outlined,
              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'NO TRANSACTIONS MATCHING "$query".',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try searching with a different keyword or amount.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz,
              size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'NO TRANSACTIONS LOGGED.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add your first entry.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddIncomeSheet extends ConsumerStatefulWidget {
  const _AddIncomeSheet();
  @override
  ConsumerState<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends ConsumerState<_AddIncomeSheet> {
  final _amountCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _uuid = const Uuid();

  DateTime _loggedAt = DateTime.now();
  String? _selectedFundUuid;
  bool _saving = false;
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _amountFocus.requestFocus());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    final source = _sourceCtrl.text.trim();
    if (amountStr.isEmpty || source.isEmpty || _selectedFundUuid == null) {
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    final entry = IncomeEntry()
      ..uuid = _uuid.v4()
      ..amount = amount
      ..source = source
      ..fundUuid = _selectedFundUuid
      ..loggedAt = _loggedAt;

    await ref.read(incomeRepositoryProvider).saveEntry(entry);
    if (_isRecurring) {
      final recurring = RecurringTransaction()
        ..uuid = _uuid.v4()
        ..type = RecurringTransactionType.income.index
        ..amount = amount
        ..title = source
        ..fundUuid = _selectedFundUuid
        ..startAt = _loggedAt
        ..lastGeneratedAt = _loggedAt
        ..frequency = _frequency.index
        ..isActive = true;
      await ref
          .read(recurringTransactionRepositoryProvider)
          .saveRecurring(recurring);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    setState(() {
      _loggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _loggedAt.hour,
        pickedTime?.minute ?? _loggedAt.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final accounts = ref.watch(allFundAccountsProvider).value ?? [];
    final canSave = _amountCtrl.text.trim().isNotEmpty &&
        _sourceCtrl.text.trim().isNotEmpty &&
        _selectedFundUuid != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('ADD INCOME',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 18, letterSpacing: 2)),
          ),
          const Divider(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetLabel('AMOUNT (LKR)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 38,
                    color: _kIncomeGreen,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 38,
                      color: AppColors.textSecondary,
                    ),
                    prefixText: 'RS  ',
                    prefixStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('SOURCE'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kDefaultSources.map((src) {
                    final isSel = _sourceCtrl.text == src;
                    return GestureDetector(
                      onTap: () => setState(() => _sourceCtrl.text = src),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _kIncomeGreen.withOpacity(0.15)
                              : AppColors.backgroundElevated,
                          border: Border.all(
                            color: isSel ? _kIncomeGreen : AppColors.cardBorder,
                            width: isSel ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          src,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight:
                                isSel ? FontWeight.w500 : FontWeight.w400,
                            color:
                                isSel ? _kIncomeGreen : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _sourceCtrl,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'or type a custom source...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('ADD TO FUND'),
                const SizedBox(height: 10),
                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      border: Border.all(
                        color: AppColors.destructive.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'No fund accounts yet. Go to FUNDS tab to create one first.',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.destructive,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((acc) {
                      final isSel = _selectedFundUuid == acc.uuid;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFundUuid = acc.uuid),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF4A90D9).withOpacity(0.15)
                                : AppColors.backgroundElevated,
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF4A90D9)
                                  : AppColors.cardBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 12,
                                color: isSel
                                    ? const Color(0xFF4A90D9)
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                acc.name,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  color: isSel
                                      ? const Color(0xFF4A90D9)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                const _SheetLabel('DATE & TIME'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSurface,
                      border: Border.all(color: AppColors.accentBlue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          dateFmt.format(_loggedAt),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'CHANGE',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 9,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _SheetLabel('RECURRING'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) =>
                          setState(() => _isRecurring = value),
                      activeThumbColor: _kIncomeGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecurring ? 'REPEATS' : 'ONE-TIME',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RecurrenceFrequency>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(
                      hintText: 'Frequency',
                    ),
                    icon: const Icon(Icons.expand_more),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    items: RecurrenceFrequency.values.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(freq.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _frequency = value);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || !canSave) ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _kIncomeGreen),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.backgroundPrimary,
                          ),
                        )
                      : const Text('CONFIRM'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditIncomeSheet extends ConsumerStatefulWidget {
  const _EditIncomeSheet({required this.entry});
  final IncomeEntry entry;

  @override
  ConsumerState<_EditIncomeSheet> createState() => _EditIncomeSheetState();
}

class _EditIncomeSheetState extends ConsumerState<_EditIncomeSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _sourceCtrl;
  late DateTime _loggedAt;
  late String? _selectedFundUuid;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.entry.amount.toString());
    _sourceCtrl = TextEditingController(text: widget.entry.source);
    _loggedAt = widget.entry.loggedAt;
    _selectedFundUuid = widget.entry.fundUuid;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    final source = _sourceCtrl.text.trim();
    if (amountStr.isEmpty || source.isEmpty || _selectedFundUuid == null) {
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    await ref.read(incomeRepositoryProvider).updateEntry(
          uuid: widget.entry.uuid,
          amount: amount,
          source: source,
          fundUuid: _selectedFundUuid,
          loggedAt: _loggedAt,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    setState(() {
      _loggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _loggedAt.hour,
        pickedTime?.minute ?? _loggedAt.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final accounts = ref.watch(allFundAccountsProvider).value ?? [];
    final canSave = _amountCtrl.text.trim().isNotEmpty &&
        _sourceCtrl.text.trim().isNotEmpty &&
        _selectedFundUuid != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('EDIT INCOME',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 18, letterSpacing: 2)),
          ),
          const Divider(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetLabel('AMOUNT (LKR)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 38,
                    color: _kIncomeGreen,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 38,
                      color: AppColors.textSecondary,
                    ),
                    prefixText: 'RS  ',
                    prefixStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('SOURCE'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kDefaultSources.map((src) {
                    final isSel = _sourceCtrl.text == src;
                    return GestureDetector(
                      onTap: () => setState(() => _sourceCtrl.text = src),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _kIncomeGreen.withOpacity(0.15)
                              : AppColors.backgroundElevated,
                          border: Border.all(
                            color: isSel ? _kIncomeGreen : AppColors.cardBorder,
                            width: isSel ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          src,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            letterSpacing: 2,
                            color: isSel
                                ? _kIncomeGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _sourceCtrl,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'or type a custom source...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('ADD TO FUND'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: accounts.map((acc) {
                    final isSel = _selectedFundUuid == acc.uuid;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFundUuid = acc.uuid),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF4A90D9).withOpacity(0.15)
                              : AppColors.backgroundElevated,
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF4A90D9)
                                : AppColors.cardBorder,
                            width: isSel ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              size: 12,
                              color: isSel
                                  ? const Color(0xFF4A90D9)
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              acc.name,
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 12,
                                letterSpacing: 1,
                                color: isSel
                                    ? const Color(0xFF4A90D9)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('DATE & TIME'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSurface,
                      border: Border.all(color: AppColors.accentBlue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          dateFmt.format(_loggedAt),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'CHANGE',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 9,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || !canSave) ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: _kIncomeGreen),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.backgroundPrimary,
                          ),
                        )
                      : const Text('SAVE CHANGES'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet();

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _uuid = const Uuid();

  DateTime _loggedAt = DateTime.now();
  String? _selectedFundUuid;
  bool _saving = false;
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    final purpose = _purposeCtrl.text.trim();
    if (amountStr.isEmpty || purpose.isEmpty || _selectedFundUuid == null) {
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    final entry = ExpenseEntry()
      ..uuid = _uuid.v4()
      ..amount = amount
      ..purpose = purpose
      ..fundUuid = _selectedFundUuid
      ..loggedAt = _loggedAt;

    await ref.read(expenseRepositoryProvider).saveEntry(entry);

    if (_isRecurring) {
      final recurring = RecurringTransaction()
        ..uuid = _uuid.v4()
        ..type = RecurringTransactionType.expense.index
        ..amount = amount
        ..title = purpose
        ..fundUuid = _selectedFundUuid
        ..startAt = _loggedAt
        ..lastGeneratedAt = _loggedAt
        ..frequency = _frequency.index
        ..isActive = true;
      await ref
          .read(recurringTransactionRepositoryProvider)
          .saveRecurring(recurring);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );

    setState(() {
      _loggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _loggedAt.hour,
        pickedTime?.minute ?? _loggedAt.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final accounts = ref.watch(allFundAccountsProvider).value ?? [];
    final canSave = _amountCtrl.text.trim().isNotEmpty &&
        _purposeCtrl.text.trim().isNotEmpty &&
        _selectedFundUuid != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'ADD EXPENSE',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
            ),
          ),
          const Divider(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetLabel('AMOUNT (LKR)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 38,
                    color: AppColors.accentGold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 38,
                      color: AppColors.textSecondary,
                    ),
                    prefixText: 'RS  ',
                    prefixStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('PURPOSE'),
                const SizedBox(height: 8),
                TextField(
                  controller: _purposeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Lunch, Transport, Groceries...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('PAY FROM FUND'),
                const SizedBox(height: 10),
                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      border: Border.all(
                        color: AppColors.destructive.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'No fund accounts yet. Go to FUNDS tab to create one first.',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.destructive,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((acc) {
                      final isSel = _selectedFundUuid == acc.uuid;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFundUuid = acc.uuid),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF4A90D9).withOpacity(0.15)
                                : AppColors.backgroundElevated,
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF4A90D9)
                                  : AppColors.cardBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 12,
                                color: isSel
                                    ? const Color(0xFF4A90D9)
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                acc.name,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  color: isSel
                                      ? const Color(0xFF4A90D9)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                const _SheetLabel('DATE & TIME'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSurface,
                      border: Border.all(color: AppColors.accentBlue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          dateFmt.format(_loggedAt),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'CHANGE',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 9,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _SheetLabel('RECURRING'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) =>
                          setState(() => _isRecurring = value),
                      activeThumbColor: AppColors.accentGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecurring ? 'REPEATS' : 'ONE-TIME',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<RecurrenceFrequency>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(
                      hintText: 'Frequency',
                    ),
                    icon: const Icon(Icons.expand_more),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    items: RecurrenceFrequency.values.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(freq.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _frequency = value);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || !canSave) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.backgroundPrimary,
                          ),
                        )
                      : const Text('CONFIRM'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditExpenseSheet extends ConsumerStatefulWidget {
  const _EditExpenseSheet({required this.entry});
  final ExpenseEntry entry;

  @override
  ConsumerState<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<_EditExpenseSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _purposeCtrl;
  late DateTime _loggedAt;
  late String? _selectedFundUuid;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.entry.amount.toString());
    _purposeCtrl = TextEditingController(text: widget.entry.purpose);
    _loggedAt = widget.entry.loggedAt;
    _selectedFundUuid = widget.entry.fundUuid;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    final purpose = _purposeCtrl.text.trim();
    if (amountStr.isEmpty || purpose.isEmpty || _selectedFundUuid == null) {
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    await ref.read(expenseRepositoryProvider).updateEntry(
          uuid: widget.entry.uuid,
          amount: amount,
          purpose: purpose,
          fundUuid: _selectedFundUuid,
          loggedAt: _loggedAt,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    setState(() {
      _loggedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _loggedAt.hour,
        pickedTime?.minute ?? _loggedAt.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final accounts = ref.watch(allFundAccountsProvider).value ?? [];
    final canSave = _amountCtrl.text.trim().isNotEmpty &&
        _purposeCtrl.text.trim().isNotEmpty &&
        _selectedFundUuid != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('EDIT EXPENSE',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 18, letterSpacing: 2)),
          ),
          const Divider(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetLabel('AMOUNT (LKR)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 38,
                    color: AppColors.accentGold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 38,
                      color: AppColors.textSecondary,
                    ),
                    prefixText: 'RS  ',
                    prefixStyle: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('PURPOSE'),
                const SizedBox(height: 8),
                TextField(
                  controller: _purposeCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Lunch, Transport, Groceries...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('PAY FROM FUND'),
                const SizedBox(height: 10),
                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      border: Border.all(
                        color: AppColors.destructive.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'No fund accounts yet.',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.destructive,
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((acc) {
                      final isSel = _selectedFundUuid == acc.uuid;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFundUuid = acc.uuid),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF4A90D9).withOpacity(0.15)
                                : AppColors.backgroundElevated,
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFF4A90D9)
                                  : AppColors.cardBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 12,
                                color: isSel
                                    ? const Color(0xFF4A90D9)
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                acc.name,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  color: isSel
                                      ? const Color(0xFF4A90D9)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                const _SheetLabel('DATE & TIME'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSurface,
                      border: Border.all(color: AppColors.accentBlue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text(
                          dateFmt.format(_loggedAt),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'CHANGE',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 9,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || !canSave) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.backgroundPrimary,
                          ),
                        )
                      : const Text('SAVE CHANGES'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        letterSpacing: 2,
        color: AppColors.textSecondary,
      ),
    );
  }
}
