import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/recurring_transaction.dart';
import '../../domain/providers/fund_providers.dart';
import '../../domain/providers/recurring_transaction_providers.dart';
import '../../domain/providers/income_providers.dart';
import '../../domain/providers/expense_providers.dart';

const _kIncomeGreen = Color(0xFF3DAA6E);
const _kExpenseRed = AppColors.destructive;

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(allRecurringTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('RECURRING'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: recurring.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _RecurringCard(
                rule: rule,
                onEdit: () => _showEditSheet(context, ref, rule),
                onDelete: () => _confirmDelete(context, ref, rule),
                onToggleActive: (value) => ref
                    .read(recurringTransactionRepositoryProvider)
                    .setActive(rule.uuid, value),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction rule,
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
        child: _EditRecurringSheet(rule: rule),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction rule,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'DELETE RECURRING RULE?',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will stop future entries. Past transactions stay.',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(recurringTransactionRepositoryProvider)
                  .deleteRecurring(rule.uuid);
            },
            child: const Text('DELETE',
                style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final RecurringTransaction rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final type = _typeFromCode(rule.type);
    final frequency = _frequencyFromCode(rule.frequency);
    final amountColor =
        type == RecurringTransactionType.income ? _kIncomeGreen : _kExpenseRed;
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');
    final now = DateTime.now();
    final next = _nextOccurrence(rule, now);

    final typeLabel = type.label.toUpperCase();
    final freqLabel = frequency.label.toUpperCase();
    final statusLabel = rule.isActive
        ? 'NEXT ${dateFmt.format(next)}'
        : 'PAUSED';

    return Dismissible(
      key: ValueKey(rule.uuid),
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
        onDelete();
        return false;
      },
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
                    rule.title,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$typeLabel • $freqLabel • $statusLabel',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'START ${dateFmt.format(rule.startAt)}',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${fmt.format(rule.amount)}',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 6),
                Switch(
                  value: rule.isActive,
                  onChanged: onToggleActive,
                  activeThumbColor: amountColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditRecurringSheet extends ConsumerStatefulWidget {
  const _EditRecurringSheet({required this.rule});
  final RecurringTransaction rule;

  @override
  ConsumerState<_EditRecurringSheet> createState() =>
      _EditRecurringSheetState();
}

class _EditRecurringSheetState extends ConsumerState<_EditRecurringSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _titleCtrl;
  late DateTime _startAt;
  late String? _selectedFundUuid;
  late String? _selectedCategory;
  late RecurringTransactionType _type;
  late RecurrenceFrequency _frequency;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.rule.amount.toString());
    _titleCtrl = TextEditingController(text: widget.rule.title);
    _startAt = widget.rule.startAt;
    _selectedFundUuid = widget.rule.fundUuid;
    _selectedCategory = widget.rule.category;
    _type = _typeFromCode(widget.rule.type);
    _frequency = _frequencyFromCode(widget.rule.frequency);
    _isActive = widget.rule.isActive;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    if (amountStr.isEmpty || title.isEmpty || _selectedFundUuid == null) {
      return;
    }
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    widget.rule
      ..amount = amount
      ..title = title
      ..category = _selectedCategory
      ..fundUuid = _selectedFundUuid
      ..startAt = _startAt
      ..type = _type.index
      ..frequency = _frequency.index
      ..isActive = _isActive;

    await ref
        .read(recurringTransactionRepositoryProvider)
        .updateRecurring(widget.rule);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      initialTime: TimeOfDay.fromDateTime(_startAt),
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
      _startAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _startAt.hour,
        pickedTime?.minute ?? _startAt.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final accounts = ref.watch(allFundAccountsProvider).value ?? [];
    final canSave = _amountCtrl.text.trim().isNotEmpty &&
        _titleCtrl.text.trim().isNotEmpty &&
        _selectedFundUuid != null;
    final amountColor =
        _type == RecurringTransactionType.income ? _kIncomeGreen : _kExpenseRed;

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
            child: Text('EDIT RECURRING',
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
                const _SheetLabel('TYPE'),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurringTransactionType>(
                  initialValue: _type,
                  decoration: const InputDecoration(hintText: 'Type'),
                  items: RecurringTransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 16),
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
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 38,
                    color: amountColor,
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
                _SheetLabel(
                  _type == RecurringTransactionType.income ? 'SOURCE' : 'PURPOSE'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Salary, Rent, Subscription...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('CATEGORY'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
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
                    ...(_type == RecurringTransactionType.income
                            ? ref.watch(incomeCategoriesProvider)
                            : ref.watch(expenseCategoriesProvider))
                        .map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(height: 20),
                _SheetLabel(
                  _type == RecurringTransactionType.income ? 'ADD TO FUND' : 'PAY FROM FUND'),
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
                          dateFmt.format(_startAt),
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
                const _SheetLabel('FREQUENCY'),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(hintText: 'Frequency'),
                  icon: const Icon(Icons.expand_more),
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
                const SizedBox(height: 16),
                const _SheetLabel('STATUS'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      value: _isActive,
                      onChanged: (value) =>
                          setState(() => _isActive = value),
                      activeThumbColor: amountColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isActive ? 'ACTIVE' : 'PAUSED',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_saving || !canSave) ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: amountColor),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat,
              size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'NO RECURRING RULES.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create one from the add transaction flow.',
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

RecurringTransactionType _typeFromCode(int code) {
  if (code < 0 || code >= RecurringTransactionType.values.length) {
    return RecurringTransactionType.expense;
  }
  return RecurringTransactionType.values[code];
}

RecurrenceFrequency _frequencyFromCode(int code) {
  if (code < 0 || code >= RecurrenceFrequency.values.length) {
    return RecurrenceFrequency.monthly;
  }
  return RecurrenceFrequency.values[code];
}

DateTime _nextOccurrence(RecurringTransaction rule, DateTime now) {
  DateTime next;
  if (rule.lastGeneratedAt == null) {
    next = rule.startAt;
  } else {
    next = _addFrequency(rule.lastGeneratedAt!, rule.frequency);
  }

  while (next.isBefore(now)) {
    next = _addFrequency(next, rule.frequency);
  }

  return next;
}

DateTime _addFrequency(DateTime from, int frequencyCode) {
  final frequency = _frequencyFromCode(frequencyCode);
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return from.add(const Duration(days: 1));
    case RecurrenceFrequency.weekly:
      return from.add(const Duration(days: 7));
    case RecurrenceFrequency.monthly:
      return _addMonths(from, 1);
    case RecurrenceFrequency.yearly:
      return _addMonths(from, 12);
  }
}

DateTime _addMonths(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final targetYear = date.year + (monthIndex ~/ 12);
  final targetMonth = (monthIndex % 12) + 1;
  final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final targetDay = date.day <= lastDayOfMonth ? date.day : lastDayOfMonth;

  return DateTime(
    targetYear,
    targetMonth,
    targetDay,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}
