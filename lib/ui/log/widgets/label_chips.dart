import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../domain/providers/label_providers.dart';

class LabelChips extends ConsumerWidget {
  const LabelChips({super.key, required this.onSelected});

  final void Function(String name, int? calories) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortlist = ref.watch(shortlistProvider);

    return shortlist.when(
      data: (labels) {
        if (labels.isEmpty) return const SizedBox.shrink();
        final visible = labels.take(AppConstants.kMaxChipsVisible).toList();
        return SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final label = visible[i];
              return GestureDetector(
                onTap: () => onSelected(label.name, label.defaultCalories),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accentBlue),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    label.name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      letterSpacing: 1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
