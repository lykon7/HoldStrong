import 'package:isar/isar.dart';
import '../models/expense_entry.dart';

class ExpenseRepository {
  ExpenseRepository(this._isar);

  final Isar _isar;

  Stream<List<ExpenseEntry>> watchAllEntries() {
    return _isar.expenseEntrys
        .where()
        .sortByLoggedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<void> saveEntry(ExpenseEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.expenseEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(String uuid) async {
    await _isar.writeTxn(() async {
      final entry =
          await _isar.expenseEntrys.filter().uuidEqualTo(uuid).findFirst();
      if (entry != null) {
        await _isar.expenseEntrys.delete(entry.id);
      }
    });
  }

  Future<double> getTotalForDateRange(DateTime from, DateTime to) async {
    final entries = await _isar.expenseEntrys
        .filter()
        .loggedAtBetween(from, to)
        .findAll();
    return entries.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> deleteAllEntries() async {
    await _isar.writeTxn(() async {
      await _isar.expenseEntrys.clear();
    });
  }
}
