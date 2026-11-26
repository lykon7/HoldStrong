import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quick_transaction.dart';
import 'recalibration_provider.dart';

/// All quick-add presets (income and expense). Stored in SharedPreferences,
/// so the generic preferences export in the backup service covers them.
final quickTransactionsProvider =
    StateNotifierProvider<QuickTransactionsNotifier, List<QuickTransaction>>(
        (ref) {
  return QuickTransactionsNotifier(ref.watch(sharedPreferencesProvider));
});

final quickExpensesProvider = Provider<List<QuickTransaction>>((ref) {
  return ref
      .watch(quickTransactionsProvider)
      .where((q) => q.type == QuickTransactionType.expense)
      .toList();
});

final quickIncomesProvider = Provider<List<QuickTransaction>>((ref) {
  return ref
      .watch(quickTransactionsProvider)
      .where((q) => q.type == QuickTransactionType.income)
      .toList();
});

class QuickTransactionsNotifier extends StateNotifier<List<QuickTransaction>> {
  QuickTransactionsNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static const _key = 'quick_transactions_list';

  static List<QuickTransaction> _load(SharedPreferences prefs) {
    final raw = prefs.getStringList(_key) ?? const [];
    final out = <QuickTransaction>[];
    for (final s in raw) {
      try {
        out.add(QuickTransaction.fromJson(s));
      } catch (_) {
        // Skip a corrupt entry rather than losing the whole list.
      }
    }
    return out;
  }

  Future<void> _save(List<QuickTransaction> items) async {
    await _prefs.setStringList(_key, items.map((q) => q.toJson()).toList());
    state = items;
  }

  Future<void> add(QuickTransaction item) => _save([...state, item]);

  Future<void> update(QuickTransaction item) =>
      _save(state.map((q) => q.id == item.id ? item : q).toList());

  Future<void> remove(String id) =>
      _save(state.where((q) => q.id != id).toList());
}
