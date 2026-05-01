import 'package:isar/isar.dart';
import '../models/goal.dart';

class GoalRepository {
  GoalRepository(this._isar);

  final Isar _isar;

  Stream<Goal?> watchActiveGoal() {
    return _isar.goals
        .filter()
        .isActiveEqualTo(true)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  Stream<List<Goal>> watchAllGoals() {
    return _isar.goals
        .filter()
        .isCompletedEqualTo(false)
        .or()
        .isCompletedEqualTo(true)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<Goal?> getGoalByUuid(String uuid) async {
    return _isar.goals.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> saveGoal(Goal goal) async {
    await _isar.writeTxn(() async {
      await _isar.goals.put(goal);
    });
  }

  Future<void> setActiveGoal(String uuid) async {
    await _isar.writeTxn(() async {
      // Deactivate all
      final all = await _isar.goals.where().findAll();
      for (final g in all) {
        g.isActive = false;
      }
      await _isar.goals.putAll(all);

      // Activate target
      final target = await _isar.goals.filter().uuidEqualTo(uuid).findFirst();
      if (target != null) {
        target.isActive = true;
        await _isar.goals.put(target);
      }
    });
  }

  Future<void> completeGoal(String uuid) async {
    await _isar.writeTxn(() async {
      final goal = await _isar.goals.filter().uuidEqualTo(uuid).findFirst();
      if (goal != null) {
        goal.isCompleted = true;
        goal.isActive = false;
        goal.completedAt = DateTime.now();
        await _isar.goals.put(goal);
      }
    });
  }

  Future<void> deleteGoal(String uuid) async {
    await _isar.writeTxn(() async {
      final goal = await _isar.goals.filter().uuidEqualTo(uuid).findFirst();
      if (goal != null) {
        await _isar.goals.delete(goal.id);
      }
    });
  }
}
