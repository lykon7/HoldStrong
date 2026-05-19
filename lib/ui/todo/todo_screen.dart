import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/todo_providers.dart';
import '../../data/models/todo_item.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
      ),
      body: todoAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No tasks yet.\nAdd something to do!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isOverdue = item.deadline != null &&
                  !item.isCompleted &&
                  item.deadline!.isBefore(DateTime.now());

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
                    ref.read(todoControllerProvider.notifier).deleteTodo(item.id);
                  }
                },
                child: CheckboxListTile(
                  value: item.isCompleted,
                  onChanged: (_) {
                    ref.read(todoControllerProvider.notifier).toggleCompletion(item.id);
                  },
                  title: Text(
                    item.title,
                    style: TextStyle(
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      color: item.isCompleted ? Colors.grey : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: item.deadline != null
                      ? Text(
                          'Deadline: ${DateFormat('MMM dd, h:mm a').format(item.deadline!)}',
                          style: TextStyle(
                            color: isOverdue ? Colors.redAccent : Colors.grey,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        )
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
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
    final titleController = TextEditingController();
    DateTime? selectedDeadline;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Deadline (Optional)'),
                    subtitle: Text(
                      selectedDeadline == null
                          ? 'None'
                          : DateFormat('MMM dd, yyyy - h:mm a').format(selectedDeadline!),
                      style: TextStyle(
                          color: selectedDeadline != null ? Colors.blueAccent : Colors.grey),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDeadline = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
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
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      ref.read(todoControllerProvider.notifier).addTodo(title, selectedDeadline);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, TodoItem item) async {
    final titleController = TextEditingController(text: item.title);
    DateTime? selectedDeadline = item.deadline;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Deadline (Optional)'),
                    subtitle: Text(
                      selectedDeadline == null
                          ? 'None'
                          : DateFormat('MMM dd, yyyy - h:mm a').format(selectedDeadline!),
                      style: TextStyle(
                          color: selectedDeadline != null ? Colors.blueAccent : Colors.grey),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDeadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedDeadline != null 
                              ? TimeOfDay.fromDateTime(selectedDeadline!) 
                              : TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDeadline = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
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
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      ref.read(todoControllerProvider.notifier).editTodo(item.id, title, selectedDeadline);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
