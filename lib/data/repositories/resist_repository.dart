import 'package:isar/isar.dart';
import '../models/resist_entry.dart';

class ResistRepository {
  ResistRepository(this._isar);

  final Isar _isar;

  Stream<List<ResistEntry>> watchEntriesForGoal(String goalUuid) {
    return _isar.resistEntrys
        .filter()
        .goalUuidEqualTo(goalUuid)
        .sortByLoggedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<ResistEntry>> watchAllEntries() {
    return _isar.resistEntrys
        .where()
        .sortByLoggedAtDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<ResistEntry>> watchRecentEntries({int limit = 3}) {
    return _isar.resistEntrys
        .where()
        .sortByLoggedAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Future<List<ResistEntry>> getRecentEntries({int limit = 3}) async {
    return _isar.resistEntrys
        .where()
        .sortByLoggedAtDesc()
        .limit(limit)
        .findAll();
  }

  Future<void> saveEntry(ResistEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.resistEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(String uuid) async {
    await _isar.writeTxn(() async {
      final entry =
          await _isar.resistEntrys.filter().uuidEqualTo(uuid).findFirst();
      if (entry != null) {
        await _isar.resistEntrys.delete(entry.id);
      }
    });
  }

  Future<double> getTotalSavedForGoal(String goalUuid) async {
    final entries = await _isar.resistEntrys
        .filter()
        .goalUuidEqualTo(goalUuid)
        .findAll();
    return entries.fold<double>(0.0, (sum, e) => sum + e.amountLkr);
  }

  Future<List<ResistEntry>> getAllEntriesForGoal(String goalUuid) async {
    return _isar.resistEntrys
        .filter()
        .goalUuidEqualTo(goalUuid)
        .sortByLoggedAtDesc()
        .findAll();
  }

  Future<List<ResistEntry>> getAllEntries() async {
    return _isar.resistEntrys.where().sortByLoggedAtDesc().findAll();
  }

  Future<double> getTotalCaloriesAvoidedForGoal(String goalUuid) async {
    final entries = await _isar.resistEntrys
        .filter()
        .goalUuidEqualTo(goalUuid)
        .caloriesAvoidedIsNotNull()
        .findAll();
    return entries.fold<double>(0.0, (sum, e) => sum + (e.caloriesAvoided ?? 0));
  }

  Future<void> deleteAllEntries() async {
    await _isar.writeTxn(() async {
      await _isar.resistEntrys.clear();
    });
  }
}
