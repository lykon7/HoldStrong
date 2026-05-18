import 'package:isar/isar.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  JournalRepository(this._isar);

  final Isar _isar;

  Stream<List<JournalEntry>> watchEntriesForMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    return _isar.journalEntrys
        .filter()
        .dateBetween(startOfMonth, endOfMonth)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }
  
  Stream<List<JournalEntry>> watchAllEntries() {
    return _isar.journalEntrys
        .where()
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<JournalEntry?> getEntryForDate(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _isar.journalEntrys
        .filter()
        .dateEqualTo(normalizedDate)
        .findFirst();
  }

  Future<void> saveEntry(JournalEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.journalEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(String uuid) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.journalEntrys.filter().uuidEqualTo(uuid).findFirst();
      if (entry != null) {
        await _isar.journalEntrys.delete(entry.id);
      }
    });
  }
}
