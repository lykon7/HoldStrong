import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/expense_entry.dart';
import '../../domain/providers/expense_providers.dart';
import '../../domain/providers/fund_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExpenses = ref.watch(allExpensesProvider);
    final daily = ref.watch(dailyExpenseTotalProvider);
    final weekly = ref.watch(weeklyExpenseTotalProvider);
    final monthly = ref.watch(monthlyExpenseTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('EXPENSES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Expense',
            onPressed: () => _showAddExpenseSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary strip ──────────────────────────────────────────────
          _SummaryStrip(daily: daily, weekly: weekly, monthly: monthly),
          // ── Divider ───────────────────────────────────────────────────
          const Divider(height: 1),
          // ── Entry list ────────────────────────────────────────────────
          Expanded(
            child: allExpenses.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const _EmptyState();
                }

                // Build grouped flat list: [_DayHeader, ExpenseEntry, ...]
                final now = DateTime.now();
                final today =
                    DateTime(now.year, now.month, now.day);
                final yesterday =
                    today.subtract(const Duration(days: 1));

                final items = <Object>[];
                DateTime? lastDay;

                for (final entry in entries) {
                  final entryDay = DateTime(
                    entry.loggedAt.year,
                    entry.loggedAt.month,
                    entry.loggedAt.day,
                  );
                  if (lastDay == null || entryDay != lastDay) {
                    // Compute day total
                    final dayTotal = entries
                        .where((e) =>
                            DateTime(e.loggedAt.year, e.loggedAt.month,
                                e.loggedAt.day) ==
                            entryDay)
                        .fold<double>(0.0, (s, e) => s + e.amount);

                    String label;
                    if (entryDay == today) {
                      label = 'TODAY';
                    } else if (entryDay == yesterday) {
                      label = 'YESTERDAY';
                    } else {
                      label =
                          DateFormat('EEEE, d MMM yyyy').format(entryDay).toUpperCase();
                    }
                    items.add(_DayHeader(label: label, total: dayTotal));
                    lastDay = entryDay;
                  }
                  items.add(entry);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is _DayHeader) {
                      return _DayHeaderTile(header: item);
                    }
                    final entry = item as ExpenseEntry;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ExpenseRow(
                        entry: entry,
                        onDelete: () => ref
                            .read(expenseRepositoryProvider)
                            .deleteEntry(entry.uuid),
                        onEdit: () => _showEditSheet(context, ref, entry),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FAB for primary action
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseSheet(context, ref),
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        child: const Icon(Icons.add),
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

  void _showEditSheet(BuildContext context, WidgetRef ref, ExpenseEntry entry) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Summary strip
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.daily,
    required this.weekly,
    required this.monthly,
  });

  final AsyncValue<double> daily;
  final AsyncValue<double> weekly;
  final AsyncValue<double> monthly;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart =
        todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dayFmt = DateFormat('d MMM');
    final monthFmt = DateFormat('MMMM yyyy');

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _SummaryCard(
            label: 'TODAY',
            sublabel: dayFmt.format(now),
            value: daily,
            accentColor: AppColors.accentGold,
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'THIS WEEK',
            sublabel:
                '${dayFmt.format(weekStart)} – ${dayFmt.format(weekEnd)}',
            value: weekly,
            accentColor: const Color(0xFF4A90D9),
          ),
          const SizedBox(width: 12),
          _SummaryCard(
            label: 'THIS MONTH',
            sublabel: monthFmt.format(now),
            value: monthly,
            accentColor: const Color(0xFF7B68EE),
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
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String sublabel;
  final AsyncValue<double> value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        border: Border.all(color: AppColors.cardBorder),
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
                  color: accentColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          value.when(
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppColors.accentGold),
            ),
            error: (_, __) => const Text('—'),
            data: (total) => Text(
              'Rs ${fmt.format(total)}',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day grouping helpers
// ─────────────────────────────────────────────────────────────────────────────

class _DayHeader {
  const _DayHeader({required this.label, required this.total});
  final String label;
  final double total;
}

class _DayHeaderTile extends StatelessWidget {
  const _DayHeaderTile({required this.header});
  final _DayHeader header;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
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
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.cardBorder,
              margin: const EdgeInsets.only(bottom: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rs ${fmt.format(header.total)}',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense row with swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  final ExpenseEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final timeFmt = DateFormat('HH:mm');

    return Dismissible(
      key: ValueKey(entry.uuid),
      direction: DismissDirection.horizontal,
      // Right background = edit (startToEnd)
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
      // Left background = delete (endToStart)
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
          // Swipe right = edit — show sheet and never actually dismiss
          onEdit();
          return false;
        }
        // Swipe left = delete
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundElevated,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            title: const Text(
              'DELETE EXPENSE?',
              style: TextStyle(
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
        ) ?? false;
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
                    entry.purpose,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (entry.category != null && entry.category!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.category!,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeFmt.format(entry.loggedAt),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs ${fmt.format(entry.amount)}',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.accentGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'NO EXPENSES LOGGED.',
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

// ─────────────────────────────────────────────────────────────────────────────
// Add expense bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

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
  String? _selectedCategory;
  bool _saving = false;

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
    if (amountStr.isEmpty || purpose.isEmpty || _selectedFundUuid == null) return;
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    final entry = ExpenseEntry()
      ..uuid = _uuid.v4()
      ..amount = amount
      ..purpose = purpose
      ..category = _selectedCategory
      ..fundUuid = _selectedFundUuid
      ..loggedAt = _loggedAt;

    await ref.read(expenseRepositoryProvider).saveEntry(entry);

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
          // Handle bar
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
                // Amount
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

                // Purpose
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

                const _SheetLabel('CATEGORY'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'Select category (optional)',
                  ),
                  icon: const Icon(Icons.expand_more),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  dropdownColor: AppColors.backgroundElevated,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...ref.watch(expenseCategoriesProvider).map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 20),

                // Fund account picker
                const _SheetLabel('PAY FROM FUND'),
                const SizedBox(height: 10),
                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      border: Border.all(
                          color: AppColors.destructive.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'No fund accounts yet. Go to FUNDS tab to create one first.',
                      style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 11,
                          color: AppColors.destructive),
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
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF4A90D9).withOpacity(0.15)
                                : AppColors.backgroundElevated,
                            border: Border.all(
                                color: isSel
                                    ? const Color(0xFF4A90D9)
                                    : AppColors.cardBorder,
                                width: isSel ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.savings_outlined,
                                  size: 12,
                                  color: isSel
                                      ? const Color(0xFF4A90D9)
                                      : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(acc.name,
                                  style: TextStyle(
                                      fontFamily: 'IBMPlexMono',
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      color: isSel
                                          ? const Color(0xFF4A90D9)
                                          : AppColors.textSecondary)),
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
                        horizontal: 16, vertical: 14),
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

                // Confirm button
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

// ─────────────────────────────────────────────────────────────────────────────
// Edit expense bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

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
  late String? _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.entry.amount.toString());
    _purposeCtrl = TextEditingController(text: widget.entry.purpose);
    _loggedAt = widget.entry.loggedAt;
    _selectedFundUuid = widget.entry.fundUuid;
    _selectedCategory = widget.entry.category;
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
          category: _selectedCategory,
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
        pickedDate.year, pickedDate.month, pickedDate.day,
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
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
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
                      color: AppColors.accentGold),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700,
                        fontSize: 38,
                        color: AppColors.textSecondary),
                    prefixText: 'RS  ',
                    prefixStyle: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                        color: AppColors.textSecondary),
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

                const _SheetLabel('CATEGORY'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    hintText: 'Select category (optional)',
                  ),
                  icon: const Icon(Icons.expand_more),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  dropdownColor: AppColors.backgroundElevated,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...ref.watch(expenseCategoriesProvider).map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 20),

                // Fund account picker
                const _SheetLabel('PAY FROM FUND'),
                const SizedBox(height: 10),
                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      border: Border.all(
                          color: AppColors.destructive.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'No fund accounts yet.',
                      style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 11,
                          color: AppColors.destructive),
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
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFF4A90D9).withOpacity(0.15)
                                : AppColors.backgroundElevated,
                            border: Border.all(
                                color: isSel
                                    ? const Color(0xFF4A90D9)
                                    : AppColors.cardBorder,
                                width: isSel ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.savings_outlined,
                                  size: 12,
                                  color: isSel
                                      ? const Color(0xFF4A90D9)
                                      : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(acc.name,
                                  style: TextStyle(
                                      fontFamily: 'IBMPlexMono',
                                      fontSize: 12,
                                      letterSpacing: 1,
                                      color: isSel
                                          ? const Color(0xFF4A90D9)
                                          : AppColors.textSecondary)),
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
                        horizontal: 16, vertical: 14),
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
                        Text(dateFmt.format(_loggedAt),
                            style: const TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 12,
                                color: AppColors.textPrimary)),
                        const Spacer(),
                        const Text('CHANGE',
                            style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 9,
                                letterSpacing: 1.5,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || !canSave) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.backgroundPrimary))
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
