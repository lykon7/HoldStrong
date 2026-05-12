import 'package:isar/isar.dart';

part 'expense_entry.g.dart';

@collection
class ExpenseEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late double amount;
  late String purpose;

  @Index()
  String? fundUuid;

  @Index()
  late DateTime loggedAt;
}
