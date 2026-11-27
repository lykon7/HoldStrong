import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/period_cycle.dart';
import 'recalibration_provider.dart';

/// Period start dates, newest first. Stored as `yyyy-MM-dd` strings in
/// SharedPreferences, so they're included in backups with the other settings.
final periodStartsProvider =
    StateNotifierProvider<PeriodStartsNotifier, List<DateTime>>((ref) {
  return PeriodStartsNotifier(ref.watch(sharedPreferencesProvider));
});

class PeriodStartsNotifier extends StateNotifier<List<DateTime>> {
  PeriodStartsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static const prefsKey = 'period_start_dates';

  static List<DateTime> _load(SharedPreferences prefs) {
    final out = <DateTime>{};
    for (final s in prefs.getStringList(prefsKey) ?? const <String>[]) {
      final d = DateTime.tryParse(s);
      if (d != null) out.add(dateOnly(d));
    }
    return out.toList()..sort((a, b) => b.compareTo(a));
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _save(List<DateTime> starts) async {
    final sorted = [...starts]..sort((a, b) => b.compareTo(a));
    await _prefs.setStringList(prefsKey, sorted.map(_fmt).toList());
    state = sorted;
  }

  /// Marks [day] as the first day of a period. Marking the same day twice
  /// is a no-op.
  Future<void> addStart(DateTime day) async {
    final d = dateOnly(day);
    if (state.contains(d)) return;
    await _save([...state, d]);
  }

  Future<void> removeStart(DateTime day) async {
    final d = dateOnly(day);
    await _save(state.where((s) => s != d).toList());
  }
}
