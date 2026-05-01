import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/models/goal.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.goal,
    required this.totalSaved,
    required this.streakDays,
  });

  final Goal goal;
  final double totalSaved;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final progressPct = goal.targetAmountLkr > 0
        ? (totalSaved / goal.targetAmountLkr * 100).clamp(0.0, 100.0)
        : 0.0;
    final fmt = NumberFormat('#,##0', 'en_US');
    final isFitness = goal.type == GoalType.fitnessFinancial;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  goal.name.toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _TypeBadge(isFitness: isFitness),
            ],
          ),
          const SizedBox(height: 4),

          // Streak
          if (streakDays > 0)
            Text(
              'DAY $streakDays',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                letterSpacing: 2,
                color: AppColors.accentGold,
              ),
            ),

          const Spacer(),

          // Amount display
          RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Rajdhani'),
              children: [
                TextSpan(
                  text: '${AppConstants.kCurrencySymbol} ${fmt.format(totalSaved)}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentGold,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of ${AppConstants.kCurrencySymbol} ${fmt.format(goal.targetAmountLkr)}',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Angular segmented progress bar
          _AngularProgressBar(progress: progressPct / 100),
          const SizedBox(height: 8),

          // Progress percentage
          Text(
            '${progressPct.toStringAsFixed(1)}% COMPLETE',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              letterSpacing: 1.5,
              color: AppColors.textPrimary,
            ),
          ),

          // Fitness milestone
          if (isFitness && goal.fitnessMilestone != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 10),
            Text(
              '"${goal.fitnessMilestone}"',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isFitness});
  final bool isFitness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accentBlue),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        isFitness ? 'FITNESS' : 'FINANCIAL',
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 9,
          letterSpacing: 1.5,
          color: AppColors.accentBlue,
        ),
      ),
    );
  }
}

class _AngularProgressBar extends StatelessWidget {
  const _AngularProgressBar({required this.progress});
  final double progress; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 8),
      painter: _SegmentedBarPainter(progress: progress),
    );
  }
}

class _SegmentedBarPainter extends CustomPainter {
  _SegmentedBarPainter({required this.progress});
  final double progress;

  static const int segments = 20;
  static const double gap = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final filled = (progress * segments).round();
    final segW = (size.width - gap * (segments - 1)) / segments;

    for (int i = 0; i < segments; i++) {
      final x = i * (segW + gap);
      final rect = Rect.fromLTWH(x, 0, segW, size.height);
      final paint = Paint()
        ..color = i < filled ? AppColors.accentGold : AppColors.accentBlue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_SegmentedBarPainter old) => old.progress != progress;
}
