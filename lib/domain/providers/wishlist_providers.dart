import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/wishlist_item.dart';
import 'goal_providers.dart'; // To access isarProvider

final wishlistProvider = StreamProvider<List<WishlistItem>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.wishlistItems.where().sortByCreatedAtDesc().watch(fireImmediately: true);
});

class WishlistNotifier extends StateNotifier<AsyncValue<void>> {
  final Isar _isar;

  WishlistNotifier(this._isar) : super(const AsyncData(null));

  Future<void> addItem(String name, double cost) async {
    state = const AsyncLoading();
    try {
      final item = WishlistItem()
        ..name = name
        ..estimatedCost = cost
        ..createdAt = DateTime.now();

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
}

final wishlistControllerProvider = StateNotifierProvider<WishlistNotifier, AsyncValue<void>>((ref) {
  final isar = ref.watch(isarProvider);
  return WishlistNotifier(isar);
});
