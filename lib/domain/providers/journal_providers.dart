import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/journal_entry.dart';
import '../../data/repositories/journal_repository.dart';
import 'goal_providers.dart'; // for isarProvider

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(ref.watch(isarProvider));
});

final journalEntryProvider = FutureProvider.family<JournalEntry?, DateTime>((ref, date) async {
  return ref.watch(journalRepositoryProvider).getEntryForDate(date);
});

final allJournalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  return ref.watch(journalRepositoryProvider).watchAllEntries();
});
