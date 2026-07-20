import 'package:isar/isar.dart';

part 'workout_entry.g.dart';

@collection
class WorkoutEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late DateTime date; // Stored at midnight to represent the day

  late DateTime recordedAt; // Optional, when it was toggled

  double? weight; // Optional weight in kg
}
