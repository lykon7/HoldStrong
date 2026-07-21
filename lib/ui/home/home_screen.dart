import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/goal_providers.dart';
import '../../domain/providers/resist_providers.dart';
import '../../domain/providers/income_providers.dart';
import '../../domain/providers/expense_providers.dart';
import 'widgets/goal_progress_card.dart';
import 'widgets/net_week_graph.dart';
import 'widgets/hub_shortcuts.dart';
import 'widgets/total_cash_card.dart';
import 'widgets/custom_timer_card.dart';
import '../../domain/providers/custom_timer_providers.dart';
import '../../core/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeGoal = ref.watch(activeGoalProvider);
    final streak = ref.watch(streakProvider);
    final totalSaved = ref.watch(totalSavedForActiveGoalProvider);
    final incomes = ref.watch(allIncomeProvider);
    final expenses = ref.watch(allExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('HOLDSTRONG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: activeGoal.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goal) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NetWeekGraph(incomes: incomes, expenses: expenses),
                const SizedBox(height: 16),
                const HubShortcuts(),
                const SizedBox(height: 16),
                const TotalCashCard(),
                const SizedBox(height: 16),
                ...ref.watch(customTimersProvider).map((t) => CustomTimerCard(timer: t)),
                goal == null
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSurface,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'NO ACTIVE GOAL.\nGO TO GOALS.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      )
                    : GoalProgressCard(
                        goal: goal,
                        totalSaved: totalSaved.value ?? 0.0,
                        streakDays: streak.value ?? 0,
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}


