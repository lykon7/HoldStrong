import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../domain/providers/backup_provider.dart';
import '../../domain/providers/goal_providers.dart';
import '../../domain/providers/income_providers.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/fund_account.dart';
import '../../domain/providers/expense_providers.dart';
import '../../domain/providers/fund_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;

  // ─── Export ────────────────────────────────────────────────────────────────

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final service = ref.read(backupServiceProvider);
      final result = await service.export();
      if (!mounted) return;

      if (result.isSuccess) {
        await Share.shareXFiles(
          [XFile(result.file!.path)],
          subject: 'HoldStrong Backup',
        );
      } else {
        _showError('Export failed: ${result.error}');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ─── Import ────────────────────────────────────────────────────────────────

  Future<void> _import() async {
    final confirm = await _confirmImport();
    if (!confirm || !mounted) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) return;

    final path = picked.files.first.path;
    if (path == null) {
      _showError('Could not read the selected file.');
      return;
    }

    if (!path.endsWith('.hsbackup')) {
      _showError('Invalid file. Please select a .hsbackup file.');
      return;
    }

    setState(() => _importing = true);
    try {
      final service = ref.read(backupServiceProvider);
      final result = await service.importFile(File(path));
      if (!mounted) return;

      if (result.isSuccess) {
        _showImportSuccess(result.counts!);
      } else {
        _showError('Import failed: ${result.error}');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<bool> _confirmImport() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundElevated,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            title: const Text(
              'IMPORT BACKUP',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1,
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'New records from the backup will be merged into your existing data. '
              'Records you already have will not be changed or duplicated.',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL',
                    style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('PROCEED',
                    style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        color: AppColors.accentGold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showImportSuccess(Map<String, int> counts) {
    final total = counts.values.fold(0, (a, b) => a + b);
    final lines = [
      if (counts['goals'] != null && counts['goals']! > 0) '  ${counts['goals']} goal(s)',
      if (counts['resistEntries'] != null && counts['resistEntries']! > 0)
        '  ${counts['resistEntries']} resist log(s)',
      if (counts['cravingLabels'] != null && counts['cravingLabels']! > 0)
        '  ${counts['cravingLabels']} craving label(s)',
      if (counts['incomeEntries'] != null && counts['incomeEntries']! > 0)
        '  ${counts['incomeEntries']} income entr(ies)',
      if (counts['expenseEntries'] != null && counts['expenseEntries']! > 0)
        '  ${counts['expenseEntries']} expense(s)',
      if (counts['fundAccounts'] != null && counts['fundAccounts']! > 0)
        '  ${counts['fundAccounts']} fund account(s)',
      if (counts['recurringTransactions'] != null && counts['recurringTransactions']! > 0)
        '  ${counts['recurringTransactions']} recurring transaction(s)',
      if (counts['journalEntries'] != null && counts['journalEntries']! > 0)
        '  ${counts['journalEntries']} journal entry(ies)',
      if (counts['wishlist'] != null && counts['wishlist']! > 0)
        '  ${counts['wishlist']} wishlist item(s)',
      if (counts['liabilities'] != null && counts['liabilities']! > 0)
        '  ${counts['liabilities']} liability item(s)',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'IMPORT COMPLETE',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 1,
            color: Color(0xFF3DAA6E),
          ),
        ),
        content: Text(
          total == 0
              ? 'No new records found — your data is already up to date.'
              : '$total new record(s) imported:\n${lines.join('\n')}',
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontFamily: 'IBMPlexMono', fontSize: 12, color: AppColors.textPrimary)),
        backgroundColor: AppColors.backgroundElevated,
      ),
    );
  }

  // ─── Delete all ────────────────────────────────────────────────────────────

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'DELETE ALL DATA',
          style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              color: AppColors.destructive),
        ),
        content: const Text(
          'This will permanently delete every goal and every logged resist. There is no undo.',
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: AppColors.textPrimary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final isar = ref.read(isarProvider);
              await isar.writeTxn(() async {
                await isar.clear();
                await isar.fundAccounts.put(
                  FundAccount()
                    ..uuid = const Uuid().v4()
                    ..name = 'Cash'
                    ..openingBalance = 0.0
                    ..createdAt = DateTime.now(),
                );
              });
            },
            child: const Text('DELETE EVERYTHING',
                style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: AppColors.destructive)),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _showIncomeSourcesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _IncomeSourcesDialog(),
      ),
    );
  }

  void _showExpenseAccountsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _ExpenseAccountsConfig(),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // About
          _SectionHeader('ABOUT'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'HoldStrong is a discipline engine. Every craving you resist earns a brick in the wall of what you actually want. '
              'No cloud. No accounts. No telemetry. Your data lives on this device.',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('VERSION',
                    style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary)),
                Text('1.0.0',
                    style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const SizedBox(height: 32),

          // Preferences
          _SectionHeader('PREFERENCES'),
          const SizedBox(height: 8),

          _ActionTile(
            icon: Icons.category_outlined,
            label: 'INCOME SOURCES',
            sublabel: 'Configure default income source tags',
            loading: false,
            onTap: () => _showIncomeSourcesDialog(context, ref),
          ),

          const SizedBox(height: 8),

          _ActionTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'EXPENSE ACCOUNTS',
            sublabel: 'Configure which fund accounts are available for expenses',
            loading: false,
            onTap: () => _showExpenseAccountsDialog(context, ref),
          ),

          const SizedBox(height: 32),

          // Data backup
          _SectionHeader('DATA'),
          const SizedBox(height: 8),

          _ActionTile(
            icon: Icons.upload_outlined,
            label: 'EXPORT BACKUP',
            sublabel: 'Save a .hsbackup file with all your data',
            loading: _exporting,
            onTap: _export,
          ),

          const SizedBox(height: 8),

          _ActionTile(
            icon: Icons.download_outlined,
            label: 'IMPORT BACKUP',
            sublabel: 'Merge a .hsbackup file into your current data',
            loading: _importing,
            onTap: _import,
          ),

          const SizedBox(height: 8),
          const Text(
            'Import uses merge — existing records are never overwritten.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Danger zone
          _SectionHeader('DANGER ZONE'),
          const SizedBox(height: 8),

          GestureDetector(
            onTap: _confirmDeleteAll,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.destructive.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_outlined,
                      color: AppColors.destructive, size: 16),
                  SizedBox(width: 12),
                  Text(
                    'DELETE ALL DATA',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: AppColors.destructive,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Permanently deletes all goals and logged resists. Cannot be undone.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentGold, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.accentGold,
                ),
              )
            else
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _IncomeSourcesDialog extends ConsumerStatefulWidget {
  const _IncomeSourcesDialog();
  @override
  ConsumerState<_IncomeSourcesDialog> createState() => _IncomeSourcesDialogState();
}

