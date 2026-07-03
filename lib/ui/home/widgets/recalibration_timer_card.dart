import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../domain/providers/recalibration_provider.dart';

class RecalibrationTimerCard extends ConsumerStatefulWidget {
  const RecalibrationTimerCard({super.key});

  @override
  ConsumerState<RecalibrationTimerCard> createState() =>
      _RecalibrationTimerCardState();
}

class _RecalibrationTimerCardState
    extends ConsumerState<RecalibrationTimerCard> {
  Timer? _timer;

  static const _messages = [
    "Your dopamine threshold is shifting down. Every second counted is neural rewiring.",
    "Pixels are cheap stimulation. Your real life is not. You just reclaimed another moment.",
    "The sensation is dopamine seeking an old path. The path is closing. Hold strong.",
    "You are not broken. You are recalibrating. Discipline over artificial novelty.",
    "Every urge defeated strengthens your prefrontal cortex. Keep holding.",
    "Real connection requires a real baseline. You are building it right now.",
    "The urge lasts a few minutes. Your recovery lasts forever.",
    "Discipline is not a feeling. It is a decision you keep making every second.",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickCustomTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            onPrimary: AppColors.backgroundPrimary,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            onPrimary: AppColors.backgroundPrimary,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final customDateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await ref
        .read(recalibrationStartTimeProvider.notifier)
        .setStartTime(customDateTime);
  }

  void _showManageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MANAGE RECALIBRATION TIMER',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                letterSpacing: 2,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.backgroundPrimary),
              label: const Text('RESET TO RIGHT NOW'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.backgroundPrimary,
                textStyle: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700, fontSize: 16),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(recalibrationStartTimeProvider.notifier).resetToNow();
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textPrimary),
              label: const Text('SET CUSTOM PAST DATE/TIME'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cardBorder),
                foregroundColor: AppColors.textPrimary,
                textStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _pickCustomTime();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(recalibrationStartTimeProvider.notifier).clear();
              },
              child: const Text(
                'CLEAR TIMER',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: AppColors.destructive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTime = ref.watch(recalibrationStartTimeProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(2),
      ),
      child: startTime == null
          ? _buildUnstartedView()
          : _buildTimerView(startTime),
    );
  }

  Widget _buildUnstartedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'RECALIBRATION TIMER',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track clean time elapsed since last watched porn down to the second.',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            await ref
                .read(recalibrationStartTimeProvider.notifier)
                .resetToNow();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.backgroundPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            'START RECALIBRATION TIMER',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: _pickCustomTime,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Text(
                'SET CUSTOM PAST TIMESTAMP',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  letterSpacing: 1,
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerView(DateTime startTime) {
    final now = DateTime.now();
    var elapsed = now.difference(startTime);
    if (elapsed.isNegative) elapsed = Duration.zero;

    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    final msgIndex = (elapsed.inSeconds ~/ 15) % _messages.length;
    final motivationMsg = _messages[msgIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CLEAN TIME RECLAIMED',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: _showManageSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundElevated,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(startTime).toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Live counter display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimeSegment(days.toString().padLeft(2, '0'), 'DAYS'),
            _buildColon(),
            _buildTimeSegment(hours.toString().padLeft(2, '0'), 'HRS'),
            _buildColon(),
            _buildTimeSegment(minutes.toString().padLeft(2, '0'), 'MIN'),
            _buildColon(),
            _buildTimeSegment(seconds.toString().padLeft(2, '0'), 'SEC'),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: AppColors.cardBorder.withValues(alpha: 0.5), height: 1),
        const SizedBox(height: 12),
        // Rotating motivation message
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.bolt_outlined,
              size: 14,
              color: AppColors.accentGold,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  motivationMsg,
                  key: ValueKey(msgIndex),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ),
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
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: AppColors.accentGold,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
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
    return const Padding(
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
    );
  }
}
