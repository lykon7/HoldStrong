import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/workout_providers.dart';
import '../../data/models/workout_entry.dart';
import 'package:intl/intl.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workoutStatsProvider);
    final entriesAsync = ref.watch(workoutEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            statsAsync.when(
              data: (stats) => _buildStatsRow(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading stats: $err'),
            ),
            const SizedBox(height: 32),
            _buildMonthHeader(),
            const SizedBox(height: 16),
            entriesAsync.when(
              data: (entries) => _buildCalendarGrid(context, ref, entries),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading calendar: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(WorkoutStats stats) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Streak', '${stats.streak} Days', Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('This Month', '${stats.monthlyTotal}', Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('All-Time', '${stats.allTimeTotal}', Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    final now = DateTime.now();
    return Text(
      DateFormat('MMMM yyyy').format(now),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, WidgetRef ref, List<WorkoutEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // DateTime.weekday returns 1 for Monday, 7 for Sunday.
    // We want Monday = 0, Sunday = 6 for our grid padding if Monday is start.
    final firstWeekday = firstDay.weekday; 
    final emptyCells = firstWeekday - 1; // Start on Monday

    final entryDates = entries.map((e) => e.date).toSet();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: emptyCells + daysInMonth,
          itemBuilder: (context, index) {
            if (index < emptyCells) {
              return const SizedBox.shrink();
            }
            final day = index - emptyCells + 1;
            final date = DateTime(now.year, now.month, day);
            final isFuture = date.isAfter(today);
            final isWorkoutDay = entryDates.contains(date);

            Color bgColor;
            if (isWorkoutDay) {
              bgColor = Colors.green;
            } else if (isFuture) {
              bgColor = Colors.grey.withOpacity(0.1);
            } else {
              // Past day without a workout, or today without a workout
              bgColor = Colors.red.withOpacity(0.8);
            }

            return InkWell(
              onTap: isFuture
                  ? null
                  : () {
                      ref.read(workoutControllerProvider.notifier).toggleWorkout(date);
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isFuture ? null : Border.all(color: Colors.black26),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isFuture ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
