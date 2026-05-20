import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/liability_item.dart';
import '../../domain/providers/liability_providers.dart';

class LiabilitiesScreen extends ConsumerWidget {
  const LiabilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = ref.watch(overdueProvider);
    final dueThisWeek = ref.watch(dueThisWeekProvider);
    final dueThisMonth = ref.watch(dueThisMonthProvider);
    final upcoming = ref.watch(upcomingProvider);
    final monthlyTotal = ref.watch(monthlyLiabilityTotalProvider);
    final totalOutstanding = ref.watch(totalOutstandingLiabilityProvider);
    final allAsync = ref.watch(allLiabilitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIABILITIES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSheet(context, ref),
          ),
        ],
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          final hasAny = overdue.isNotEmpty ||
              dueThisWeek.isNotEmpty ||
              dueThisMonth.isNotEmpty ||
              upcoming.isNotEmpty;
          return CustomScrollView(
            slivers: [
              // ── Header summary card ───────────────────────────────────
              SliverToBoxAdapter(
                child: _SummaryHeader(
                  monthlyTotal: monthlyTotal,
                  totalOutstanding: totalOutstanding,
                ),
              ),
              if (!hasAny)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'No upcoming liabilities.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap + to add one.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                    label: 'OVERDUE', color: AppColors.destructive),
                _LiabilityList(items: overdue, ref: ref),
              ],
              if (dueThisWeek.isNotEmpty) ...[
                _SectionHeader(
                    label: 'DUE THIS WEEK', color: AppColors.accentGold),
                _LiabilityList(items: dueThisWeek, ref: ref),
              ],
              if (dueThisMonth.isNotEmpty) ...[
                _SectionHeader(
                    label: 'DUE THIS MONTH', color: const Color(0xFF7C83FD)),
                _LiabilityList(items: dueThisMonth, ref: ref),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                    label: 'LATER',
                    color: const Color(0xFF4CAF82)),
                _LiabilityList(items: upcoming, ref: ref),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // ── Add bottom sheet ────────────────────────────────────────────────────
  static Future<void> _showAddSheet(BuildContext context, WidgetRef ref,
      {LiabilityItem? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LiabilityForm(existing: existing, ref: ref),
    );
  }

  static Future<void> showEditSheet(BuildContext context, WidgetRef ref,
      LiabilityItem item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LiabilityForm(existing: item, ref: ref),
    );
  }
}

// ── Section header sliver ────────────────────────────────────────────────────

class _SectionHeader extends SliverToBoxAdapter {
  _SectionHeader({required String label, required Color color})
      : super(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 2,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
}

// ── Liability list sliver ─────────────────────────────────────────────────────

class _LiabilityList extends SliverList {
  _LiabilityList({required List<LiabilityItem> items, required WidgetRef ref})
      : super(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _LiabilityTile(item: items[index], ref: ref),
            childCount: items.length,
          ),
        );
}

// ── Single tile ──────────────────────────────────────────────────────────────

class _LiabilityTile extends ConsumerWidget {
  final LiabilityItem item;
  final WidgetRef ref;

  const _LiabilityTile({required this.item, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = item.dueDate.isBefore(today);
    final dateColor = isOverdue ? AppColors.destructive : AppColors.accentGold;
    final isBnpl = item.type == LiabilityType.bnpl.index;

    return Dismissible(
      key: ValueKey(item.uuid),
      direction: DismissDirection.horizontal,
      background: Container(
        color: const Color(0xFF4CAF82).withOpacity(0.85),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('PAID',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontFamily: 'IBMPlexMono')),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: AppColors.destructive.withOpacity(0.85),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('DELETE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontFamily: 'IBMPlexMono')),
          ],
        ),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          ref.read(liabilityControllerProvider.notifier).markPaid(item.uuid);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"${item.title}" marked as paid → logged to expenses'),
          ));
          return false;
        }
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete Liability'),
                content: Text('Remove "${item.title}"?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('DELETE',
                          style: TextStyle(color: AppColors.destructive))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart) {
          ref.read(liabilityControllerProvider.notifier).delete(item.uuid);
        }
      },
      child: InkWell(
        onTap: () => LiabilitiesScreen.showEditSheet(context, ref, item),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeIcon(type: item.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 11, color: dateColor),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(item.dueDate),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: dateColor,
                                  letterSpacing: 0.5),
                            ),
                            if (item.isRecurring) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.repeat,
                                  size: 11,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Text(
                                _freqLabel(item.recurrenceFrequency),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'LKR ${item.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: isOverdue
                          ? AppColors.destructive
                          : AppColors.accentGold,
                    ),
                  ),
                ],
              ),
              if (isBnpl && item.instalmentNumber != null) ...[
                const SizedBox(height: 8),
                _InstalmentBadge(
                  number: item.instalmentNumber!,
                  total: item.totalInstalments ?? item.instalmentNumber!,
                ),
              ],
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.notes!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _freqLabel(int? code) {
    if (code == null) return '';
    return LiabilityFrequency.values[code % LiabilityFrequency.values.length]
        .label
        .toUpperCase();
  }
}

