import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../data/models/expense_entry.dart';
import '../../../data/models/income_entry.dart';

const _kIncomeGreen = Color(0xFF3DAA6E);
const _kExpenseRed = AppColors.destructive;

class NetWeekGraph extends StatefulWidget {
  const NetWeekGraph({
    super.key,
    required this.incomes,
    required this.expenses,
    this.weeksToShow = 12,
  });

  final AsyncValue<List<IncomeEntry>> incomes;
  final AsyncValue<List<ExpenseEntry>> expenses;
  final int weeksToShow;

  @override
  State<NetWeekGraph> createState() => _NetWeekGraphState();
}

class _NetWeekGraphState extends State<NetWeekGraph> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.incomes.when(
      loading: () => const _GraphShell(child: _GraphLoading()),
      error: (e, _) => _GraphShell(child: _GraphError(error: e.toString())),
      data: (incomeEntries) => widget.expenses.when(
        loading: () => const _GraphShell(child: _GraphLoading()),
        error: (e, _) => _GraphShell(child: _GraphError(error: e.toString())),
        data: (expenseEntries) {
          final incomeTotals = _totalsByDay(incomeEntries);
          final expenseTotals = _totalsByDay(expenseEntries);

          return SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.weeksToShow,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final now = DateTime.now();
                final start = _startOfWeek(now)
                    .subtract(Duration(days: 7 * index));
                final end = start.add(const Duration(days: 6));

                final days = List.generate(
                  7,
                  (i) => start.add(Duration(days: i)),
                );
                final values = days
                    .map((d) => (incomeTotals[_dayKey(d)] ?? 0) -
                        (expenseTotals[_dayKey(d)] ?? 0))
                    .toList();

                return _WeekCard(
                  index: index,
                  weekStart: start,
                  weekEnd: end,
                  values: values,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Map<DateTime, double> _totalsByDay(List<dynamic> entries) {
    final totals = <DateTime, double>{};
    for (final entry in entries) {
      final loggedAt = entry is IncomeEntry
          ? entry.loggedAt
          : (entry as ExpenseEntry).loggedAt;
      final amount = entry is IncomeEntry
          ? entry.amount
          : (entry as ExpenseEntry).amount;
      final day = _dayKey(loggedAt);
      totals[day] = (totals[day] ?? 0) + amount;
    }
    return totals;
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  DateTime _dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.index,
    required this.weekStart,
    required this.weekEnd,
    required this.values,
  });

  final int index;
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final rangeFmt = DateFormat('d MMM');
    final label = index == 0
        ? 'THIS WEEK'
        : '${rangeFmt.format(weekStart)} - ${rangeFmt.format(weekEnd)}'
            .toUpperCase();
    final total = values.fold<double>(0.0, (s, v) => s + v);
    final totalColor = total >= 0 ? _kIncomeGreen : _kExpenseRed;
    final totalPrefix = total >= 0 ? '+Rs ' : '-Rs ';
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final dayFmt = DateFormat('EEE');

    final maxAbs = values.isEmpty
        ? 1.0
        : values.map((v) => v.abs()).fold<double>(0.0, math.max);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                'NET $totalPrefix${fmt.format(total.abs())}',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: totalColor,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: _NetLinePainter(values: values, maxAbs: maxAbs),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: values.asMap().entries.map((entry) {
              final day = weekStart.add(Duration(days: entry.key));
              return Text(
                dayFmt.format(day).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NetLinePainter extends CustomPainter {
  _NetLinePainter({required this.values, required this.maxAbs});

  final List<double> values;
  final double maxAbs;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height / 2;
    final usableHeight = baseline - 6;
    final linePaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      linePaint,
    );

    if (values.isEmpty) return;

    final safeMax = maxAbs == 0 ? 1.0 : maxAbs;
    final step = values.length == 1 ? 0.0 : size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final normalized = value / safeMax;
      final y = baseline - (normalized * usableHeight);
      final x = step * i;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final strokePaint = Paint()
      ..color = AppColors.accentBlue.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final normalized = value / safeMax;
      final y = baseline - (normalized * usableHeight);
      final x = step * i;
      final dotPaint = Paint()
        ..color = value >= 0 ? _kIncomeGreen : _kExpenseRed
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 3.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetLinePainter oldDelegate) {
    return true;
  }
}

class _GraphShell extends StatelessWidget {
  const _GraphShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: child,
    );
  }
}

class _GraphLoading extends StatelessWidget {
  const _GraphLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentGold),
    );
  }
}

class _GraphError extends StatelessWidget {
  const _GraphError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error: $error',
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
