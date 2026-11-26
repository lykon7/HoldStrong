import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../domain/models/quick_transaction.dart';
import '../../../domain/providers/quick_transaction_providers.dart';
import '../../transactions/transactions_screen.dart' show showAddTransactionSheet;
import 'quick_transactions_picker.dart';

const _kIncomeGreen = Color(0xFF3DAA6E);

/// One scrollable row of pinned quick-add presets. Tapping one opens the
/// matching add sheet pre-filled; the last button picks which presets show.
class QuickTransactionsRow extends ConsumerWidget {
  const QuickTransactionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned =
        ref.watch(quickTransactionsProvider).where((q) => q.onHome).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final q in pinned) _QuickChip(preset: q),
          _EditButton(
            onTap: () => showDialog(
              context: context,
              builder: (_) => const QuickTransactionsPickerDialog(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.preset});

  final QuickTransaction preset;

  @override
  Widget build(BuildContext context) {
    final isIncome = preset.type == QuickTransactionType.income;
    final color = isIncome ? _kIncomeGreen : AppColors.destructive;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () =>
            showAddTransactionSheet(context, preset.type, preset: preset),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ],
              ),
              if (preset.amountLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    preset.amountLabel!,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Icon(Icons.edit_outlined,
            size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
