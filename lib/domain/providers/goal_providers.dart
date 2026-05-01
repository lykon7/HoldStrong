import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/goal.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/resist_repository.dart';

/// Overridden in main() with the opened Isar instance.
final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider must be overridden in main()'),
);

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(isarProvider));
});

final resistRepositoryProvider = Provider<ResistRepository>((ref) {
  return ResistRepository(ref.watch(isarProvider));
});

final activeGoalProvider = StreamProvider<Goal?>((ref) {
  return ref.watch(goalRepositoryProvider).watchActiveGoal();
});

final allGoalsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalRepositoryProvider).watchAllGoals();
});

/// Stats for a specific goal — total saved, progress %, projected completion.
final goalStatsProvider =
    FutureProvider.family<GoalStats, String>((ref, goalUuid) async {
  final goalRepo = ref.watch(goalRepositoryProvider);
  final resistRepo = ref.watch(resistRepositoryProvider);
  final goal = await goalRepo.getGoalByUuid(goalUuid);
  if (goal == null) return const GoalStats();

  final totalSaved = await resistRepo.getTotalSavedForGoal(goalUuid);
  final allEntries = await resistRepo.getAllEntriesForGoal(goalUuid);
  final progressPct = goal.targetAmountLkr > 0
      ? (totalSaved / goal.targetAmountLkr * 100).clamp(0.0, 100.0)
      : 0.0;

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 30));
  final recent = allEntries.where((e) => e.loggedAt.isAfter(cutoff)).toList();
  final recentTotal = recent.fold<double>(0, (s, e) => s + e.amountLkr);
  final dailyAvg = recentTotal / 30;

  DateTime? projectedDate;
  if (dailyAvg > 0 && totalSaved < goal.targetAmountLkr) {
    final remaining = goal.targetAmountLkr - totalSaved;
    projectedDate = now.add(Duration(days: (remaining / dailyAvg).ceil()));
  }

  return GoalStats(
    totalSaved: totalSaved,
    progressPct: progressPct,
    projectedCompletionDate: projectedDate,
  );
});

class GoalStats {
  const GoalStats({
    this.totalSaved = 0,
    this.progressPct = 0,
    this.projectedCompletionDate,
  });

  final double totalSaved;
  final double progressPct;
  final DateTime? projectedCompletionDate;
}
