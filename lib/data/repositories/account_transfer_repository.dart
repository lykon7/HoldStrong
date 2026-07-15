import 'package:isar/isar.dart';
import '../models/account_transfer.dart';

class AccountTransferRepository {
  AccountTransferRepository(this._isar);

  final Isar _isar;

  Stream<List<AccountTransfer>> watchAllTransfers() {
    return _isar.accountTransfers
        .where()
        .sortByTransferAtDesc()
        .watch(fireImmediately: true);
  }

  Future<void> saveTransfer(AccountTransfer transfer) async {
    await _isar.writeTxn(() async {
      await _isar.accountTransfers.put(transfer);
    });
  }

  Future<void> deleteTransfer(String uuid) async {
    await _isar.writeTxn(() async {
      final transfer =
          await _isar.accountTransfers.filter().uuidEqualTo(uuid).findFirst();
      if (transfer != null) {
        await _isar.accountTransfers.delete(transfer.id);
      }
    });
  }

  Future<void> updateTransfer({
    required String uuid,
    required String fromFundUuid,
    required String toFundUuid,
    required double amount,
    String? note,
    required DateTime transferAt,
  }) async {
    await _isar.writeTxn(() async {
      final transfer =
          await _isar.accountTransfers.filter().uuidEqualTo(uuid).findFirst();
      if (transfer != null) {
        transfer
          ..fromFundUuid = fromFundUuid
          ..toFundUuid = toFundUuid
          ..amount = amount
          ..note = note
          ..transferAt = transferAt;
        await _isar.accountTransfers.put(transfer);
      }
    });
  }

  Future<void> deleteAllTransfers() async {
    await _isar.writeTxn(() async {
      await _isar.accountTransfers.clear();
    });
  }
}
