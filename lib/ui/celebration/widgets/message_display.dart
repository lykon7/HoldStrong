import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class MessageDisplay extends StatelessWidget {
  const MessageDisplay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.accentGold, width: 2),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
