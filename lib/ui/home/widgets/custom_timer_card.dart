import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../domain/models/custom_timer.dart';
import '../../../domain/providers/custom_timer_providers.dart';

class CustomTimerCard extends ConsumerStatefulWidget {
  final CustomTimer timer;

  const CustomTimerCard({super.key, required this.timer});

  @override
  ConsumerState<CustomTimerCard> createState() => _CustomTimerCardState();
}

class _CustomTimerCardState extends ConsumerState<CustomTimerCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _showRenameDialog() {
    final ctrl = TextEditingController(text: widget.timer.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('RENAME TIMER', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'e.g. TIME SINCE',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newTitle = ctrl.text.trim().toUpperCase();
              if (newTitle.isNotEmpty) {
                ref.read(customTimersProvider.notifier).updateTimer(
                  widget.timer.copyWith(title: newTitle)
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: _buildTimerView(),
    );
  }

  Widget _buildTimerView() {
    final now = DateTime.now();
    
    Duration elapsed;
    if (widget.timer.isCountdown) {
      elapsed = widget.timer.targetDate.difference(now);
      if (elapsed.isNegative) elapsed = Duration.zero;
    } else {
      elapsed = now.difference(widget.timer.targetDate);
      if (elapsed.isNegative) elapsed = Duration.zero;
    }

    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showRenameDialog,
                child: Row(
                  children: [
                    Text(
                      widget.timer.title,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined, size: 12, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                DateFormat('MMM d, yyyy').format(widget.timer.targetDate).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeSegment(days.toString().padLeft(2, '0'), 'DAYS')),
            _buildColon(),
            Expanded(child: _buildTimeSegment(hours.toString().padLeft(2, '0'), 'HRS')),
            _buildColon(),
            Expanded(child: _buildTimeSegment(minutes.toString().padLeft(2, '0'), 'MIN')),
            _buildColon(),
            Expanded(child: _buildTimeSegment(seconds.toString().padLeft(2, '0'), 'SEC')),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSegment(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: AppColors.accentGold,
            height: 1,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 9,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return const SizedBox(
      width: 14,
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            ':',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
