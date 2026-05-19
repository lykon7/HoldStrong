import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../domain/providers/journal_providers.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  Future<void> _pickDateAndGo(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGold,
              onPrimary: Colors.black,
              surface: AppColors.backgroundElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      context.push('/journal/$dateStr');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allJournalEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('JOURNAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Write Entry',
            onPressed: () => _pickDateAndGo(context),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mode_edit_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'NO ENTRIES YET.',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      letterSpacing: 1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _pickDateAndGo(context),
                    child: const Text(
                      'START WRITING',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final dateFmt = DateFormat('EEEE, d MMM yyyy');
              
              // Snippet for preview
              final preview = entry.content.length > 100 
                  ? '${entry.content.substring(0, 100)}...' 
                  : entry.content;

              return Dismissible(
                key: ValueKey(entry.uuid),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.withOpacity(0.8),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  ref.read(journalRepositoryProvider).deleteEntry(entry.uuid);
                },
                child: InkWell(
                  onTap: () {
                    final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);
                    context.push('/journal/$dateStr');
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFmt.format(entry.date).toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 10,
                            letterSpacing: 1.5,
                            color: AppColors.accentGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preview,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
