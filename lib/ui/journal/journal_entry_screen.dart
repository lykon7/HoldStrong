import 'dart:async';
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
  final _undoController = UndoHistoryController();
  JournalEntry? _existingEntry;
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _date = DateTime.parse(widget.dateString);
    _loadEntry();
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSave(isAutoSave: true);
    });
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

  Future<void> _performSave({bool isAutoSave = false}) async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _existingEntry == null) {
      if (!isAutoSave && mounted) Navigator.of(context).pop();
      return;
    }

    final repo = ref.read(journalRepositoryProvider);

    if (content.isEmpty && _existingEntry != null) {
      await repo.deleteEntry(_existingEntry!.uuid);
      _existingEntry = null;
    } else {
      final now = DateTime.now();
      if (_existingEntry == null) {
        _existingEntry = JournalEntry()
          ..uuid = const Uuid().v4()
          ..date = _date
          ..createdAt = now;
      } else {
        _existingEntry!.date = _date;
      }
      _existingEntry!.content = content;
      _existingEntry!.updatedAt = now;

      await repo.saveEntry(_existingEntry!);
    }

    if (!isAutoSave && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _contentController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
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

    if (picked != null && picked != _date) {
      final repo = ref.read(journalRepositoryProvider);
      final existingForNewDate = await repo.getEntryForDate(picked);

      if (existingForNewDate != null && existingForNewDate.uuid != _existingEntry?.uuid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An entry already exists for this date. Please select another date.'),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
        return;
      }

      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _selectDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateFmt.format(_date).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_calendar_outlined, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
        actions: [
          ValueListenableBuilder<UndoHistoryValue>(
            valueListenable: _undoController,
            builder: (context, value, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    onPressed: value.canUndo ? () => _undoController.undo() : null,
                    color: value.canUndo ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.5),
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    onPressed: value.canRedo ? () => _undoController.redo() : null,
                    color: value.canRedo ? AppColors.textPrimary : AppColors.textSecondary.withOpacity(0.5),
                  ),
                ],
              );
            },
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _performSave(isAutoSave: false),
            child: const Text(
              'DONE',
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
          : TextField(
              controller: _contentController,
              undoController: _undoController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              textCapitalization: TextCapitalization.sentences,
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 18,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
              ),
            ),
    );
  }
}
