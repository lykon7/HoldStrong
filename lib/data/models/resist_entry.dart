import 'package:isar/isar.dart';

part 'resist_entry.g.dart';

@collection
class ResistEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String goalUuid;

  late double amountLkr;
  String? label;
  int? caloriesAvoided;
  String? note;

  @Index()
  late DateTime loggedAt;
}
