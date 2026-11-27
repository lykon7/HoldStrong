/// Period tracker maths. Pure Dart so it is easy to test.
///
/// A period is stored as its *start* date plus an optional *end* date (the
/// last day of bleeding). Without an end date it is assumed to last
/// [kPeriodLengthDays]. The countdown to the next period always runs from the
/// latest start.
library;

/// A period typically lasts this many days (the start day is day 1).
const kPeriodLengthDays = 5;

/// The longest period the app will accept when setting an end date.
const kMaxPeriodLengthDays = 14;

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

/// Every logged period: start dates (newest first) and optional end dates.
/// Immutable; the `with…` methods return a modified copy.
class PeriodLog {
  PeriodLog({
    Iterable<DateTime> starts = const [],
    Map<DateTime, DateTime> ends = const {},
  })  : starts = (starts.map(dateOnly).toSet().toList()
          ..sort((a, b) => b.compareTo(a))),
        _ends = {
          for (final e in ends.entries) dateOnly(e.key): dateOnly(e.value),
        };

  /// First day of each period, newest first.
  final List<DateTime> starts;

  /// Raw end dates keyed by start. Prefer [endOf], which sanity-checks them.
  final Map<DateTime, DateTime> _ends;

  bool get isEmpty => starts.isEmpty;

  /// Raw stored ends, for persisting.
  Map<DateTime, DateTime> get storedEnds => Map.unmodifiable(_ends);

  /// The earliest start strictly after [start], if any.
  DateTime? nextStartAfter(DateTime start) {
    DateTime? next;
    for (final s in starts) {
      if (s.isAfter(start) && (next == null || s.isBefore(next))) next = s;
    }
    return next;
  }

  /// Last day of the period that began on [start], or null if none was set.
  /// Ignored if it precedes the start, and cut short so it never runs into
  /// the next period.
  DateTime? endOf(DateTime start) {
    final s = dateOnly(start);
    final e = _ends[s];
    if (e == null || e.isBefore(s)) return null;
    final next = nextStartAfter(s);
    if (next != null && !e.isBefore(next)) return addDays(next, -1);
    return e;
  }

  /// Days the period starting on [start] lasted (or is assumed to last).
  int lengthOf(DateTime start) {
    final s = dateOnly(start);
    final e = endOf(s);
    if (e != null) return daysBetween(s, e) + 1;
    final next = nextStartAfter(s);
    if (next == null) return kPeriodLengthDays;
    final gap = daysBetween(s, next);
    return gap < kPeriodLengthDays ? gap : kPeriodLengthDays;
  }

  /// The latest start on or before [day], if any.
  DateTime? latestStartOnOrBefore(DateTime day) {
    final d = dateOnly(day);
    for (final s in starts) {
      if (!s.isAfter(d)) return s; // starts are newest first
    }
    return null;
  }

  PeriodLog withStart(DateTime day) =>
      PeriodLog(starts: [...starts, day], ends: _ends);

  /// Removes a period, and its end date with it.
  PeriodLog withoutStart(DateTime day) {
    final d = dateOnly(day);
    return PeriodLog(
      starts: starts.where((s) => s != d),
      ends: {
        for (final e in _ends.entries)
          if (e.key != d) e.key: e.value,
      },
    );
  }

  /// Sets the last day of the period that began on [start]. Ignored if there
  /// is no such period or [end] is before it.
  PeriodLog withEnd(DateTime start, DateTime end) {
    final s = dateOnly(start);
    final e = dateOnly(end);
    if (!starts.contains(s) || e.isBefore(s)) return this;
    return PeriodLog(starts: starts, ends: {..._ends, s: e});
  }

  PeriodLog withoutEnd(DateTime start) {
    final s = dateOnly(start);
    return PeriodLog(
      starts: starts,
      ends: {
        for (final e in _ends.entries)
          if (e.key != s) e.key: e.value,
      },
    );
  }
}

enum PeriodPhase {
  /// Nothing logged yet.
  noData,

  /// Inside the period itself (its 5 days, or up to its end date).
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
    this.periodLength,
    this.dayOfPeriod,
    this.expectedStart,
    this.daysUntilExpected,
  });

  const PeriodStatus.noData() : this._(phase: PeriodPhase.noData);

  final PeriodPhase phase;

  /// First day of the most recent period.
  final DateTime? lastStart;

  /// How many days that period lasts (set end date, else the default).
  final int? periodLength;

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
      dayOfPeriod == null ? null : periodLength! - dayOfPeriod! + 1;

  /// Days past the end of the expected window; only meaningful when overdue.
  int get daysLate => phase == PeriodPhase.overdue
      ? -daysUntilExpected! - kCycleVarianceDays
      : 0;

  /// Works out where [today] sits relative to the latest start on or before
  /// it. Starts in the future are ignored.
  static PeriodStatus of(PeriodLog log, DateTime today) {
    final t = dateOnly(today);
    final last = log.latestStartOnOrBefore(t);
    if (last == null) return const PeriodStatus.noData();

    final length = log.lengthOf(last);
    final expected = addDays(last, kCycleLengthDays);
    final until = daysBetween(t, expected);
    final sinceStart = daysBetween(last, t); // 0 on the start day

    final PeriodPhase phase;
    if (sinceStart < length) {
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
      periodLength: length,
      dayOfPeriod: phase == PeriodPhase.onPeriod ? sinceStart + 1 : null,
      expectedStart: expected,
      daysUntilExpected: until,
    );
  }
}

/// Whether [day] falls inside a logged period.
bool isPeriodDay(PeriodLog log, DateTime day) {
  final d = dateOnly(day);
  for (final s in log.starts) {
    final offset = daysBetween(s, d);
    if (offset >= 0 && offset < log.lengthOf(s)) return true;
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
