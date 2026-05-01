import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/models/resist_entry.dart';

class RecentFeed extends StatelessWidget {
  const RecentFeed({super.key, required this.entries});

  final List<ResistEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text(
        'NO RESISTS LOGGED YET.',
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 11,
          letterSpacing: 1,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ...entries.map((e) => _EntryRow(entry: e)),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final ResistEntry entry;

  String _elapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '${AppConstants.kCurrencySymbol} ${fmt.format(entry.amountLkr)}',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.accentGold,
            ),
          ),
          const SizedBox(width: 10),
          if (entry.label != null)
            Expanded(
              child: Text(
                entry.label!.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          Text(
            _elapsed(entry.loggedAt),
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
