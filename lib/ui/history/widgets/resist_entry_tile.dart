import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/models/resist_entry.dart';

class ResistEntryTile extends StatelessWidget {
  const ResistEntryTile({
    super.key,
    required this.entry,
    required this.onDeleted,
  });

  final ResistEntry entry;
  final void Function(ResistEntry) onDeleted;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final timeFmt = DateFormat('HH:mm');

    return Dismissible(
      key: Key(entry.uuid),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDeleted(entry),
      background: Container(
        color: AppColors.destructive.withOpacity(0.3),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.destructive, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Amount
            Text(
              '${AppConstants.kCurrencySymbol} ${fmt.format(entry.amountLkr)}',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.label != null)
                    Text(
                      entry.label!.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    timeFmt.format(entry.loggedAt),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Calories
            if (entry.caloriesAvoided != null)
              Text(
                '~${entry.caloriesAvoided} kcal',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
