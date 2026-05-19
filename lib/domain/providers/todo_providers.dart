import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/todo_item.dart';
import 'goal_providers.dart'; // To access isarProvider

final todoProvider = StreamProvider<List<TodoItem>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.todoItems.where().watch(fireImmediately: true).map((items) {
    // Sort logic: Incomplete first, then by deadline (earliest first), then by creation date.
    final incomplete = items.where((i) => !i.isCompleted).toList();
    final completed = items.where((i) => i.isCompleted).toList();

    incomplete.sort((a, b) {
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      } else if (a.deadline != null) {
        return -1;
      } else if (b.deadline != null) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return [...incomplete, ...completed];
  });
});

class TodoNotifier extends StateNotifier<AsyncValue<void>> {
  final Isar _isar;

  TodoNotifier(this._isar) : super(const AsyncData(null));

  Future<void> addTodo(String title, DateTime? deadline) async {
    state = const AsyncLoading();
    try {
      final item = TodoItem()
        ..title = title
        ..deadline = deadline
        ..createdAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.todoItems.put(item);
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleCompletion(Id id) async {
    state = const AsyncLoading();
    try {
      await _isar.writeTxn(() async {
        final item = await _isar.todoItems.get(id);
        if (item != null) {
          item.isCompleted = !item.isCompleted;
          await _isar.todoItems.put(item);
        }
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTodo(Id id) async {
    state = const AsyncLoading();
    try {
      await _isar.writeTxn(() async {
        await _isar.todoItems.delete(id);
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final todoControllerProvider = StateNotifierProvider<TodoNotifier, AsyncValue<void>>((ref) {
  final isar = ref.watch(isarProvider);
  return TodoNotifier(isar);
});
