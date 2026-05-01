import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/craving_label.dart';
import '../../core/calorie_library.dart';

class LabelRepository {
  LabelRepository(this._isar);

  final Isar _isar;
  final _uuid = const Uuid();

  Stream<List<CravingLabel>> watchShortlist() {
    return _isar.cravingLabels
        .where()
        .sortByLastUsedDesc()
        .watch(fireImmediately: true);
  }

  Future<List<CravingLabel>> getShortlist() async {
    return _isar.cravingLabels.where().sortByLastUsedDesc().findAll();
  }

  Future<void> recordLabelUse(String name, {int? defaultCalories}) async {
    if (name.trim().isEmpty) return;
    final normalised = name.trim().toLowerCase();

    await _isar.writeTxn(() async {
      final existing =
          await _isar.cravingLabels.filter().nameEqualTo(normalised).findFirst();
      if (existing != null) {
        existing.useCount += 1;
        existing.lastUsed = DateTime.now();
        if (defaultCalories != null) {
          existing.defaultCalories = defaultCalories;
        }
        await _isar.cravingLabels.put(existing);
      } else {
        final label = CravingLabel()
          ..uuid = _uuid.v4()
          ..name = normalised
          ..useCount = 1
          ..lastUsed = DateTime.now()
          ..defaultCalories =
              defaultCalories ?? CalorieLibrary.getSuggestion(normalised);
        await _isar.cravingLabels.put(label);
      }
    });
  }

  Future<void> updateLabelCalories(String uuid, int calories) async {
    await _isar.writeTxn(() async {
      final label =
          await _isar.cravingLabels.filter().uuidEqualTo(uuid).findFirst();
      if (label != null) {
        label.defaultCalories = calories;
        await _isar.cravingLabels.put(label);
      }
    });
  }

  Future<void> deleteLabel(String uuid) async {
    await _isar.writeTxn(() async {
      final label =
          await _isar.cravingLabels.filter().uuidEqualTo(uuid).findFirst();
      if (label != null) {
        await _isar.cravingLabels.delete(label.id);
      }
    });
  }
}
