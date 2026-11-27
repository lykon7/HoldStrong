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

  group('PeriodStatus', () {
    test('no data', () {
      expect(PeriodStatus.of([], DateTime(2026, 3, 1)).phase,
          PeriodPhase.noData);
    });

    test('counts the 5 period days, start day being day 1', () {
      final s0 = PeriodStatus.of([start], day(0));
      expect(s0.phase, PeriodPhase.onPeriod);
      expect(s0.dayOfPeriod, 1);
      expect(s0.periodDaysLeft, 5);

      final s4 = PeriodStatus.of([start], day(4));
      expect(s4.phase, PeriodPhase.onPeriod);
      expect(s4.dayOfPeriod, 5);
      expect(s4.periodDaysLeft, 1);

      expect(PeriodStatus.of([start], day(5)).phase, PeriodPhase.countdown);
    });

    test('counts down to start + 28, with a +/-2 day window', () {
      final s = PeriodStatus.of([start], day(10));
      expect(s.phase, PeriodPhase.countdown);
      expect(s.expectedStart, day(28));
      expect(s.daysUntilExpected, 18);
      expect(s.windowStart, day(26));
      expect(s.windowEnd, day(30));

      // Day 25: still a plain countdown. Day 26: window opens.
      expect(PeriodStatus.of([start], day(25)).phase, PeriodPhase.countdown);
      expect(PeriodStatus.of([start], day(26)).phase,
          PeriodPhase.expectedSoon);
      expect(PeriodStatus.of([start], day(28)).daysUntilExpected, 0);
      expect(PeriodStatus.of([start], day(30)).phase,
          PeriodPhase.expectedSoon);
    });

    test('overdue once past the window', () {
      final s = PeriodStatus.of([start], day(31));
      expect(s.phase, PeriodPhase.overdue);
      expect(s.daysLate, 1);
      expect(PeriodStatus.of([start], day(40)).daysLate, 10);
    });

    test('uses the latest start on or before today; ignores the future', () {
      final older = DateTime(2026, 2, 1);
      final future = DateTime(2026, 4, 1);
      final s = PeriodStatus.of([older, start, future], day(10));
      expect(s.lastStart, start);
      expect(PeriodStatus.of([future], day(10)).phase, PeriodPhase.noData);
    });

    test('is not thrown by the time of day or daylight saving', () {
      // 5 Apr 2026 spans a typical DST change in many zones.
      final s = PeriodStatus.of(
          [DateTime(2026, 3, 20, 23, 59)], DateTime(2026, 4, 5, 0, 1));
      expect(s.daysUntilExpected, 12); // 17 Apr − 5 Apr
    });
  });

  test('calendar helpers', () {
    final status = PeriodStatus.of([start], day(10));
    expect(isPeriodDay([start], day(0)), true);
    expect(isPeriodDay([start], day(4)), true);
    expect(isPeriodDay([start], day(5)), false);
    expect(isPeriodDay([start], day(-1)), false);
    expect(isPredictedDay(status, day(25)), false);
    expect(isPredictedDay(status, day(26)), true);
    expect(isPredictedDay(status, day(30)), true);
    expect(isPredictedDay(status, day(31)), false);
    expect(isPredictedDay(const PeriodStatus.noData(), day(28)), false);
  });

  test('starts persist newest-first, dedupe, and survive a backup', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = PeriodStartsNotifier(prefs);

    await notifier.addStart(DateTime(2026, 1, 3, 14, 30));
    await notifier.addStart(DateTime(2026, 2, 1));
    await notifier.addStart(DateTime(2026, 2, 1, 9)); // same day: ignored
    expect(notifier.state, [DateTime(2026, 2, 1), DateTime(2026, 1, 3)]);

    // Reload, as after an app restart.
    expect(PeriodStartsNotifier(prefs).state, notifier.state);

    // Included in the generic preferences backup and restorable.
    final exported = BackupService(_FakeIsar(), prefs).exportPreferences();
    expect(exported.keys, contains(PeriodStartsNotifier.prefsKey));
    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    await BackupService(_FakeIsar(), fresh).importPreferences(exported);
    expect(PeriodStartsNotifier(fresh).state.length, 2);

    await notifier.removeStart(DateTime(2026, 2, 1));
    expect(PeriodStartsNotifier(prefs).state, [DateTime(2026, 1, 3)]);
  });
}
