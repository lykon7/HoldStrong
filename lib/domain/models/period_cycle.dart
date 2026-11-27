/// Period tracker maths. Pure Dart so it is easy to test.
///
/// Only period *start* dates are stored. Everything else (the 5 period days,
/// the countdown to the next one) is derived from the latest start.
library;

/// A period typically lasts this many days (the start day is day 1).
const kPeriodLengthDays = 5;

/// Start of one period to the start of the next. This is a rough estimate.
const kCycleLengthDays = 28;

/// The next period can realistically come this many days early or late.
const kCycleVarianceDays = 2;

/// Strips the time so two timestamps on the same day compare equal.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [a] to [b] (negative if [b] is earlier). Immune
/// to daylight-saving shifts, unlike `b.difference(a).inDays`.
int daysBetween(DateTime a, DateTime b) {
  return DateTime.utc(b.year, b.month, b.day)
      .difference(DateTime.utc(a.year, a.month, a.day))
      .inDays;
}

DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

enum PeriodPhase {
  /// Nothing logged yet.
  noData,

  /// Inside the 5 period days.
  onPeriod,

  /// Period is over and the next one isn't due for a while.
  countdown,

  /// Inside the "could be any day now" window around the expected date.
  expectedSoon,

  /// Past the end of the window.
  overdue,
}

class PeriodStatus {
  const PeriodStatus._({
    required this.phase,
    this.lastStart,
    this.dayOfPeriod,
    this.expectedStart,
    this.daysUntilExpected,
  });

  const PeriodStatus.noData() : this._(phase: PeriodPhase.noData);

  final PeriodPhase phase;

  /// First day of the most recent period.
  final DateTime? lastStart;

  /// 1-based day within the period; only set while [phase] is `onPeriod`.
  final int? dayOfPeriod;

  /// Best guess for the next start (last start + cycle length).
  final DateTime? expectedStart;

  /// Days from today to [expectedStart]; negative once it has passed.
  final int? daysUntilExpected;

  DateTime? get windowStart => expectedStart == null
      ? null
      : addDays(expectedStart!, -kCycleVarianceDays);

  DateTime? get windowEnd => expectedStart == null
      ? null
      : addDays(expectedStart!, kCycleVarianceDays);

  /// Days remaining in the current period, including today.
  int? get periodDaysLeft =>
      dayOfPeriod == null ? null : kPeriodLengthDays - dayOfPeriod! + 1;

  /// Days past the end of the expected window; only meaningful when overdue.
  int get daysLate => phase == PeriodPhase.overdue
      ? -daysUntilExpected! - kCycleVarianceDays
      : 0;

  /// Works out where [today] sits relative to the latest start on or before
  /// it. Starts in the future are ignored.
  static PeriodStatus of(Iterable<DateTime> starts, DateTime today) {
    final t = dateOnly(today);
    DateTime? last;
    for (final s in starts) {
      final d = dateOnly(s);
      if (d.isAfter(t)) continue;
      if (last == null || d.isAfter(last)) last = d;
    }
    if (last == null) return const PeriodStatus.noData();

    final expected = addDays(last, kCycleLengthDays);
    final until = daysBetween(t, expected);
    final sinceStart = daysBetween(last, t); // 0 on the start day

    final PeriodPhase phase;
    if (sinceStart < kPeriodLengthDays) {
      phase = PeriodPhase.onPeriod;
    } else if (until > kCycleVarianceDays) {
      phase = PeriodPhase.countdown;
    } else if (until >= -kCycleVarianceDays) {
      phase = PeriodPhase.expectedSoon;
    } else {
      phase = PeriodPhase.overdue;
    }

    return PeriodStatus._(
      phase: phase,
      lastStart: last,
      dayOfPeriod: phase == PeriodPhase.onPeriod ? sinceStart + 1 : null,
      expectedStart: expected,
      daysUntilExpected: until,
    );
  }
}

/// Whether [day] falls inside one of the 5-day periods that began on [starts].
bool isPeriodDay(Iterable<DateTime> starts, DateTime day) {
  final d = dateOnly(day);
  for (final s in starts) {
    final offset = daysBetween(dateOnly(s), d);
    if (offset >= 0 && offset < kPeriodLengthDays) return true;
  }
  return false;
}

/// Whether [day] is in the predicted window for the next period.
bool isPredictedDay(PeriodStatus status, DateTime day) {
  final from = status.windowStart;
  final to = status.windowEnd;
  if (from == null || to == null) return false;
  final d = dateOnly(day);
  return !d.isBefore(from) && !d.isAfter(to);
}
