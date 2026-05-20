import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/liability_item.dart';
import '../../data/repositories/liability_repository.dart';
import 'goal_providers.dart'; // exposes isarProvider

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final liabilityRepositoryProvider = Provider<LiabilityRepository>((ref) {
  return LiabilityRepository(ref.watch(isarProvider));
});

// ---------------------------------------------------------------------------
// Stream provider — all active (non-archived) liabilities
// ---------------------------------------------------------------------------

final allLiabilitiesProvider = StreamProvider<List<LiabilityItem>>((ref) {
  return ref.watch(liabilityRepositoryProvider).watchAll();
});

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class LiabilityNotifier extends StateNotifier<AsyncValue<void>> {
  final LiabilityRepository _repo;

  LiabilityNotifier(this._repo) : super(const AsyncData(null));

  Future<void> add(LiabilityItem item) async {
    state = const AsyncLoading();
    try {
      await _repo.save(item);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Creates N individual instalment entries for a BNPL liability.
  Future<void> addBnplInstalments({
    required String title,
    required double amount,
    required DateTime startDate,
    required int count,
    required LiabilityFrequency frequency,
    String? notes,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.saveBnplInstalments(
        title: title,
        amount: amount,
        startDate: startDate,
        count: count,
        frequency: frequency,
        notes: notes,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> edit(LiabilityItem item) async {
    state = const AsyncLoading();
    try {
      await _repo.update(item);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String uuid) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(uuid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markPaid(String uuid) async {
    state = const AsyncLoading();
    try {
      await _repo.markPaid(uuid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final liabilityControllerProvider =
    StateNotifierProvider<LiabilityNotifier, AsyncValue<void>>((ref) {
  return LiabilityNotifier(ref.watch(liabilityRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Derived: totals
// ---------------------------------------------------------------------------

/// Total amount of all unpaid liabilities across ALL time (every future entry).
final totalOutstandingLiabilityProvider = Provider<double>((ref) {
  final async = ref.watch(allLiabilitiesProvider);
  return async.when(
    data: (items) => items
        .where((i) => !i.isPaid)
        .fold(0.0, (sum, i) => sum + i.amount),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Total amount of unpaid liabilities due this calendar month.
final monthlyLiabilityTotalProvider = Provider<double>((ref) {
  final async = ref.watch(allLiabilitiesProvider);
  return async.when(
    data: (items) {
      final now = DateTime.now();
      return items
          .where((i) =>
              !i.isPaid &&
              i.dueDate.year == now.year &&
              i.dueDate.month == now.month)
          .fold(0.0, (sum, i) => sum + i.amount);
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// ---------------------------------------------------------------------------
// Derived: sections
// ---------------------------------------------------------------------------

/// Liabilities that are overdue (due date before today, not paid).
final overdueProvider = Provider<List<LiabilityItem>>((ref) {
  final async = ref.watch(allLiabilitiesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return async.when(
    data: (items) =>
        items.where((i) => !i.isPaid && i.dueDate.isBefore(today)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Liabilities due within the next 7 days (inclusive of today, not overdue).
final dueThisWeekProvider = Provider<List<LiabilityItem>>((ref) {
  final async = ref.watch(allLiabilitiesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final in7 = today.add(const Duration(days: 7));
  return async.when(
    data: (items) => items
        .where((i) =>
            !i.isPaid &&
            !i.dueDate.isBefore(today) &&
            !i.dueDate.isAfter(in7))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Liabilities due between day 8 and day 30 from today.
final dueThisMonthProvider = Provider<List<LiabilityItem>>((ref) {
  final async = ref.watch(allLiabilitiesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final in7 = today.add(const Duration(days: 7));
  final in30 = today.add(const Duration(days: 30));
  return async.when(
    data: (items) => items
        .where((i) =>
            !i.isPaid &&
            i.dueDate.isAfter(in7) &&
            !i.dueDate.isAfter(in30))
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Liabilities due beyond 30 days from today.
final upcomingProvider = Provider<List<LiabilityItem>>((ref) {
  final async = ref.watch(allLiabilitiesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final in30 = today.add(const Duration(days: 30));
  return async.when(
    data: (items) =>
        items.where((i) => !i.isPaid && i.dueDate.isAfter(in30)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
