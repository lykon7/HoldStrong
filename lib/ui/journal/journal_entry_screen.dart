import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/journal_entry.dart';
import '../../domain/providers/journal_providers.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key, required this.dateString});

  final String dateString;

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  late DateTime _date;
  final _contentController = TextEditingController();
  JournalEntry? _existingEntry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _date = DateTime.parse(widget.dateString);
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    final entry = await ref.read(journalRepositoryProvider).getEntryForDate(_date);
    if (entry != null && mounted) {
      setState(() {
        _existingEntry = entry;
        _contentController.text = entry.content;
      });
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEntry() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _existingEntry == null) {
      Navigator.of(context).pop();
      return;
    }

    final repo = ref.read(journalRepositoryProvider);

    if (content.isEmpty && _existingEntry != null) {
      // Delete if content cleared
      await repo.deleteEntry(_existingEntry!.uuid);
    } else {
      final now = DateTime.now();
      final entryToSave = _existingEntry ?? JournalEntry()
        ..uuid = const Uuid().v4()
        ..date = _date
        ..createdAt = now;

      entryToSave.content = content;
      entryToSave.updatedAt = now;

      await repo.saveEntry(entryToSave);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(dateFmt.format(_date).toUpperCase()),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: const Text(
              'SAVE',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                color: AppColors.accentGold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
    );
  }
}
