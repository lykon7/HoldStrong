import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../domain/models/custom_timer.dart';
import '../../../domain/providers/custom_timer_providers.dart';

class CustomTimersConfigDialog extends ConsumerStatefulWidget {
  const CustomTimersConfigDialog({super.key});

  @override
  ConsumerState<CustomTimersConfigDialog> createState() => _CustomTimersConfigDialogState();
}

class _CustomTimersConfigDialogState extends ConsumerState<CustomTimersConfigDialog> {

  Future<void> _showAddOrEditTimerDialog([CustomTimer? existing]) async {
    final titleCtrl = TextEditingController(text: existing?.title);
    DateTime targetDate = existing?.targetDate ?? DateTime.now();
    bool isCountdown = existing?.isCountdown ?? false;
    
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundElevated,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                side: BorderSide(color: AppColors.cardBorder),
              ),
              title: Text(existing == null ? 'ADD TIMER' : 'EDIT TIMER', style: const TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary),
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Timer Title',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Count Up (Time Since)', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textPrimary)),
                            value: false,
                            groupValue: isCountdown,
                            activeColor: AppColors.accentGold,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setStateDialog(() => isCountdown = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Count Down (Time Until)', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textPrimary)),
                            value: true,
                            groupValue: isCountdown,
                            activeColor: AppColors.accentGold,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setStateDialog(() => isCountdown = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 14),
                      label: Text(DateFormat('MMM d, yyyy - h:mm a').format(targetDate)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        textStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12),
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: targetDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.accentGold,
                                onPrimary: AppColors.backgroundPrimary,
                                surface: AppColors.backgroundElevated,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (date == null) return;
                        
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(targetDate),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.accentGold,
                                onPrimary: AppColors.backgroundPrimary,
                                surface: AppColors.backgroundElevated,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (time == null) return;
                        
                        setStateDialog(() {
                          targetDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing != null)
                  TextButton(
                    onPressed: () {
                      ref.read(customTimersProvider.notifier).deleteTimer(existing.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text('DELETE', style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.destructive)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL', style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim().toUpperCase();
                    if (title.isEmpty) return;
                    
                    if (existing == null) {
                      final newTimer = CustomTimer.create(title: title, targetDate: targetDate, isCountdown: isCountdown);
                      ref.read(customTimersProvider.notifier).addTimer(newTimer);
                    } else {
                      final updated = existing.copyWith(title: title, targetDate: targetDate, isCountdown: isCountdown);
                      ref.read(customTimersProvider.notifier).updateTimer(updated);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('SAVE', style: TextStyle(fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final timers = ref.watch(customTimersProvider);

    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      title: const Text('CUSTOM TIMERS',
          style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 1,
              color: AppColors.textPrimary)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: timers.isEmpty 
          ? const Center(child: Text('No custom timers configured.', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textSecondary)))
          : ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: timers.length,
              onReorder: (oldIndex, newIndex) {
                ref.read(customTimersProvider.notifier).reorderTimers(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final timer = timers[index];
                return ListTile(
                  key: ValueKey(timer.id),
                  contentPadding: EdgeInsets.zero,
                  title: Text(timer.title, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: AppColors.textPrimary)),
                  subtitle: Text(
                    '${timer.isCountdown ? "Countdown" : "Countup"} • ${DateFormat('MMM d, yyyy').format(timer.targetDate)}',
                    style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                  onTap: () => _showAddOrEditTimerDialog(timer),
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => _showAddOrEditTimerDialog(),
          child: const Text('ADD TIMER',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('DONE',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
