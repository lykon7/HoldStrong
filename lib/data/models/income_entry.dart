import 'package:isar/isar.dart';

part 'income_entry.g.dart';

@collection
class IncomeEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late double amount;
  late String source;

  @Index()
  String? fundUuid;

  @Index()
  late DateTime loggedAt;
}
