import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../domain/providers/resist_providers.dart';
import '../../domain/providers/goal_providers.dart';
import '../../data/models/resist_entry.dart';
import 'widgets/resist_entry_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('HISTORY')),
      body: entriesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'NO RESISTS LOGGED YET.',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          // Group by day
          final grouped = _groupByDay(entries);
          final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final dayEntries = grouped[day]!;
              final dayTotal = dayEntries.fold<double>(0, (s, e) => s + e.amountLkr);
              final fmt = NumberFormat('#,##0', 'en_US');
              final dateFmt = DateFormat('EEEE, dd MMM yyyy');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFmt.format(day).toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'RS ${fmt.format(dayTotal)}',
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: AppColors.cardBorder,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ...dayEntries.map((entry) => ResistEntryTile(
                    entry: entry,
                    onDeleted: (deletedEntry) async {
                      final repo = ref.read(resistRepositoryProvider);
                      await repo.deleteEntry(deletedEntry.uuid);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('ENTRY DELETED'),
                          action: SnackBarAction(
                            label: 'UNDO',
                            onPressed: () => repo.saveEntry(deletedEntry),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<DateTime, List<ResistEntry>> _groupByDay(List<ResistEntry> entries) {
    final map = <DateTime, List<ResistEntry>>{};
    for (final e in entries) {
      final day = DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day);
      (map[day] ??= []).add(e);
    }
    return map;
  }
}
