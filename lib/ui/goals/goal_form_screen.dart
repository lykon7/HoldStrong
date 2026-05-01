import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/models/goal.dart';
import '../../domain/providers/goal_providers.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goalUuid});

  final String? goalUuid;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _milestoneCtrl = TextEditingController();
  final _uuid = const Uuid();

  GoalType _type = GoalType.financial;
  DateTime? _targetDate;
  bool _saving = false;
  Goal? _existing;

  bool get _isEditing => widget.goalUuid != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(goalRepositoryProvider);
    final goal = await repo.getGoalByUuid(widget.goalUuid!);
    if (goal != null && mounted) {
      setState(() {
        _existing = goal;
        _nameCtrl.text = goal.name;
        _targetCtrl.text = goal.targetAmountLkr.toStringAsFixed(0);
        _type = goal.type;
        _targetDate = goal.targetDate;
        _milestoneCtrl.text = goal.fitnessMilestone ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _milestoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(goalRepositoryProvider);
    final activeGoal = await ref.read(activeGoalProvider.future);

    final goal = _existing ?? Goal();
    goal
      ..uuid = _existing?.uuid ?? _uuid.v4()
      ..name = _nameCtrl.text.trim()
      ..type = _type
      ..targetAmountLkr = double.parse(_targetCtrl.text.trim())
      ..fitnessMilestone = _type == GoalType.fitnessFinancial &&
              _milestoneCtrl.text.trim().isNotEmpty
          ? _milestoneCtrl.text.trim()
          : null
      ..targetDate = _targetDate
      ..createdAt = _existing?.createdAt ?? DateTime.now()
      ..isActive = _existing?.isActive ?? activeGoal == null
      ..isCompleted = _existing?.isCompleted ?? false;

    await repo.saveGoal(goal);

    // Auto-set as active if first goal
    if (activeGoal == null) {
      await repo.setActiveGoal(goal.uuid);
    }

    if (!mounted) return;
    context.pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
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
    if (picked != null) setState(() => _targetDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(_isEditing ? 'EDIT GOAL' : 'NEW GOAL'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Goal name
                  _Label('GOAL NAME'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Motorcycle, Emergency fund...',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Goal type
                  _Label('GOAL TYPE'),
                  const SizedBox(height: 8),
                  _TypeToggle(
                    selected: _type,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: 20),

                  // Target amount
                  _Label('TARGET AMOUNT (LKR)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: AppColors.accentGold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixText: 'RS  ',
                      prefixStyle: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Amount required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid amount';
                      if (double.parse(v.trim()) <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Target date (optional)
                  _Label('TARGET DATE (optional)'),
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
                            _targetDate != null
                                ? dateFmt.format(_targetDate!)
                                : 'No target date set',
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 12,
                              color: _targetDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (_targetDate != null) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _targetDate = null),
                              child: const Icon(Icons.close,
                                  size: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fitness milestone (only for fitness type)
                  if (_type == GoalType.fitnessFinancial) ...[
                    _Label('FITNESS MILESTONE (optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _milestoneCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Get back to 72kg...',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
                    : Text(_isEditing ? 'SAVE CHANGES' : 'CREATE GOAL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
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

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selected, required this.onChanged});

  final GoalType selected;
  final void Function(GoalType) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleChip(
          label: 'FINANCIAL',
          active: selected == GoalType.financial,
          onTap: () => onChanged(GoalType.financial),
        ),
        const SizedBox(width: 10),
        _ToggleChip(
          label: 'FITNESS',
          active: selected == GoalType.fitnessFinancial,
          onTap: () => onChanged(GoalType.fitnessFinancial),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.accentBlue : Colors.transparent,
          border: Border.all(
            color: active ? AppColors.accentGold : AppColors.accentBlue,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 11,
            letterSpacing: 1.5,
            color: active ? AppColors.accentGold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
