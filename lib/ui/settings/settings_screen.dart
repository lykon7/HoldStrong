import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../domain/providers/goal_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // About
          _SectionHeader('ABOUT'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'HoldStrong is a discipline engine. Every craving you resist earns a brick in the wall of what you actually want. '
              'No cloud. No accounts. No telemetry. Your data lives on this device.',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('VERSION',
                    style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary)),
                Text('1.0.0',
                    style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Danger zone
          _SectionHeader('DANGER ZONE'),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: () => _confirmDeleteAll(context, ref),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.destructive.withOpacity(0.5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_outlined,
                      color: AppColors.destructive, size: 16),
                  SizedBox(width: 12),
                  Text(
                    'DELETE ALL DATA',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: AppColors.destructive,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Permanently deletes all goals and logged resists. Cannot be undone.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        title: const Text(
          'DELETE ALL DATA',
          style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              color: AppColors.destructive),
        ),
        content: const Text(
          'This will permanently delete every goal and every logged resist. There is no undo.',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(resistRepositoryProvider).deleteAllEntries();
              final goals = await ref.read(allGoalsProvider.future);
              for (final g in goals) {
                await ref.read(goalRepositoryProvider).deleteGoal(g.uuid);
              }
            },
            child: const Text('DELETE EVERYTHING',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono', color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        letterSpacing: 2,
        color: AppColors.textSecondary,
      ),
    );
  }
}
