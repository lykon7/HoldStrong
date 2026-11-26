import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../domain/models/quick_transaction.dart';
import '../../../domain/providers/quick_transaction_providers.dart';

/// Choose which saved quick-add presets appear on the home screen row.
class QuickTransactionsPickerDialog extends ConsumerWidget {
  const QuickTransactionsPickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(quickTransactionsProvider);
    final notifier = ref.read(quickTransactionsProvider.notifier);

    Widget section(String title, List<QuickTransaction> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          for (final q in items)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.accentGold,
              checkColor: AppColors.backgroundPrimary,
              value: q.onHome,
              onChanged: (v) => notifier.update(q.withOnHome(v ?? false)),
              title: Text(
                q.amountLabel == null ? q.name : '${q.name}  ·  ${q.amountLabel}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      title: const Text(
        'HOME QUICK ACTIONS',
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 1,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: all.isEmpty
            ? const Text(
                'No presets yet. Create them in Settings → Quick Expenses / Quick Income.',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pick the presets to show on the home screen. Tap one to open it pre-filled; long-press to log it instantly (needs an amount and a fund). Manage presets in Settings.',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    section('EXPENSES', [
                      for (final q in all)
                        if (q.type == QuickTransactionType.expense) q
                    ]),
                    section('INCOME', [
                      for (final q in all)
                        if (q.type == QuickTransactionType.income) q
                    ]),
                  ],
                ),
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