// ── Type icon chip ─────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final int type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final data = _data();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: data.$2.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.$2.withOpacity(0.3)),
      ),
      child: Icon(data.$1, size: 20, color: data.$2),
    );
  }

  (IconData, Color) _data() {
    switch (type) {
      case 0: // bnpl
        return (Icons.credit_card_outlined, const Color(0xFF7C83FD));
      case 1: // subscription
        return (Icons.subscriptions_outlined, const Color(0xFF4FC3F7));
      case 2: // bill
        return (Icons.receipt_long_outlined, AppColors.accentGold);
      case 3: // loan
        return (Icons.account_balance_outlined, const Color(0xFFFF8A65));
      default:
        return (Icons.payments_outlined, AppColors.textSecondary);
    }
  }
}

// ── BNPL instalment badge ─────────────────────────────────────────────────────

class _InstalmentBadge extends StatelessWidget {
  final int number;
  final int total;
  const _InstalmentBadge({required this.number, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (number / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0xFF7C83FD).withOpacity(0.4)),
              ),
              child: Text(
                'INSTALMENT $number of $total',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: Color(0xFF7C83FD),
                  fontFamily: 'IBMPlexMono',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: AppColors.cardBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C83FD)),
          ),
        ),
      ],
    );
  }
}

// ── Summary header ─────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final double monthlyTotal;
  final double totalOutstanding;
  const _SummaryHeader({
    required this.monthlyTotal,
    required this.totalOutstanding,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM').format(DateTime.now());
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1427), Color(0xFF111318)],
        ),
        border: Border.all(color: const Color(0xFF7C83FD).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Monthly column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DUE IN $month'.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  'LKR ${monthlyTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    letterSpacing: 1,
                    color: Color(0xFF7C83FD),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 44,
            color: const Color(0xFF7C83FD).withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Total outstanding column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL DUE',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                'LKR ${totalOutstanding.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: 1,
                  color: totalOutstanding > 0
                      ? AppColors.destructive
                      : const Color(0xFF4CAF82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit form ─────────────────────────────────────────────────────────

class _LiabilityForm extends StatefulWidget {
  final LiabilityItem? existing;
  final WidgetRef ref;

  const _LiabilityForm({this.existing, required this.ref});

  @override
  State<_LiabilityForm> createState() => _LiabilityFormState();
}

class _LiabilityFormState extends State<_LiabilityForm> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _totalInstCtrl = TextEditingController();

  LiabilityType _type = LiabilityType.bill;
  bool _isRecurring = false;
  LiabilityFrequency _frequency = LiabilityFrequency.monthly;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isBnpl = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toString();
      _notesCtrl.text = e.notes ?? '';
      _type = LiabilityType.values[e.type % LiabilityType.values.length];
      _isBnpl = e.type == LiabilityType.bnpl.index;
      _isRecurring = e.isRecurring;
      _dueDate = e.dueDate;
      _frequency = e.recurrenceFrequency != null
          ? LiabilityFrequency.values[
              e.recurrenceFrequency! % LiabilityFrequency.values.length]
          : LiabilityFrequency.monthly;
      _totalInstCtrl.text = e.totalInstalments?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _totalInstCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (title.isEmpty || amount == null) return;

    final notifier = widget.ref.read(liabilityControllerProvider.notifier);

    // ── BNPL: new entry → create N individual instalment entries ──────────
    if (_isBnpl && !_isEdit) {
      final count = int.tryParse(_totalInstCtrl.text.trim()) ?? 1;
      notifier.addBnplInstalments(
        title: title,
        amount: amount,
        startDate: _dueDate,
        count: count,
        frequency: _frequency,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      Navigator.of(context).pop();
      return;
    }

    // ── All other cases (non-BNPL new, or editing any single entry) ───────
    final item = widget.existing ?? (LiabilityItem()..uuid = const Uuid().v4());
    item
      ..title = title
      ..amount = amount
      ..type = _type.index
      ..dueDate = _dueDate
      ..isRecurring = _isRecurring
      ..recurrenceFrequency = _isRecurring ? _frequency.index : null
      ..notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()
      ..createdAt = widget.existing?.createdAt ?? DateTime.now();

    if (_isEdit) {
      notifier.edit(item);
    } else {
      notifier.add(item);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isEdit ? 'EDIT LIABILITY' : 'ADD LIABILITY',
                style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: 2)),
            const SizedBox(height: 20),

            // Type selector
            const Text('TYPE',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LiabilityType.values.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(t.label),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _type = t;
                    _isBnpl = t == LiabilityType.bnpl;
                    if (_isBnpl) _isRecurring = true;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Amount
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                  labelText: 'Amount (LKR)',
                  prefixText: 'LKR '),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Due date
            GestureDetector(
              onTap: _pickDate,
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
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text(
                      'Due: ${DateFormat('dd MMM yyyy').format(_dueDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // BNPL total instalments
            if (_isBnpl) ...[
              TextField(
                controller: _totalInstCtrl,
                decoration: const InputDecoration(
                    labelText: 'Total Instalments'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
            ],

            // Recurring toggle (non-BNPL)
            if (!_isBnpl)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recurring',
                    style: TextStyle(fontSize: 13)),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeColor: AppColors.accentGold,
              ),

            // Frequency
            if (_isRecurring || _isBnpl) ...[
              const Text('FREQUENCY',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: LiabilityFrequency.values.map((f) {
                  return ChoiceChip(
                    label: Text(f.label),
                    selected: _frequency == f,
                    onSelected: (_) =>
                        setState(() => _frequency = f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Notes
            TextField(
              controller: _notesCtrl,
              decoration:
                  const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEdit ? 'SAVE CHANGES' : 'ADD LIABILITY'),
            ),
          ],
        ),
      ),
    );
  }
}
