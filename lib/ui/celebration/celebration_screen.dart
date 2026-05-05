import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../domain/models/celebration_data.dart';
import 'widgets/gold_pulse_animation.dart';
import 'widgets/message_display.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key, required this.data});

  final CelebrationData data;

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(seconds: AppConstants.kCelebrationAutoDismissSeconds),
      () { if (mounted) context.go('/'); },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final fmt = NumberFormat('#,##0', 'en_US');

    return GestureDetector(
      onTap: () => context.go('/'),
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Stack(
          children: [
            // Gold pulse background animation
            const Positioned.fill(child: GoldPulseAnimation()),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),

                    // Primary amount
                    Text(
                      '${AppConstants.kCurrencySymbol} ${fmt.format(data.amountSaved)}',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const Text(
                      'SAVED',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        letterSpacing: 6,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Progress line
                    Text(
                      '${data.progressPct.toStringAsFixed(1)}% closer to your ${data.goalName}',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total saved: ${AppConstants.kCurrencySymbol} ${fmt.format(data.totalSaved)} of ${AppConstants.kCurrencySymbol} ${fmt.format(data.targetAmount)}',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // Fitness milestone — shown for all fitness goals
                    if (data.isFitnessGoal && data.fitnessMilestone != null) ...[
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.cardBorder),
                      const SizedBox(height: 16),
                      Text(
                        '"${data.fitnessMilestone}" — you are doing it.',
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    const Spacer(flex: 3),

                    // Motivational message
                    MessageDisplay(message: data.message),

                    const SizedBox(height: 24),

                    // Dismiss hint
                    Center(
                      child: Text(
                        'TAP ANYWHERE TO CONTINUE',
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 9,
                          letterSpacing: 2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
