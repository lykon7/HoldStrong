import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/providers/goal_providers.dart';
import '../../data/models/goal.dart';
import 'widgets/goal_card.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('GOALS')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goals/new'),
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.backgroundPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentGold)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Text(
                'NO GOALS YET.\nCREATE ONE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final active = goals.where((g) => g.isActive).toList();
          final inactive = goals.where((g) => !g.isActive && !g.isCompleted).toList();
          final completed = goals.where((g) => g.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader('ACTIVE'),
                const SizedBox(height: 8),
                ...active.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GoalCard(goal: g, isHighlighted: true),
                )),
                const SizedBox(height: 16),
              ],
              if (inactive.isNotEmpty) ...[
                _SectionHeader('INACTIVE'),
                const SizedBox(height: 8),
                ...inactive.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GoalCard(goal: g, isHighlighted: false),
                )),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader('COMPLETED'),
                const SizedBox(height: 8),
                ...completed.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GoalCard(goal: g, isHighlighted: false),
                )),
              ],
            ],
          );
        },
      ),
    );
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
