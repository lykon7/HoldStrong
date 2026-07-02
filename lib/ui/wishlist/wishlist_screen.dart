import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/wishlist_providers.dart';
import '../../data/models/wishlist_item.dart';
import '../../core/export_helper.dart';
import '../../core/theme.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export Wishlist',
            onPressed: () {
              final items = wishlistAsync.value ?? [];
              if (items.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wishlist is empty.')),
                );
                return;
              }
              ExportHelper.exportWishlist(items);
            },
          ),
        ],
      ),
      body: wishlistAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No items in wishlist yet.\nAdd something you want to buy!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final activeItems = items.where((e) => !e.isBought).toList();
          final boughtItems = items.where((e) => e.isBought).toList();

          final activeTotal = activeItems.fold<double>(0, (sum, item) => sum + item.estimatedCost);
          final boughtTotal = boughtItems.fold<double>(0, (sum, item) => sum + item.estimatedCost);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              if (activeItems.isNotEmpty) ...[
                _SectionHeader('WISH LIST', activeTotal),
                const SizedBox(height: 8),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeItems.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final reordered = [...activeItems];
                    final moved = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, moved);

                    final updated = [...reordered, ...boughtItems];
                    ref.read(wishlistControllerProvider.notifier).reorderItems(updated);
                  },
                  itemBuilder: (context, index) {
                    final item = activeItems[index];
                    return _buildWishlistItem(context, ref, item, isReorderable: true);
                  },
                ),
              ],
              if (boughtItems.isNotEmpty) ...[
                if (activeItems.isNotEmpty) const SizedBox(height: 24),
                _SectionHeader('BOUGHT', boughtTotal),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: boughtItems.length,
                  itemBuilder: (context, index) {
                    final item = boughtItems[index];
                    return _buildWishlistItem(context, ref, item, isReorderable: false);
                  },
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.destructive),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWishlistItem(BuildContext context, WidgetRef ref, WishlistItem item, {required bool isReorderable}) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.destructive.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showEditDialog(context, ref, item);
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(wishlistControllerProvider.notifier).deleteItem(item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          tileColor: AppColors.backgroundElevated,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: item.isBought,
              activeColor: AppColors.accentGold,
              checkColor: AppColors.backgroundPrimary,
              side: const BorderSide(color: AppColors.textSecondary),
              onChanged: (_) {
                ref.read(wishlistControllerProvider.notifier).toggleBought(item.id);
              },
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: item.isBought ? TextDecoration.lineThrough : null,
              color: item.isBought ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Added ${item.createdAt.toString().split(' ')[0]}',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LKR ${item.estimatedCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  color: item.isBought ? AppColors.textSecondary : AppColors.accentGold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: item.isBought ? TextDecoration.lineThrough : null,
                ),
              ),
              if (isReorderable) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.drag_handle,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final costController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundElevated,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            side: BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text(
            'ADD TO WISHLIST',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 1,
              color: AppColors.accentGold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'ITEM NAME',
                  labelStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentGold),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'ESTIMATED COST (LKR)',
                  labelStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentGold),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.backgroundPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final costStr = costController.text.trim();
                if (name.isNotEmpty && costStr.isNotEmpty) {
                  final cost = double.tryParse(costStr);
                  if (cost != null) {
                    ref.read(wishlistControllerProvider.notifier).addItem(name, cost);
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text(
                'ADD',
                style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, WishlistItem item) async {
    final nameController = TextEditingController(text: item.name);
    final costController = TextEditingController(text: item.estimatedCost.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundElevated,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            side: BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text(
            'EDIT WISHLIST ITEM',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 1,
              color: AppColors.accentGold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'ITEM NAME',
                  labelStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentGold),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'ESTIMATED COST (LKR)',
                  labelStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentGold),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: AppColors.backgroundPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final costStr = costController.text.trim();
                if (name.isNotEmpty && costStr.isNotEmpty) {
                  final cost = double.tryParse(costStr);
                  if (cost != null) {
                    ref.read(wishlistControllerProvider.notifier).editItem(item.id, name, cost);
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text(
                'SAVE',
                style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double total;
  const _SectionHeader(this.title, this.total);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
            color: AppColors.accentGold,
          ),
        ),
        Text(
          'LKR ${total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
