import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../domain/providers/workout_providers.dart';
import '../../data/models/workout_entry.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
            const SizedBox(height: 32),
            const _WeightGraphSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _promptForWeight(BuildContext context, WidgetRef ref, DateTime date) async {
    final ctrl = TextEditingController();
    final weightStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('LOG WEIGHT',
            style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1,
                color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 14,
              color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Weight in kg...',
            isDense: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('SAVE',
                  style: TextStyle(color: AppColors.accentGold))),
        ],
      ),
    );
    if (weightStr != null) {
      final weight = double.tryParse(weightStr.trim());
      ref.read(workoutControllerProvider.notifier).toggleWorkout(date, weight: weight);
    }
  }

  Future<void> _promptForUntoggle(BuildContext context, WidgetRef ref, WorkoutEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('WORKOUT DETAILS',
            style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1,
                color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.weight != null) ...[
              Text('Weight logged: ${entry.weight} kg',
                  style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
            ],
            const Text('Are you sure you want to remove this workout? This will delete the entry and weight data for this day. This cannot be undone.',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 12,
                    color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('REMOVE',
                  style: TextStyle(color: AppColors.destructive))),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(workoutControllerProvider.notifier).toggleWorkout(entry.date);
    }
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

    final entryMap = {for (var e in entries) e.date: e};

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
            final entry = entryMap[date];
            final isWorkoutDay = entry != null;

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
                      if (isWorkoutDay) {
                        _promptForUntoggle(context, ref, entry!);
                      } else {
                        _promptForWeight(context, ref, date);
                      }
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

class _WeightGraphSection extends ConsumerStatefulWidget {
  const _WeightGraphSection();

  @override
  ConsumerState<_WeightGraphSection> createState() => _WeightGraphSectionState();
}

class _WeightGraphSectionState extends ConsumerState<_WeightGraphSection> {
  int _months = 1;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(weightHistoryProvider(_months));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BODY WEIGHT',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppColors.textSecondary)),
            Wrap(
              spacing: 8,
              children: [1, 3, 6, 12].map((m) {
                final isSel = _months == m;
                return GestureDetector(
                  onTap: () => setState(() => _months = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.accentGold.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                          color: isSel ? AppColors.accentGold : AppColors.cardBorder),
                    ),
                    child: Text(m == 12 ? '1Y' : '${m}M',
                        style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            color: isSel ? AppColors.accentGold : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: history.isEmpty
              ? const Center(
                  child: Text('No weight data in this period.',
                      style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 11,
                          color: AppColors.textSecondary)))
              : CustomPaint(
                  painter: _WeightLinePainter(entries: history),
                ),
        ),
      ],
    );
  }
}

class _WeightLinePainter extends CustomPainter {
  _WeightLinePainter({required this.entries});
  final List<WorkoutEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final maxW = entries.map((e) => e.weight!).reduce(math.max);
    final minW = entries.map((e) => e.weight!).reduce(math.min);
    
    final range = maxW == minW ? 10.0 : maxW - minW;
    final top = maxW + (range * 0.2);
    final bottom = math.max(0.0, minW - (range * 0.2));
    final yRange = top - bottom;

    final tMin = entries.first.date.millisecondsSinceEpoch;
    final tMax = entries.last.date.millisecondsSinceEpoch;
    final tRange = tMax == tMin ? 1 : tMax - tMin;

    final path = Path();
    var first = true;
    final points = <Offset>[];

    var prevX = 0.0;
    var prevY = 0.0;

    for (final e in entries) {
      final x = tRange == 0 
          ? size.width / 2 
          : ((e.date.millisecondsSinceEpoch - tMin) / tRange) * size.width;
      final y = size.height - (((e.weight! - bottom) / yRange) * size.height);
      points.add(Offset(x, y));
      
      if (first) {
        path.moveTo(x, y);
        prevX = x;
        prevY = y;
        first = false;
      } else {
        final controlX = (prevX + x) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
        prevX = x;
        prevY = y;
      }
    }

    // Draw grid lines and labels
    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
      
    final textStyle = const TextStyle(
      color: AppColors.textSecondary,
      fontFamily: 'IBMPlexMono',
      fontSize: 9,
    );

    void drawGridLine(double y, double weightValue, bool textBelow) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      
      final textSpan = TextSpan(text: '${weightValue.toStringAsFixed(1)} kg', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final yOffset = textBelow ? y + 2 : y - textPainter.height - 2;
      textPainter.paint(canvas, Offset(4, yOffset));
    }

    drawGridLine(0, top, true);
    drawGridLine(size.height / 2, bottom + (yRange / 2), false);
    drawGridLine(size.height, bottom, false);

    final fillRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accentGold.withOpacity(0.5),
          AppColors.accentGold.withOpacity(0.0),
        ],
      ).createShader(fillRect);
      
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
      
    canvas.drawPath(path, strokePaint);

    for (final p in points) {
      final dotPaint = Paint()
        ..color = AppColors.accentGold
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 3.5, dotPaint);
      
      final innerDot = Paint()
        ..color = AppColors.backgroundElevated
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 1.5, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLinePainter old) => true;
}
