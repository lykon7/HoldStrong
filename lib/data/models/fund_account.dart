import 'package:isar/isar.dart';

part 'fund_account.g.dart';

@collection
class FundAccount {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;
  double openingBalance = 0.0;

  @Index()
  late DateTime createdAt;
}
