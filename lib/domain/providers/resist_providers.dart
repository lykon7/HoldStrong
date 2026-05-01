import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/resist_entry.dart';
import 'goal_providers.dart';

final recentEntriesProvider = FutureProvider<List<ResistEntry>>((ref) async {
  return ref.watch(resistRepositoryProvider).getRecentEntries(limit: 3);
});

final allEntriesProvider = StreamProvider<List<ResistEntry>>((ref) {
  return ref.watch(resistRepositoryProvider).watchAllEntries();
});

/// Streak for the active goal (consecutive days with at least one entry).
final streakProvider = FutureProvider<int>((ref) async {
  final activeGoal = await ref.watch(activeGoalProvider.future);
  if (activeGoal == null) return 0;
  final entries = await ref
      .watch(resistRepositoryProvider)
      .getAllEntriesForGoal(activeGoal.uuid);
  return _calculateStreak(entries);
});

/// Total saved for the active goal.
final totalSavedForActiveGoalProvider = FutureProvider<double>((ref) async {
  final activeGoal = await ref.watch(activeGoalProvider.future);
  if (activeGoal == null) return 0.0;
  return ref
      .watch(resistRepositoryProvider)
      .getTotalSavedForGoal(activeGoal.uuid);
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
