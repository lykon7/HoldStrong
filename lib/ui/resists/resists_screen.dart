import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/goal.dart';
import '../../data/models/resist_entry.dart';
import '../../domain/providers/goal_providers.dart';
import '../../domain/providers/resist_providers.dart';
import '../goals/widgets/goal_card.dart';
import '../history/widgets/resist_entry_tile.dart';

class ResistsScreen extends ConsumerWidget {
  const ResistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);
    final entriesAsync = ref.watch(allEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('RESISTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Goal',
            onPressed: () => context.push('/goals/new'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildGoalsSection(goalsAsync)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: _buildHistorySection(context, ref, entriesAsync),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(AsyncValue<List<Goal>> goalsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('GOALS'),
          const SizedBox(height: 8),
          goalsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            data: (goals) {
              if (goals.isEmpty) {
                return const Text(
                  'NO GOALS YET. CREATE ONE.',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    letterSpacing: 1,
                    color: AppColors.textSecondary,
                  ),
                );
              }

              final active = goals.where((g) => g.isActive).toList();
              final inactive =
                  goals.where((g) => !g.isActive && !g.isCompleted).toList();
              final completed = goals.where((g) => g.isCompleted).toList();

              final children = <Widget>[];

              if (active.isNotEmpty) {
                children.addAll([
                  const _SectionHeader('ACTIVE'),
                  const SizedBox(height: 8),
                  ...active.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GoalCard(goal: g, isHighlighted: true),
                      )),
                  const SizedBox(height: 16),
                ]);
              }

              if (inactive.isNotEmpty) {
                children.addAll([
                  const _SectionHeader('INACTIVE'),
                  const SizedBox(height: 8),
                  ...inactive.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GoalCard(goal: g, isHighlighted: false),
                      )),
                  const SizedBox(height: 16),
                ]);
              }

              if (completed.isNotEmpty) {
                children.addAll([
                  const _SectionHeader('COMPLETED'),
                  const SizedBox(height: 8),
                  ...completed.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GoalCard(goal: g, isHighlighted: false),
                      )),
                ]);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ResistEntry>> entriesAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SectionHeader('RESIST HISTORY'),
          ),
          entriesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Error: $e',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
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

              final grouped = _groupByDay(entries);
              final days = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));
              final fmt = NumberFormat('#,##0', 'en_US');
              final dateFmt = DateFormat('EEEE, dd MMM yyyy');

              final widgets = <Widget>[];
              for (final day in days) {
                final dayEntries = grouped[day]!;
                final dayTotal =
                    dayEntries.fold<double>(0, (s, e) => s + e.amountLkr);

                widgets.addAll([
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
                ]);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgets,
              );
            },
          ),
        ],
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
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
