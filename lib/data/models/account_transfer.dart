import 'package:isar/isar.dart';

part 'account_transfer.g.dart';

@collection
class AccountTransfer {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String fromFundUuid;

  @Index()
  late String toFundUuid;

  late double amount;

  String? note;

  @Index()
  late DateTime transferAt;
}
