import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/wishlist_item.dart';
import 'goal_providers.dart'; // To access isarProvider

final wishlistProvider = StreamProvider<List<WishlistItem>>((ref) {
  final isar = ref.watch(isarProvider);
  // Sort by user-defined sortOrder; fall back to createdAt for legacy items.
  return isar.wishlistItems.where().watch(fireImmediately: true).map((items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  });
});

class WishlistNotifier extends StateNotifier<AsyncValue<void>> {
  final Isar _isar;

  WishlistNotifier(this._isar) : super(const AsyncData(null));

  Future<void> addItem(String name, double cost) async {
    state = const AsyncLoading();
    try {
      // Place new items at the end of the list.
      final all = await _isar.wishlistItems.where().findAll();
      final maxOrder = all.isEmpty
          ? -1
          : all.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);

      final item = WishlistItem()
        ..name = name
        ..estimatedCost = cost
        ..createdAt = DateTime.now()
        ..sortOrder = maxOrder + 1;

      await _isar.writeTxn(() async {
        await _isar.wishlistItems.put(item);
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteItem(Id id) async {
    state = const AsyncLoading();
    try {
      await _isar.writeTxn(() async {
        await _isar.wishlistItems.delete(id);
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> editItem(Id id, String name, double cost) async {
    state = const AsyncLoading();
    try {
      await _isar.writeTxn(() async {
        final item = await _isar.wishlistItems.get(id);
        if (item != null) {
          item.name = name;
          item.estimatedCost = cost;
          await _isar.wishlistItems.put(item);
        }
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Persists the new order after a drag-and-drop reorder.
  /// [reorderedItems] is the full list in the new desired order.
  Future<void> reorderItems(List<WishlistItem> reorderedItems) async {
    try {
      await _isar.writeTxn(() async {
        for (var i = 0; i < reorderedItems.length; i++) {
          reorderedItems[i].sortOrder = i;
          await _isar.wishlistItems.put(reorderedItems[i]);
        }
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final wishlistControllerProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<void>>((ref) {
  final isar = ref.watch(isarProvider);
  return WishlistNotifier(isar);
});
