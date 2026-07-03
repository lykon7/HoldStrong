import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final recalibrationStartTimeProvider =
    StateNotifierProvider<RecalibrationStartTimeNotifier, DateTime?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RecalibrationStartTimeNotifier(prefs);
});

class RecalibrationStartTimeNotifier extends StateNotifier<DateTime?> {
  RecalibrationStartTimeNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'last_watched_porn_timestamp';

  static DateTime? _load(SharedPreferences prefs) {
    final millis = prefs.getInt(_key);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setStartTime(DateTime time) async {
    await _prefs.setInt(_key, time.millisecondsSinceEpoch);
    state = time;
  }

  Future<void> resetToNow() async {
    await setStartTime(DateTime.now());
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    state = null;
  }
}
