import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme.dart';
import '../../domain/models/period_cycle.dart';
import '../../domain/providers/period_providers.dart';

const _periodColor = Color(0xFFE5566D);
const _predictedColor = Color(0xFFF0C040);

/// "1 day" / "3 days"; an uppercase [unit] gets an uppercase "S".
String _plural(int n, String unit) {
  if (n == 1) return '$n $unit';
  return '$n $unit${unit == unit.toUpperCase() ? 'S' : 's'}';
}

class PeriodScreen extends ConsumerWidget {
  const PeriodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starts = ref.watch(periodStartsProvider);
    final status = PeriodStatus.of(starts, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Period Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(status: status),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _pickStartDate(context, ref),
            icon: const Icon(Icons.water_drop_outlined),
            label: const Text('MARK PERIOD STARTED'),
          ),
          const SizedBox(height: 24),
          _MonthCalendar(starts: starts, status: status),
          const SizedBox(height: 12),
          const _Legend(),
          const SizedBox(height: 24),
          _History(starts: starts),
        ],
      ),
    );
  }
}

Future<void> _pickStartDate(BuildContext context, WidgetRef ref) async {
  final today = dateOnly(DateTime.now());
  final picked = await showDatePicker(
    context: context,
    helpText: 'FIRST DAY OF PERIOD',
    initialDate: today,
    firstDate: DateTime(today.year - 2),
    lastDate: today,
  );
  if (picked != null) {
    await ref.read(periodStartsProvider.notifier).addStart(picked);
  }
}

// ─── Status ──────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final PeriodStatus status;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, MMM d');
    final expected = status.expectedStart;
    final approx = expected == null
        ? ''
        : 'Expected around ${fmt.format(expected)}, give or take '
            '${_plural(kCycleVarianceDays, 'day')}.';

    final String headline;
    final String detail;
    Color color = _periodColor;

    switch (status.phase) {
      case PeriodPhase.noData:
        headline = 'NO DATA YET';
        detail = 'Mark the first day of her last period to start tracking.';
        color = AppColors.textSecondary;
      case PeriodPhase.onPeriod:
        final left = status.periodDaysLeft!;
        headline = 'DAY ${status.dayOfPeriod} OF $kPeriodLengthDays';
        detail = '${left == 1 ? 'Last day' : '$left days left'} '
            '(including today).\nNext period: ${fmt.format(expected!)} (est.)';
      case PeriodPhase.countdown:
        headline = '~${_plural(status.daysUntilExpected!, 'DAY')}';
        detail = 'Until the next period (estimate).\n$approx';
        color = _predictedColor;
      case PeriodPhase.expectedSoon:
        final until = status.daysUntilExpected!;
        headline = until == 0 ? 'EXPECTED TODAY' : 'ANY DAY NOW';
        detail = approx;
        color = _predictedColor;
      case PeriodPhase.overdue:
        headline = '${_plural(status.daysLate, 'DAY')} LATE';
        detail = approx;
        color = AppColors.destructive;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar ────────────────────────────────────────────────────────────────

class _MonthCalendar extends ConsumerStatefulWidget {
  const _MonthCalendar({required this.starts, required this.status});

  final List<DateTime> starts;
  final PeriodStatus status;

  @override
  ConsumerState<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends ConsumerState<_MonthCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  Future<void> _onDayTap(DateTime day) async {
    final today = dateOnly(DateTime.now());
    if (day.isAfter(today)) return;
    final notifier = ref.read(periodStartsProvider.notifier);
    final isStart = widget.starts.contains(day);
    final label = DateFormat('EEE, MMM d').format(day);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        title: Text(label),
        content: Text(isStart
            ? 'This day is marked as the start of a period.'
            : 'Mark this day as the first day of a period?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isStart ? 'REMOVE' : 'MARK AS START',
              style: TextStyle(
                  color: isStart ? AppColors.destructive : _periodColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (isStart) {
      await notifier.removeStart(day);
    } else {
      await notifier.addStart(day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final first = _month;
    // Monday-first grid.
    final leading = (first.weekday + 6) % 7;
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shift(-1),
            ),
            Text(
              DateFormat('MMMM yyyy').format(first).toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shift(1),
            ),
          ],
        ),
        Row(
          children: [
            for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (var i = 0; i < cellCount; i++)
              Builder(builder: (_) {
                final n = i - leading + 1;
                if (n < 1 || n > daysInMonth) return const SizedBox.shrink();
                final day = DateTime(first.year, first.month, n);
                return _DayCell(
                  day: day,
                  isToday: day == today,
                  isFuture: day.isAfter(today),
                  isStart: widget.starts.contains(day),
                  isPeriod: isPeriodDay(widget.starts, day),
                  isPredicted: isPredictedDay(widget.status, day),
                  onTap: () => _onDayTap(day),
                );
              }),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.isStart,
    required this.isPeriod,
    required this.isPredicted,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isFuture;
  final bool isStart;
  final bool isPeriod;
  final bool isPredicted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? fill;
    Color? border;
    if (isPeriod) {
      fill = _periodColor.withOpacity(isStart ? 0.9 : 0.5);
    } else if (isPredicted) {
      fill = _predictedColor.withOpacity(0.15);
      border = _predictedColor.withOpacity(0.6);
    }
    if (isToday) border = AppColors.textPrimary;

    return InkWell(
      onTap: isFuture ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isStart ? FontWeight.w700 : FontWeight.w400,
            color: isFuture && !isPredicted
                ? AppColors.textSecondary.withOpacity(0.5)
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String text, {bool outline = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: outline ? color.withOpacity(0.15) : color,
                border: outline ? Border.all(color: color) : null,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(_periodColor, 'Period'),
        item(_predictedColor, 'Expected window', outline: true),
      ],
    );
  }
}

// ─── History ─────────────────────────────────────────────────────────────────

class _History extends ConsumerWidget {
  const _History({required this.starts});

  /// Newest first.
  final List<DateTime> starts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (starts.isEmpty) return const SizedBox.shrink();
    final fmt = DateFormat('EEE, MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HISTORY',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < starts.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(fmt.format(starts[i])),
            // Gap to the previous (older) start = that cycle's real length.
            subtitle: i + 1 < starts.length
                ? Text(
                    '${_plural(daysBetween(starts[i + 1], starts[i]), 'day')} '
                    'after the previous start',
                    style: const TextStyle(color: AppColors.textSecondary),
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.textSecondary,
              onPressed: () => ref
                  .read(periodStartsProvider.notifier)
                  .removeStart(starts[i]),
            ),
          ),
      ],
    );
  }
}
