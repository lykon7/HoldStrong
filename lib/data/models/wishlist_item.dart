import 'package:isar/isar.dart';

part 'wishlist_item.g.dart';

@collection
class WishlistItem {
  Id id = Isar.autoIncrement;

  late String name;
  late double estimatedCost;
  late DateTime createdAt;

  /// Used to persist user-defined drag-and-drop order.
  int sortOrder = 0;

  bool isBought = false;
}
