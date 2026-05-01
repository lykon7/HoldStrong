import 'dart:math';

class MessageBank {
  MessageBank._();

  static const List<String> financial = [
    'RS {amount} SAVED. That is {progress}% of your {goal}. You are not playing.',
    'You looked that craving dead in the eye and said no. RS {amount} locked in.',
    'Day {streak}. RS {amount} closer to your {goal}. This is what discipline looks like.',
    'The food was not worth it. Your {goal} is. RS {amount} added to the war chest.',
    'That craving had a price tag: RS {amount}. You refused to pay it.',
    'RS {amount}. Small? Maybe. But you are {progress}% of the way to your {goal} and that is real.',
    'Most people give in. You did not. RS {amount} stays where it belongs.',
    'You won that round. RS {amount} towards {goal}. Keep going.',
    'RS {amount} saved. {progress}% done. The goal is not moving. Neither are you.',
    'Discipline is not motivation. It is a decision. You just made it. RS {amount}.',
    'The craving lasted a moment. Your {goal} will last a lifetime. RS {amount} saved.',
    'You chose the goal over the moment. RS {amount} recorded. Do it again tomorrow.',
  ];

  static const List<String> fitnessFinancial = [
    'RS {amount} SAVED. ~{calories} CALORIES AVOIDED. You are building the right version of yourself.',
    'That junk would have cost you RS {amount} and set you back {calories} calories. You kept both.',
    'RS {amount} towards {goal}. {calories} calories you did not eat. Both wins count.',
    'Your wallet and your body are aligned. RS {amount} saved, {calories} kcal avoided.',
    'Financial discipline and physical discipline are the same muscle. You just trained it. RS {amount}.',
    'You resisted. RS {amount} saved. {calories} calories stayed out of your system. This is the work.',
    'The version of yourself you are building does not eat that. RS {amount} saved. {calories} kcal avoided.',
  ];

  static const List<String> milestones = [
    '7-DAY STREAK. RS {amount} just added to a 7-day run of discipline. Do not stop.',
    'RS 50,000 SAVED IN TOTAL. That is not a number. That is a decision made {streak} times.',
    '100TH RESIST LOGGED. RS {amount}. You are a different person than when you started.',
    'GOAL COMPLETE. Every RS saved, every craving refused — it was worth it.',
  ];

  static final _rng = Random();

  /// Returns a formatted message for a financial resist.
  static String pickFinancial({
    required String amount,
    required String goal,
    required String progress,
    required String streak,
  }) {
    final template = financial[_rng.nextInt(financial.length)];
    return _fill(template, amount: amount, goal: goal, progress: progress, streak: streak);
  }

  /// Returns a formatted message for a fitness+financial resist.
  static String pickFitnessFinancial({
    required String amount,
    required String goal,
    required String progress,
    required String streak,
    required String calories,
  }) {
    final template = fitnessFinancial[_rng.nextInt(fitnessFinancial.length)];
    return _fill(template,
        amount: amount, goal: goal, progress: progress, streak: streak, calories: calories);
  }

  static String _fill(
    String template, {
    required String amount,
    required String goal,
    required String progress,
    required String streak,
    String calories = '',
  }) {
    return template
        .replaceAll('{amount}', amount)
        .replaceAll('{goal}', goal)
        .replaceAll('{progress}', progress)
        .replaceAll('{streak}', streak)
        .replaceAll('{calories}', calories);
  }
}
