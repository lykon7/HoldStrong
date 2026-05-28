import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/wishlist_providers.dart';
import '../../data/models/wishlist_item.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: wishlistAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No items in wishlist yet.\nAdd something you want to buy!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ReorderableListView.builder(
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) {
              // Flutter's ReorderableListView passes newIndex as if the old
              // item is already removed, so we adjust when moving downward.
              if (newIndex > oldIndex) newIndex -= 1;
              final reordered = [...items];
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              ref.read(wishlistControllerProvider.notifier).reorderItems(reordered);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: Colors.green.withOpacity(0.8),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red.withOpacity(0.8),
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
                child: ListTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Added ${item.createdAt.toString().split(' ')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LKR ${item.estimatedCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.drag_handle,
                        color: Colors.grey.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
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
          title: const Text('Add to Wishlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Estimated Cost'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
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
              child: const Text('ADD'),
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
          title: const Text('Edit Wishlist Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Estimated Cost'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
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
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}
