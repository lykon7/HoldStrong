import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/income_entry.dart';
import '../../domain/providers/income_providers.dart';

// Default income source chips
const _kDefaultSources = ['DA', 'PM', 'UB'];

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allIncome = ref.watch(allIncomeProvider);
    final daily = ref.watch(dailyIncomeTotalProvider);
    final weekly = ref.watch(weeklyIncomeTotalProvider);
    final monthly = ref.watch(monthlyIncomeTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('INCOME'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Income',
            onPressed: () => _showAddIncomeSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary strip ──────────────────────────────────────────────
          _SummaryStrip(daily: daily, weekly: weekly, monthly: monthly),
          const Divider(height: 1),
          // ── Entry list ────────────────────────────────────────────────
          Expanded(
            child: allIncome.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const _EmptyState();
                }

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final yesterday = today.subtract(const Duration(days: 1));

                final items = <Object>[];
                DateTime? lastDay;

                for (final entry in entries) {
                  final entryDay = DateTime(
                    entry.loggedAt.year,
                    entry.loggedAt.month,
                    entry.loggedAt.day,
                  );
                  if (lastDay == null || entryDay != lastDay) {
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
                      label = DateFormat('EEEE, d MMM yyyy')
                          .format(entryDay)
                          .toUpperCase();
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
                    final entry = item as IncomeEntry;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _IncomeRow(
                        entry: entry,
                        onDelete: () => ref
                            .read(incomeRepositoryProvider)
                            .deleteEntry(entry.uuid),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIncomeSheet(context, ref),
        backgroundColor: const Color(0xFF3DAA6E),
        foregroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        child: const Icon(Icons.add),
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
            accentColor: const Color(0xFF3DAA6E),
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
// Income row with swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({required this.entry, required this.onDelete});

  final IncomeEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final timeFmt = DateFormat('HH:mm');

    return Dismissible(
      key: ValueKey(entry.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
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
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundElevated,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            title: const Text(
              'DELETE INCOME ENTRY?',
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
            // Source badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3DAA6E).withOpacity(0.12),
                border: Border.all(
                    color: const Color(0xFF3DAA6E).withOpacity(0.4)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                entry.source,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Color(0xFF3DAA6E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Time
            Expanded(
              child: Text(
                timeFmt.format(entry.loggedAt),
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Amount
            Text(
              'Rs ${fmt.format(entry.amount)}',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF3DAA6E),
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
          Icon(Icons.account_balance_wallet_outlined,
              size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'NO INCOME LOGGED.',
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
// Add income bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

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
    _sourceCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    final source = _sourceCtrl.text.trim();
    if (amountStr.isEmpty || source.isEmpty) return;
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    final entry = IncomeEntry()
      ..uuid = _uuid.v4()
      ..amount = amount
      ..source = source
      ..loggedAt = _loggedAt;

    await ref.read(incomeRepositoryProvider).saveEntry(entry);

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
              'ADD INCOME',
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
                    color: Color(0xFF3DAA6E),
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

                // Source — quick chips + text field
                const _SheetLabel('SOURCE'),
                const SizedBox(height: 10),
                // Default source chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kDefaultSources.map((src) {
                    final isSelected = _sourceCtrl.text == src;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _sourceCtrl.text = src;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3DAA6E).withOpacity(0.15)
                              : AppColors.backgroundElevated,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3DAA6E)
                                : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          src,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF3DAA6E)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // Custom source text field
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

                // Date & time
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
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DAA6E),
                  ),
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
