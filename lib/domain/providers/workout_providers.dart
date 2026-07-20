import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/workout_entry.dart';
import 'goal_providers.dart'; // To access isarProvider

final workoutEntriesProvider = StreamProvider<List<WorkoutEntry>>((ref) {
  final isar = ref.watch(isarProvider);
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

  return isar.workoutEntrys
      .where()
      .dateBetween(firstDayOfMonth, lastDayOfMonth)
      .watch(fireImmediately: true);
});

final workoutStatsProvider = Provider<AsyncValue<WorkoutStats>>((ref) {
  final isar = ref.watch(isarProvider);
  // Re-evaluate when entries change
  ref.watch(workoutEntriesProvider);

  try {
    final allEntries = isar.workoutEntrys.where().sortByDateDesc().findAllSync();
    
    int streak = 0;
    int allTimeTotal = allEntries.length;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    int monthlyTotal = 0;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    for (var entry in allEntries) {
      if (!entry.date.isBefore(firstDayOfMonth) && !entry.date.isAfter(lastDayOfMonth)) {
        monthlyTotal++;
      }
    }

    // Calculate Streak
    if (allEntries.isNotEmpty) {
      final entryDates = allEntries.map((e) => e.date).toSet();
      
      DateTime currentCheckDate = today;
      if (entryDates.contains(today)) {
        streak++;
        currentCheckDate = yesterday;
      } else if (entryDates.contains(yesterday)) {
        streak++;
        currentCheckDate = yesterday.subtract(const Duration(days: 1));
      }

      if (streak > 0) {
        while (entryDates.contains(currentCheckDate)) {
          streak++;
          currentCheckDate = currentCheckDate.subtract(const Duration(days: 1));
        }
      }
    }

    return AsyncData(WorkoutStats(
      streak: streak,
      monthlyTotal: monthlyTotal,
      allTimeTotal: allTimeTotal,
    ));
  } catch (e, st) {
    return AsyncError(e, st);
  }
});

class WorkoutStats {
  final int streak;
  final int monthlyTotal;
  final int allTimeTotal;

  WorkoutStats({
    required this.streak,
    required this.monthlyTotal,
    required this.allTimeTotal,
  });
}

class WorkoutNotifier extends StateNotifier<AsyncValue<void>> {
  final Isar _isar;

  WorkoutNotifier(this._isar) : super(const AsyncData(null));

  Future<void> toggleWorkout(DateTime date, {double? weight}) async {
    state = const AsyncLoading();
    try {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      await _isar.writeTxn(() async {
        final existing = await _isar.workoutEntrys.where().dateEqualTo(normalizedDate).findFirst();
        if (existing != null) {
          await _isar.workoutEntrys.delete(existing.id);
        } else {
          final entry = WorkoutEntry()
            ..date = normalizedDate
            ..recordedAt = DateTime.now()
            ..weight = weight;
          await _isar.workoutEntrys.put(entry);
        }
      });
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final workoutControllerProvider = StateNotifierProvider<WorkoutNotifier, AsyncValue<void>>((ref) {
  final isar = ref.watch(isarProvider);
  return WorkoutNotifier(isar);
});

// Provides weight history sorted by date
final weightHistoryProvider = Provider.family<List<WorkoutEntry>, int>((ref, months) {
  final isar = ref.watch(isarProvider);
  // Re-evaluate when entries change
  ref.watch(workoutEntriesProvider);

  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - months, now.day);
  
  final entries = isar.workoutEntrys
      .where()
      .dateGreaterThan(startDate)
      .sortByDate()
      .findAllSync();

  return entries.where((e) => e.weight != null).toList();
});
