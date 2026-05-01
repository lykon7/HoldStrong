import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/message_bank.dart';
import '../../core/calorie_library.dart';
import '../../data/models/resist_entry.dart';
import '../../data/models/goal.dart';
import '../../domain/models/celebration_data.dart';
import '../../domain/providers/goal_providers.dart';
import '../../domain/providers/resist_providers.dart';
import '../../domain/providers/label_providers.dart';
import 'widgets/label_chips.dart';
import 'widgets/calorie_input.dart';

class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  final _amountCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _calorieCtrl = TextEditingController();
  final _amountFocus = FocusNode();
  final _uuid = const Uuid();

  DateTime _loggedAt = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus amount field on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
    _labelCtrl.addListener(_onLabelChanged);
  }

  void _onLabelChanged() {
    final cal = CalorieLibrary.getSuggestion(_labelCtrl.text);
    if (cal != null && _calorieCtrl.text.isEmpty) {
      _calorieCtrl.text = cal.toString();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _labelCtrl.dispose();
    _calorieCtrl.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty) return;
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);

    final activeGoal = await ref.read(activeGoalProvider.future);
    if (activeGoal == null || !mounted) {
      setState(() => _saving = false);
      return;
    }

    final label = _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim();
    final caloriesStr = _calorieCtrl.text.trim();
    final calories = caloriesStr.isEmpty ? null : int.tryParse(caloriesStr);

    final entry = ResistEntry()
      ..uuid = _uuid.v4()
      ..goalUuid = activeGoal.uuid
      ..amountLkr = amount
      ..label = label
      ..caloriesAvoided = calories
      ..loggedAt = _loggedAt;

    final resistRepo = ref.read(resistRepositoryProvider);
    await resistRepo.saveEntry(entry);

    if (label != null) {
      await ref.read(labelRepositoryProvider).recordLabelUse(label, defaultCalories: calories);
    }

    // Build celebration data
    final totalSaved = await resistRepo.getTotalSavedForGoal(activeGoal.uuid);
    final progressPct = activeGoal.targetAmountLkr > 0
        ? (totalSaved / activeGoal.targetAmountLkr * 100).clamp(0.0, 100.0)
        : 0.0;

    final allEntries = await resistRepo.getAllEntriesForGoal(activeGoal.uuid);
    final streak = _calcStreak(allEntries.map((e) => e.loggedAt).toList());

    final fmt = NumberFormat('#,##0', 'en_US');
    final message = activeGoal.type == GoalType.fitnessFinancial
        ? MessageBank.pickFitnessFinancial(
            amount: fmt.format(amount),
            goal: activeGoal.name,
            progress: progressPct.toStringAsFixed(1),
            streak: streak.toString(),
            calories: calories?.toString() ?? '0',
          )
        : MessageBank.pickFinancial(
            amount: fmt.format(amount),
            goal: activeGoal.name,
            progress: progressPct.toStringAsFixed(1),
            streak: streak.toString(),
          );

    // Monthly calories for fitness
    int? totalCaloriesThisMonth;
    if (activeGoal.type == GoalType.fitnessFinancial) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      totalCaloriesThisMonth = allEntries
          .where((e) => e.loggedAt.isAfter(monthStart) && e.caloriesAvoided != null)
          .fold<int>(0, (s, e) => s + (e.caloriesAvoided ?? 0));
    }

    final celebData = CelebrationData(
      amountSaved: amount,
      goalName: activeGoal.name,
      goalType: activeGoal.type,
      progressPct: progressPct,
      totalSaved: totalSaved,
      targetAmount: activeGoal.targetAmountLkr,
      streakDays: streak,
      message: message,
      caloriesAvoided: calories,
      totalCaloriesThisMonth: totalCaloriesThisMonth,
      fitnessMilestone: activeGoal.fitnessMilestone,
    );

    if (!mounted) return;
    context.pushReplacement('/celebration', extra: celebData);
  }

  int _calcStreak(List<DateTime> timestamps) {
    if (timestamps.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = timestamps
        .map((t) => DateTime(t.year, t.month, t.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (days.first.difference(today).inDays.abs() > 1) return 0;
    int streak = 1;
    for (int i = 0; i < days.length - 1; i++) {
      if (days[i].difference(days[i + 1]).inDays == 1) streak++;
      else break;
    }
    return streak;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentGold,
            surface: AppColors.backgroundElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _loggedAt = DateTime(
          picked.year, picked.month, picked.day,
          _loggedAt.hour, _loggedAt.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGoal = ref.watch(activeGoalProvider).value;
    final isFitness = activeGoal?.type == GoalType.fitnessFinancial;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('LOG A RESIST'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount input — large and dominant
                  _SectionLabel('AMOUNT SAVED (LKR)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 42,
                      color: AppColors.accentGold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w700,
                        fontSize: 42,
                        color: AppColors.textSecondary,
                      ),
                      prefixText: 'RS  ',
                      prefixStyle: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w600,
                        fontSize: 28,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Label chips
                  _SectionLabel('WHAT WAS THE CRAVING? (optional)'),
                  const SizedBox(height: 8),
                  LabelChips(
                    onSelected: (name, calories) {
                      _labelCtrl.text = name;
                      if (calories != null && _calorieCtrl.text.isEmpty) {
                        _calorieCtrl.text = calories.toString();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. KFC, bubble tea...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Calorie input (fitness goals only)
                  if (isFitness) ...[
                    _SectionLabel('CALORIES AVOIDED (optional)'),
                    const SizedBox(height: 8),
                    CalorieInput(
                      controller: _calorieCtrl,
                      labelController: _labelCtrl,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Date/time
                  _SectionLabel('DATE'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSurface,
                        border: Border.all(color: AppColors.accentBlue),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            dateFmt.format(_loggedAt),
                            style: const TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm button pinned at bottom
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.backgroundPrimary,
                      ),
                    )
                  : const Text('CONFIRM'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 10,
        letterSpacing: 2,
        color: AppColors.textSecondary,
      ),
    );
  }
}
