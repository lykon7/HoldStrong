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
    final log = ref.watch(periodLogProvider);
    final status = PeriodStatus.of(log, DateTime.now());
    // Offer a quick "end" while a period is under way and has no end date.
    final openStart = status.phase == PeriodPhase.onPeriod &&
            log.endOf(status.lastStart!) == null
        ? status.lastStart
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Period Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(status: status),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pickStartDate(context, ref),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text('MARK START'),
                ),
              ),
              if (openStart != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _pickEndDate(context, ref, openStart),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('END PERIOD'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _MonthCalendar(log: log, status: status),
          const SizedBox(height: 12),
          const _Legend(),
          const SizedBox(height: 24),
          _History(log: log),
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
    await ref.read(periodLogProvider.notifier).addStart(picked);
  }
}

/// The last day an end date may be set to for the period that began on
/// [start]: not in the future, not absurdly long, not into the next period.
DateTime _latestEnd(PeriodLog log, DateTime start) {
  var latest = dateOnly(DateTime.now());
  final capped = addDays(start, kMaxPeriodLengthDays - 1);
  if (capped.isBefore(latest)) latest = capped;
  final next = log.nextStartAfter(start);
  if (next != null && !next.isAfter(latest)) latest = addDays(next, -1);
  return latest;
}

/// Asks for the last day of the period that began on [start].
Future<void> _pickEndDate(
    BuildContext context, WidgetRef ref, DateTime start) async {
  final log = ref.read(periodLogProvider);
  final last = _latestEnd(log, start);
  var initial = log.endOf(start) ?? dateOnly(DateTime.now());
  if (initial.isAfter(last)) initial = last;
  if (initial.isBefore(start)) initial = start;
  final picked = await showDatePicker(
    context: context,
    helpText: 'LAST DAY OF PERIOD',
    initialDate: initial,
    firstDate: start,
    lastDate: last,
  );
  if (picked != null) {
    await ref.read(periodLogProvider.notifier).setEnd(start, picked);
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
        headline = 'DAY ${status.dayOfPeriod} OF ${status.periodLength}';
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

enum _DayAction { addStart, removeStart, setEnd, clearEnd }

class _MonthCalendar extends ConsumerStatefulWidget {
  const _MonthCalendar({required this.log, required this.status});

  final PeriodLog log;
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
    final notifier = ref.read(periodLogProvider.notifier);
    final log = widget.log;
    final isStart = log.starts.contains(day);
    final fmt = DateFormat('EEE, MMM d');

    // The period this day belongs to (the latest one that began on or before).
    final owner = log.latestStartOnOrBefore(day);
    final ownerEnd = owner == null ? null : log.endOf(owner);
    final canEnd = owner != null &&
        owner != day &&
        ownerEnd != day &&
        !day.isAfter(_latestEnd(log, owner));
    final canClearEnd = ownerEnd != null && (ownerEnd == day || isStart);

    final action = await showDialog<_DayAction>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.backgroundElevated,
        title: Text(fmt.format(day)),
        children: [
          if (isStart)
            _option(ctx, 'Remove this period', _DayAction.removeStart,
                color: AppColors.destructive)
          else
            _option(ctx, 'Mark as first day of a period', _DayAction.addStart,
                color: _periodColor),
          if (canEnd)
            _option(
                ctx,
                'Mark as last day of the period that began '
                '${DateFormat('MMM d').format(owner)}',
                _DayAction.setEnd),
          if (canClearEnd)
            _option(ctx, 'Clear the end date', _DayAction.clearEnd),
        ],
      ),
    );

    switch (action) {
      case _DayAction.addStart:
        await notifier.addStart(day);
      case _DayAction.removeStart:
        await notifier.removeStart(day);
      case _DayAction.setEnd:
        await notifier.setEnd(owner!, day);
      case _DayAction.clearEnd:
        await notifier.clearEnd(owner!);
      case null:
        break;
    }
  }

  Widget _option(BuildContext ctx, String text, _DayAction action,
      {Color? color}) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(ctx, action),
      child: Text(text, style: TextStyle(color: color)),
    );
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
                  isStart: widget.log.starts.contains(day),
                  isPeriod: isPeriodDay(widget.log, day),
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
  const _History({required this.log});

  final PeriodLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starts = log.starts; // newest first
    if (starts.isEmpty) return const SizedBox.shrink();
    final fmt = DateFormat('EEE, MMM d, yyyy');
    final short = DateFormat('EEE, MMM d');
    final notifier = ref.read(periodLogProvider.notifier);

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
          Builder(builder: (context) {
            final start = starts[i];
            final end = log.endOf(start);
            final length = _plural(log.lengthOf(start), 'day');
            final lines = [
              end != null
                  ? 'Ended ${short.format(end)} · $length'
                  : 'No end date · assumed $length',
              // Gap to the previous (older) start = that cycle's real length.
              if (i + 1 < starts.length)
                '${_plural(daysBetween(starts[i + 1], start), 'day')} '
                    'after the previous start',
            ];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(fmt.format(start)),
              subtitle: Text(
                lines.join('\n'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              isThreeLine: lines.length > 1,
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary),
                onSelected: (v) {
                  switch (v) {
                    case 'end':
                      _pickEndDate(context, ref, start);
                    case 'clear':
                      notifier.clearEnd(start);
                    case 'delete':
                      notifier.removeStart(start);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'end',
                    child: Text(end == null ? 'Set end date' : 'Change end date'),
                  ),
                  if (end != null)
                    const PopupMenuItem(
                        value: 'clear', child: Text('Clear end date')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            );
          }),
      ],
    );
  }
}
