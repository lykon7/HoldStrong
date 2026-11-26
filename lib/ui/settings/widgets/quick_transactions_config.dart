import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../domain/models/quick_transaction.dart';
import '../../../domain/providers/expense_providers.dart';
import '../../../domain/providers/fund_providers.dart';
import '../../../domain/providers/income_providers.dart';
import '../../../domain/providers/quick_transaction_providers.dart';

const _kIncomeGreen = Color(0xFF3DAA6E);
const _kFundBlue = Color(0xFF4A90D9);

/// Manage the quick-add presets for one transaction type.
class QuickTransactionsConfigDialog extends ConsumerWidget {
  const QuickTransactionsConfigDialog({super.key, required this.type});

  final QuickTransactionType type;

  bool get _isIncome => type == QuickTransactionType.income;

  Future<void> _openEditor(BuildContext context, [QuickTransaction? existing]) {
    return showDialog(
      context: context,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _QuickTransactionEditor(type: type, existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
        _isIncome ? quickIncomesProvider : quickExpensesProvider);
    final funds = ref.watch(allFundAccountsProvider).value ?? [];
    String? fundName(String? uuid) {
      for (final f in funds) {
        if (f.uuid == uuid) return f.name;
      }
      return null;
    }

    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      title: Text(
        _isIncome ? 'QUICK INCOME' : 'QUICK EXPENSES',
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 1,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isIncome
                  ? 'Presets shown at the top of the Add Income window. Tapping one fills in the source, category and fund.'
                  : 'Presets shown at the top of the Add Expense window. Tapping one fills in the purpose, category and fund.',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No presets yet.',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final q = items[i];
                    final detail = [
                      if (q.category != null) q.category!,
                      if (fundName(q.fundUuid) != null) fundName(q.fundUuid)!,
                    ].join(' · ');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () => _openEditor(context, q),
                      title: Text(
                        q.name,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: detail.isEmpty
                          ? null
                          : Text(
                              detail,
                              style: const TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.textSecondary),
                        onPressed: () => ref
                            .read(quickTransactionsProvider.notifier)
                            .remove(q.id),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add,
                    size: 16, color: AppColors.accentGold),
                label: const Text(
                  'ADD PRESET',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.accentGold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('DONE',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
        ),
      ],
    );
  }
}

class _QuickTransactionEditor extends ConsumerStatefulWidget {
  const _QuickTransactionEditor({required this.type, this.existing});

  final QuickTransactionType type;
  final QuickTransaction? existing;

  @override
  ConsumerState<_QuickTransactionEditor> createState() =>
      _QuickTransactionEditorState();
}

class _QuickTransactionEditorState
    extends ConsumerState<_QuickTransactionEditor> {
  late final TextEditingController _nameCtrl;
  String? _category;
  String? _fundUuid;

  bool get _isIncome => widget.type == QuickTransactionType.income;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name);
    _category = widget.existing?.category;
    _fundUuid = widget.existing?.fundUuid;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    var name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    // Income sources are shown in capitals throughout the app.
    if (_isIncome) name = name.toUpperCase();

    final notifier = ref.read(quickTransactionsProvider.notifier);
    final existing = widget.existing;
    if (existing == null) {
      await notifier.add(QuickTransaction.create(
        type: widget.type,
        name: name,
        category: _category,
        fundUuid: _fundUuid,
      ));
    } else {
      await notifier.update(existing.edited(
        name: name,
        category: _category,
        fundUuid: _fundUuid,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(
        _isIncome ? incomeCategoriesProvider : expenseCategoriesProvider);
    final allAccounts = ref.watch(allFundAccountsProvider).value ?? [];
    final deductible = ref.watch(deductibleFundAccountsProvider);
    final accounts = (_isIncome || deductible.isEmpty)
        ? allAccounts
        : allAccounts.where((a) => deductible.contains(a.uuid)).toList();
    final accent = _isIncome ? _kIncomeGreen : _kFundBlue;

    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      title: Text(
        widget.existing == null ? 'ADD PRESET' : 'EDIT PRESET',
        style: const TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: widget.existing == null,
              textCapitalization: _isIncome
                  ? TextCapitalization.characters
                  : TextCapitalization.sentences,
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                labelText: _isIncome ? 'Source (e.g. Salary)' : 'Name (e.g. Fuel)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // A category that was since deleted from settings is dropped
              // rather than crashing the dropdown.
              initialValue: categories.contains(_category) ? _category : null,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Category (optional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              icon: const Icon(Icons.expand_more),
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              dropdownColor: AppColors.backgroundElevated,
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('None')),
                ...categories.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            Text(
              _isIncome ? 'ADD TO FUND (OPTIONAL)' : 'PAY FROM FUND (OPTIONAL)',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accounts.map((acc) {
                final isSel = _fundUuid == acc.uuid;
                return GestureDetector(
                  // Tap again to clear the fund.
                  onTap: () =>
                      setState(() => _fundUuid = isSel ? null : acc.uuid),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? accent.withOpacity(0.15)
                          : AppColors.backgroundSurface,
                      border: Border.all(
                        color: isSel ? accent : AppColors.cardBorder,
                        width: isSel ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      acc.name,
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 12,
                        color: isSel ? accent : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('SAVE',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
        ),
      ],
    );
  }
}