class _IncomeSourcesDialogState extends ConsumerState<_IncomeSourcesDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(incomeSourcesProvider);
    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      title: const Text('INCOME SOURCES',
          style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 1,
              color: AppColors.textPrimary)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sources.map((src) {
                return Chip(
                  label: Text(src,
                      style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 12,
                          color: AppColors.textPrimary)),
                  backgroundColor: AppColors.backgroundSurface,
                  side: const BorderSide(color: AppColors.cardBorder),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  deleteIconColor: AppColors.textSecondary,
                  onDeleted: () {
                    ref.read(incomeSourcesProvider.notifier).removeSource(src);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 12,
                        color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'New source (e.g. DA)',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accentGold),
                  onPressed: () {
                    final text = _ctrl.text.trim().toUpperCase();
                    if (text.isNotEmpty) {
                      ref.read(incomeSourcesProvider.notifier).addSource(text);
                      _ctrl.clear();
                    }
                  },
                )
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('DONE',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
        ),
      ],
    );
  }
}

class _ExpenseAccountsConfig extends ConsumerWidget {
  const _ExpenseAccountsConfig();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAccounts = ref.watch(allFundAccountsProvider).value ?? [];
    final selectedAccounts = ref.watch(deductibleFundAccountsProvider);

    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      title: const Text('EXPENSE ACCOUNTS',
          style: TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 1,
              color: AppColors.textPrimary)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select which fund accounts are available to deduct from when logging an expense. If none are selected, all accounts will be shown by default.',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (allAccounts.isEmpty)
              const Text('No fund accounts exist.', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'IBMPlexMono', fontSize: 12))
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: allAccounts.length,
                itemBuilder: (ctx, i) {
                  final acc = allAccounts[i];
                  final isSelected = selectedAccounts.contains(acc.uuid);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.accentGold,
                    checkColor: AppColors.backgroundPrimary,
                    title: Text(acc.name, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14, color: AppColors.textPrimary)),
                    value: isSelected,
                    onChanged: (val) {
                      ref.read(deductibleFundAccountsProvider.notifier).toggleAccount(acc.uuid);
                    },
                  );
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('DONE',
              style: TextStyle(
                  fontFamily: 'IBMPlexMono', color: AppColors.accentGold)),
        ),
      ],
    );
  }
}
