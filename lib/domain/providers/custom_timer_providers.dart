import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_timer.dart';
import 'recalibration_provider.dart';

final customTimersProvider = StateNotifierProvider<CustomTimersNotifier, List<CustomTimer>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CustomTimersNotifier(prefs);
});

class CustomTimersNotifier extends StateNotifier<List<CustomTimer>> {
  CustomTimersNotifier(this._prefs) : super(_loadAndMigrate(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'custom_timers_list';
  static const _legacyKey = 'last_watched_porn_timestamp';

  static List<CustomTimer> _loadAndMigrate(SharedPreferences prefs) {
    final rawList = prefs.getStringList(_key);
    
    if (rawList != null && rawList.isNotEmpty) {
      return rawList.map((str) => CustomTimer.fromJson(str)).toList();
    }

    // Migration
    final legacyMillis = prefs.getInt(_legacyKey);
    if (legacyMillis != null) {
      final legacyTimer = CustomTimer.create(
        title: 'TIME SINCE',
        targetDate: DateTime.fromMillisecondsSinceEpoch(legacyMillis),
        isCountdown: false,
      );
      // We don't save synchronously here, but we will save on next interaction.
      return [legacyTimer];
    }

    return [];
  }

  Future<void> _save(List<CustomTimer> timers) async {
    final stringList = timers.map((t) => t.toJson()).toList();
    await _prefs.setStringList(_key, stringList);
    state = timers;
  }

  Future<void> addTimer(CustomTimer timer) async {
    final newTimers = [...state, timer];
    await _save(newTimers);
  }

  Future<void> updateTimer(CustomTimer timer) async {
    final newTimers = state.map((t) => t.id == timer.id ? timer : t).toList();
    await _save(newTimers);
  }

  Future<void> deleteTimer(String id) async {
    final newTimers = state.where((t) => t.id != id).toList();
    await _save(newTimers);
  }

  Future<void> reorderTimers(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newTimers = List<CustomTimer>.from(state);
    final item = newTimers.removeAt(oldIndex);
    newTimers.insert(newIndex, item);
    await _save(newTimers);
  }
}
