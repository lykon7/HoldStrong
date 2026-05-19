import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/wishlist_providers.dart';

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

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.withOpacity(0.8),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(wishlistControllerProvider.notifier).deleteItem(item.id);
                },
                child: ListTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Added ${item.createdAt.toString().split(' ')[0]}'),
                  trailing: Text(
                    '\$${item.estimatedCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
}
