import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resist_entry.dart';
import 'goal_providers.dart';

final recentEntriesProvider = StreamProvider<List<ResistEntry>>((ref) {
  return ref.watch(resistRepositoryProvider).watchRecentEntries(limit: 3);
});

final allEntriesProvider = StreamProvider<List<ResistEntry>>((ref) {
  return ref.watch(resistRepositoryProvider).watchAllEntries();
});

/// Streak for the active goal (consecutive days with at least one entry).
/// Uses a StreamProvider so it reacts to every new resist entry.
final streakProvider = StreamProvider<int>((ref) async* {
  final activeGoal = await ref.watch(activeGoalProvider.future);
  if (activeGoal == null) {
    yield 0;
    return;
  }
  yield* ref
      .watch(resistRepositoryProvider)
      .watchEntriesForGoal(activeGoal.uuid)
      .map(_calculateStreak);
});

/// Total saved for the active goal.
/// Uses a StreamProvider so the progress card updates in real-time.
final totalSavedForActiveGoalProvider = StreamProvider<double>((ref) async* {
  final activeGoal = await ref.watch(activeGoalProvider.future);
  if (activeGoal == null) {
    yield 0.0;
    return;
  }
  yield* ref
      .watch(resistRepositoryProvider)
      .watchEntriesForGoal(activeGoal.uuid)
      .map((entries) => entries.fold<double>(0.0, (sum, e) => sum + e.amountLkr));
});

int _calculateStreak(List<ResistEntry> entries) {
  if (entries.isEmpty) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = entries
      .map((e) => DateTime(e.loggedAt.year, e.loggedAt.month, e.loggedAt.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  if (days.isEmpty) return 0;
  final diff = today.difference(days.first).inDays;
  if (diff > 1) return 0;
  int streak = 1;
  for (int i = 0; i < days.length - 1; i++) {
    if (days[i].difference(days[i + 1]).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
