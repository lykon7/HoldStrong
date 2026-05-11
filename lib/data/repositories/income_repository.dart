import 'package:isar/isar.dart';
import '../models/income_entry.dart';

class IncomeRepository {
  IncomeRepository(this._isar);

  final Isar _isar;

  Stream<List<IncomeEntry>> watchAllEntries() {
    return _isar.incomeEntrys
        .where()
        .sortByLoggedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<void> saveEntry(IncomeEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.incomeEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(String uuid) async {
    await _isar.writeTxn(() async {
      final entry =
          await _isar.incomeEntrys.filter().uuidEqualTo(uuid).findFirst();
      if (entry != null) {
        await _isar.incomeEntrys.delete(entry.id);
      }
    });
  }

  Future<void> deleteAllEntries() async {
    await _isar.writeTxn(() async {
      await _isar.incomeEntrys.clear();
    });
  }
}
