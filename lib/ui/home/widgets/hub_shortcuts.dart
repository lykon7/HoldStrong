import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class HubShortcuts extends StatelessWidget {
  const HubShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
            _buildShortcut(
              context,
              title: 'Journal',
              icon: Icons.book_outlined,
              color: AppColors.accentGold,
              route: '/hub/journal',
            ),
            _buildShortcut(
              context,
              title: 'Wishlist',
              icon: Icons.star_border,
              color: AppColors.accentGold,
              route: '/hub/wishlist',
            ),
            _buildShortcut(
              context,
              title: 'Resists',
              icon: Icons.shield_outlined,
              color: AppColors.accentGold,
              route: '/hub/resists',
            ),
            _buildShortcut(
              context,
              title: 'To-Do',
              icon: Icons.checklist,
              color: AppColors.accentGold,
              route: '/hub/todo',
            ),
            _buildShortcut(
              context,
              title: 'Liabilities',
              icon: Icons.receipt_long,
              color: AppColors.accentGold,
              route: '/hub/liabilities',
            ),
            _buildShortcut(
              context,
              title: 'More',
              icon: Icons.more_horiz,
              color: AppColors.accentGold,
              route: '/hub',
            ),
        ],
      ),
    );
  }

  Widget _buildShortcut(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String? route,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: route != null ? () => context.push(route) : null,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
