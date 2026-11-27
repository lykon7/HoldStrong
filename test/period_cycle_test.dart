import 'package:flutter_test/flutter_test.dart';
import 'package:holdstrong/data/backup/backup_service.dart';
import 'package:holdstrong/domain/models/period_cycle.dart';
import 'package:holdstrong/domain/providers/period_providers.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final start = DateTime(2026, 3, 1);
  DateTime day(int n) => addDays(start, n); // n days after the start
  PeriodLog logOf(Iterable<DateTime> starts,
          [Map<DateTime, DateTime> ends = const {}]) =>
      PeriodLog(starts: starts, ends: ends);
  PeriodStatus statusOn(int n, [PeriodLog? log]) =>
      PeriodStatus.of(log ?? logOf([start]), day(n));

  group('PeriodStatus', () {
    test('no data', () {
      expect(PeriodStatus.of(PeriodLog(), DateTime(2026, 3, 1)).phase,
          PeriodPhase.noData);
    });

    test('counts the 5 period days, start day being day 1', () {
      final s0 = statusOn(0);
      expect(s0.phase, PeriodPhase.onPeriod);
      expect(s0.dayOfPeriod, 1);
      expect(s0.periodLength, 5);
      expect(s0.periodDaysLeft, 5);

      final s4 = statusOn(4);
      expect(s4.phase, PeriodPhase.onPeriod);
      expect(s4.dayOfPeriod, 5);
      expect(s4.periodDaysLeft, 1);

      expect(statusOn(5).phase, PeriodPhase.countdown);
    });

    test('counts down to start + 28, with a +/-2 day window', () {
      final s = statusOn(10);
      expect(s.phase, PeriodPhase.countdown);
      expect(s.expectedStart, day(28));
      expect(s.daysUntilExpected, 18);
      expect(s.windowStart, day(26));
      expect(s.windowEnd, day(30));

      // Day 25: still a plain countdown. Day 26: window opens.
      expect(statusOn(25).phase, PeriodPhase.countdown);
      expect(statusOn(26).phase, PeriodPhase.expectedSoon);
      expect(statusOn(28).daysUntilExpected, 0);
      expect(statusOn(30).phase, PeriodPhase.expectedSoon);
    });

    test('overdue once past the window', () {
      final s = statusOn(31);
      expect(s.phase, PeriodPhase.overdue);
      expect(s.daysLate, 1);
      expect(statusOn(40).daysLate, 10);
    });

    test('uses the latest start on or before today; ignores the future', () {
      final older = DateTime(2026, 2, 1);
      final future = DateTime(2026, 4, 1);
      final s = statusOn(10, logOf([older, start, future]));
      expect(s.lastStart, start);
      expect(statusOn(10, logOf([future])).phase, PeriodPhase.noData);
    });

    test('is not thrown by the time of day or daylight saving', () {
      // 5 Apr 2026 spans a typical DST change in many zones.
      final s = PeriodStatus.of(logOf([DateTime(2026, 3, 20, 23, 59)]),
          DateTime(2026, 4, 5, 0, 1));
      expect(s.daysUntilExpected, 12); // 17 Apr − 5 Apr
    });
  });

  group('end dates', () {
    test('ending early starts the countdown straight away', () {
      final log = logOf([start]).withEnd(start, day(2)); // 3-day period
      expect(log.lengthOf(start), 3);
      expect(statusOn(2, log).phase, PeriodPhase.onPeriod);
      expect(statusOn(2, log).dayOfPeriod, 3);
      expect(statusOn(2, log).periodLength, 3);
      expect(statusOn(2, log).periodDaysLeft, 1);
      expect(statusOn(3, log).phase, PeriodPhase.countdown);
      // The next period is still expected 28 days after the start.
      expect(statusOn(3, log).expectedStart, day(28));
    });

    test('a longer period stays on-period until its end date', () {
      final log = logOf([start]).withEnd(start, day(6)); // 7 days
      expect(statusOn(5, log).phase, PeriodPhase.onPeriod);
      expect(statusOn(5, log).dayOfPeriod, 6);
      expect(statusOn(5, log).periodLength, 7);
      expect(statusOn(6, log).periodDaysLeft, 1);
      expect(statusOn(7, log).phase, PeriodPhase.countdown);
    });

    test('a one-day period is allowed; an end before the start is not', () {
      final log = logOf([start]).withEnd(start, start);
      expect(log.lengthOf(start), 1);
      expect(logOf([start]).withEnd(start, day(-1)).endOf(start), isNull);
      // No such period: ignored.
      expect(logOf([start]).withEnd(day(9), day(10)).storedEnds, isEmpty);
    });

    test('an end never runs into the next period', () {
      final next = day(3);
      final log = logOf([start, next], {start: day(10)});
      expect(log.endOf(start), day(2));
      expect(log.lengthOf(start), 3);
      // Without an end, the default 5 days is also cut at the next start.
      expect(logOf([start, next]).lengthOf(start), 3);
    });

    test('clearing and deleting remove the end date', () {
      final log = logOf([start]).withEnd(start, day(3));
      expect(log.endOf(start), day(3));
      expect(log.withoutEnd(start).endOf(start), isNull);
      expect(log.withoutEnd(start).lengthOf(start), 5);
      final removed = log.withoutStart(start);
      expect(removed.isEmpty, true);
      expect(removed.storedEnds, isEmpty);
    });
  });

  test('calendar helpers', () {
    final log = logOf([start]);
    final status = statusOn(10);
    expect(isPeriodDay(log, day(0)), true);
    expect(isPeriodDay(log, day(4)), true);
    expect(isPeriodDay(log, day(5)), false);
    expect(isPeriodDay(log, day(-1)), false);
    expect(isPredictedDay(status, day(25)), false);
    expect(isPredictedDay(status, day(26)), true);
    expect(isPredictedDay(status, day(30)), true);
    expect(isPredictedDay(status, day(31)), false);
    expect(isPredictedDay(const PeriodStatus.noData(), day(28)), false);

    // Period days follow the end date, not the 5-day default.
    final ended = log.withEnd(start, day(2));
    expect(isPeriodDay(ended, day(2)), true);
    expect(isPeriodDay(ended, day(3)), false);
    final longer = log.withEnd(start, day(6));
    expect(isPeriodDay(longer, day(6)), true);
    expect(isPeriodDay(longer, day(7)), false);
  });

  test('periods and end dates persist, dedupe, and survive a backup',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = PeriodLogNotifier(prefs);

    await notifier.addStart(DateTime(2026, 1, 3, 14, 30));
    await notifier.addStart(DateTime(2026, 2, 1));
    await notifier.addStart(DateTime(2026, 2, 1, 9)); // same day: ignored
    await notifier.setEnd(DateTime(2026, 2, 1), DateTime(2026, 2, 4));
    expect(notifier.state.starts,
        [DateTime(2026, 2, 1), DateTime(2026, 1, 3)]);

    // Reload, as after an app restart.
    var reloaded = PeriodLogNotifier(prefs).state;
    expect(reloaded.starts, notifier.state.starts);
    expect(reloaded.endOf(DateTime(2026, 2, 1)), DateTime(2026, 2, 4));
    expect(reloaded.endOf(DateTime(2026, 1, 3)), isNull);

    // Included in the generic preferences backup and restorable.
    final exported = BackupService(_FakeIsar(), prefs).exportPreferences();
    expect(exported.keys, contains(PeriodLogNotifier.startsKey));
    expect(exported.keys, contains(PeriodLogNotifier.endsKey));
    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    await BackupService(_FakeIsar(), fresh).importPreferences(exported);
    final restored = PeriodLogNotifier(fresh).state;
    expect(restored.starts.length, 2);
    expect(restored.endOf(DateTime(2026, 2, 1)), DateTime(2026, 2, 4));

    // Data saved before end dates existed still loads (starts only).
    SharedPreferences.setMockInitialValues({
      PeriodLogNotifier.startsKey: ['2026-03-01'],
    });
    final legacy =
        PeriodLogNotifier(await SharedPreferences.getInstance()).state;
    expect(legacy.starts, [DateTime(2026, 3, 1)]);
    expect(legacy.lengthOf(DateTime(2026, 3, 1)), 5);

    // Clearing and deleting.
    await notifier.clearEnd(DateTime(2026, 2, 1));
    expect(PeriodLogNotifier(prefs).state.endOf(DateTime(2026, 2, 1)), isNull);
    await notifier.setEnd(DateTime(2026, 2, 1), DateTime(2026, 2, 3));
    await notifier.removeStart(DateTime(2026, 2, 1));
    reloaded = PeriodLogNotifier(prefs).state;
    expect(reloaded.starts, [DateTime(2026, 1, 3)]);
    expect(reloaded.storedEnds, isEmpty);
  });
}
