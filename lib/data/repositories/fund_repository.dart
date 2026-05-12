import 'package:isar/isar.dart';
import '../models/fund_account.dart';

class FundRepository {
  FundRepository(this._isar);

  final Isar _isar;

  Stream<List<FundAccount>> watchAllAccounts() {
    return _isar.fundAccounts
        .where()
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  Future<List<FundAccount>> getAllAccounts() async {
    return _isar.fundAccounts.where().sortByCreatedAt().findAll();
  }

  Future<void> saveAccount(FundAccount account) async {
    await _isar.writeTxn(() async {
      await _isar.fundAccounts.put(account);
    });
  }

  Future<void> deleteAccount(String uuid) async {
    await _isar.writeTxn(() async {
      final account =
          await _isar.fundAccounts.filter().uuidEqualTo(uuid).findFirst();
      if (account != null) {
        await _isar.fundAccounts.delete(account.id);
      }
    });
  }

  Future<void> updateAccount({
    required String uuid,
    required String name,
    required double openingBalance,
  }) async {
    await _isar.writeTxn(() async {
      final account =
          await _isar.fundAccounts.filter().uuidEqualTo(uuid).findFirst();
      if (account != null) {
        account
          ..name = name
          ..openingBalance = openingBalance;
        await _isar.fundAccounts.put(account);
      }
    });
  }

  Future<void> deleteAllAccounts() async {
    await _isar.writeTxn(() async {
      await _isar.fundAccounts.clear();
    });
  }
}
