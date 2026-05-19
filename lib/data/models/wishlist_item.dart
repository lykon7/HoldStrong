import 'package:isar/isar.dart';

part 'wishlist_item.g.dart';

@collection
class WishlistItem {
  Id id = Isar.autoIncrement;

  late String name;
  late double estimatedCost;
  late DateTime createdAt;
}
