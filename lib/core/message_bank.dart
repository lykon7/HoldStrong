import 'dart:math';

class MessageBank {
  MessageBank._();

  static const List<String> financial = [
    'RS {amount} SAVED. That is {progress}% of your {goal}. You are not playing.',
    'You looked that craving dead in the eye and said no. RS {amount} locked in.',
    'Every resist counts. RS {amount} closer to your {goal}. This is what discipline looks like.',
    'The food was not worth it. Your {goal} is. RS {amount} added to the war chest.',
    'That craving had a price tag: RS {amount}. You refused to pay it.',
    'RS {amount}. Small? Maybe. But you are {progress}% of the way to your {goal} and that is real.',
    'Most people give in. You did not. RS {amount} stays where it belongs.',
    'You won that round. RS {amount} towards {goal}. Keep going.',
    'RS {amount} saved. {progress}% done. The goal is not moving. Neither are you.',
    'Discipline is not motivation. It is a decision. You just made it. RS {amount}.',
    'The craving lasted a moment. Your {goal} will last a lifetime. RS {amount} saved.',
    'You chose the goal over the moment. RS {amount} recorded. Do it again tomorrow.',
    'You held the line. RS {amount} secured towards your {goal}.',
    'Another test of will. Another victory. RS {amount} added to your {goal}.',
    'Weakness knocked, but you did not answer. RS {amount} stays yours.',
    'Instant gratification loses today. RS {amount} added. {progress}% to your {goal}.',
    'You are in control. Not your cravings. RS {amount} saved.',
  ];

  static const List<String> fitnessFinancial = [
    'RS {amount} SAVED. Empty calories AVOIDED. You are building the right version of yourself.',
    'That junk would have cost you RS {amount} and set you back physically. You kept both.',
    'RS {amount} towards {goal}. Junk food you did not eat. Both wins count.',
    'Your wallet and your body are aligned. RS {amount} saved, garbage avoided.',
    'Financial discipline and physical discipline are the same muscle. You just trained it. RS {amount}.',
    'You resisted. RS {amount} saved. Junk stayed out of your system. This is the work.',
    'The version of yourself you are building does not eat that. RS {amount} saved.',
    'You held the line. RS {amount} saved, and junk food rejected. Total victory.',
    'Weakness knocked, but you did not answer. RS {amount} stays yours, the fat stays off.',
    'Double victory. RS {amount} closer to your {goal}, and one step closer to your ideal physique.',
    'RS {amount} saved. One step closer to those abs. Keep chipping away.',
    'Belly fat does not stand a chance against this level of discipline. RS {amount} saved.',
    'You are literally burning fat by NOT spending that RS {amount}. Keep it up.',
    'That craving was just temporary comfort. Abs are forever. RS {amount} saved.',
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
  }) {
    final template = fitnessFinancial[_rng.nextInt(fitnessFinancial.length)];
    return _fill(template,
        amount: amount, goal: goal, progress: progress, streak: streak);
  }

  static String _fill(
    String template, {
    required String amount,
    required String goal,
    required String progress,
    required String streak,
  }) {
    return template
        .replaceAll('{amount}', amount)
        .replaceAll('{goal}', goal)
        .replaceAll('{progress}', progress)
        .replaceAll('{streak}', streak);
  }
}
