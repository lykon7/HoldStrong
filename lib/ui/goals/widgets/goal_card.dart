import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/models/goal.dart';
import '../../../domain/providers/goal_providers.dart';

class GoalCard extends ConsumerWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.isHighlighted,
  });

  final Goal goal;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(goalStatsProvider(goal.uuid));
    final fmt = NumberFormat('#,##0', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isHighlighted ? AppColors.accentGold.withOpacity(0.5) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.name.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(goal: goal),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  goal.type == GoalType.fitnessFinancial ? 'FITNESS + FINANCIAL' : 'FINANCIAL',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    letterSpacing: 2,
                    color: AppColors.accentBlue,
                  ),
                ),

                const SizedBox(height: 12),

                stats.when(
                  data: (s) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppConstants.kCurrencySymbol} ${fmt.format(s.totalSaved)} of ${AppConstants.kCurrencySymbol} ${fmt.format(goal.targetAmountLkr)}',
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MiniProgressBar(progress: s.progressPct / 100),
                      const SizedBox(height: 4),
                      Text(
                        '${s.progressPct.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (s.projectedCompletionDate != null && !goal.isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Projected: ${dateFmt.format(s.projectedCompletionDate!)}',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Action bar
          if (!goal.isCompleted)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  if (!goal.isActive)
                    _ActionBtn(
                      label: 'SET ACTIVE',
                      onTap: () => ref.read(goalRepositoryProvider).setActiveGoal(goal.uuid),
                    ),
                  _ActionBtn(
                    label: 'EDIT',
                    onTap: () => context.push('/goals/${goal.uuid}/edit'),
                  ),
                  _ActionBtn(
                    label: 'COMPLETE',
                    onTap: () => _confirmComplete(context, ref),
                    isDestructive: false,
                    isGold: true,
                  ),
                  _ActionBtn(
                    label: 'DELETE',
                    onTap: () => _confirmDelete(context, ref),
                    isDestructive: true,
                  ),
                ],
              ),
            ),

          if (goal.isCompleted && goal.completedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Completed ${dateFmt.format(goal.completedAt!)}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmComplete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        title: const Text('MARK AS COMPLETE',
            style: TextStyle(fontFamily: 'Rajdhani', color: AppColors.accentGold)),
        content: const Text(
          'This will archive the goal and record it as completed.',
          style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(goalRepositoryProvider).completeGoal(goal.uuid);
            },
            child: const Text('COMPLETE',
                style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        title: const Text('DELETE GOAL',
            style: TextStyle(fontFamily: 'Rajdhani', color: AppColors.destructive)),
        content: const Text(
          'This will permanently delete the goal and all its logged resists.',
          style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(goalRepositoryProvider).deleteGoal(goal.uuid);
            },
            child: const Text('DELETE',
                style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (goal.isCompleted) {
      label = 'DONE';
      color = AppColors.accentGold;
    } else if (goal.isActive) {
      label = 'ACTIVE';
      color = AppColors.accentGold;
    } else {
      label = 'INACTIVE';
      color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 9,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 4),
      painter: _MiniBarPainter(progress: progress),
    );
  }
}

class _MiniBarPainter extends CustomPainter {
  _MiniBarPainter({required this.progress});
  final double progress;

  static const int segments = 20;
  static const double gap = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final filled = (progress * segments).round();
    final segW = (size.width - gap * (segments - 1)) / segments;
    for (int i = 0; i < segments; i++) {
      final x = i * (segW + gap);
      final rect = Rect.fromLTWH(x, 0, segW, size.height);
      final paint = Paint()
        ..color = i < filled
            ? AppColors.accentGold
            : AppColors.accentBlue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_MiniBarPainter old) => old.progress != progress;
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.isGold = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.destructive
        : isGold
            ? AppColors.accentGold
            : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9,
              letterSpacing: 1,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
