import 'package:isar/isar.dart';

part 'goal.g.dart';

enum GoalType { financial, fitnessFinancial }

@collection
class Goal {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;

  @enumerated
  late GoalType type;

  late double targetAmountLkr;
  String currency = 'LKR';

  String? fitnessMilestone;

  late DateTime createdAt;
  DateTime? targetDate;

  bool isActive = false;
  bool isCompleted = false;
  DateTime? completedAt;
}
