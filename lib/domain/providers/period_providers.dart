import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/period_cycle.dart';
import 'recalibration_provider.dart';

/// Every logged period. Stored as `yyyy-MM-dd` strings in SharedPreferences,
/// so it's included in backups with the other settings.
final periodLogProvider =
    StateNotifierProvider<PeriodLogNotifier, PeriodLog>((ref) {
  return PeriodLogNotifier(ref.watch(sharedPreferencesProvider));
});

class PeriodLogNotifier extends StateNotifier<PeriodLog> {
  PeriodLogNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  /// Period start dates, one `yyyy-MM-dd` per entry.
  static const startsKey = 'period_start_dates';

  /// Optional end dates, one `start,end` pair per entry.
  static const endsKey = 'period_end_dates';

  static PeriodLog _load(SharedPreferences prefs) {
    final starts = <DateTime>[];
    for (final s in prefs.getStringList(startsKey) ?? const <String>[]) {
      final d = DateTime.tryParse(s);
      if (d != null) starts.add(d);
    }
    final ends = <DateTime, DateTime>{};
    for (final pair in prefs.getStringList(endsKey) ?? const <String>[]) {
      final parts = pair.split(',');
      if (parts.length != 2) continue;
      final s = DateTime.tryParse(parts[0]);
      final e = DateTime.tryParse(parts[1]);
      if (s != null && e != null) ends[s] = e;
    }
    return PeriodLog(starts: starts, ends: ends);
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _save(PeriodLog log) async {
    await _prefs.setStringList(startsKey, log.starts.map(_fmt).toList());
    // Only keep ends that still belong to a period.
    final ends = log.storedEnds.entries
        .where((e) => log.starts.contains(e.key))
        .map((e) => '${_fmt(e.key)},${_fmt(e.value)}')
        .toList();
    await _prefs.setStringList(endsKey, ends);
    state = log;
  }

  /// Marks [day] as the first day of a period. Marking the same day twice
  /// is a no-op.
  Future<void> addStart(DateTime day) async {
    if (state.starts.contains(dateOnly(day))) return;
    await _save(state.withStart(day));
  }

  /// Deletes the period that began on [day], including its end date.
  Future<void> removeStart(DateTime day) => _save(state.withoutStart(day));

  /// Sets the last day of the period that began on [start].
  Future<void> setEnd(DateTime start, DateTime end) =>
      _save(state.withEnd(start, end));

  /// Forgets the end date, so the period reverts to the default length.
  Future<void> clearEnd(DateTime start) => _save(state.withoutEnd(start));
}
