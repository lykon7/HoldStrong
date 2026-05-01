import 'package:isar/isar.dart';

part 'craving_label.g.dart';

@collection
class CravingLabel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index(unique: true)
  late String name;

  int? defaultCalories;
  int useCount = 0;
  late DateTime lastUsed;
}
