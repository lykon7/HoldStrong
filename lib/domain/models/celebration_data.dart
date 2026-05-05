import '../../data/models/goal.dart';

class CelebrationData {
  const CelebrationData({
    required this.amountSaved,
    required this.goalName,
    required this.goalType,
    required this.progressPct,
    required this.totalSaved,
    required this.targetAmount,
    required this.streakDays,
    required this.message,
    this.fitnessMilestone,
  });

  final double amountSaved;
  final String goalName;
  final GoalType goalType;
  final double progressPct;
  final double totalSaved;
  final double targetAmount;
  final int streakDays;
  final String message;
  final String? fitnessMilestone;

  bool get isFitnessGoal => goalType == GoalType.fitnessFinancial;
}
