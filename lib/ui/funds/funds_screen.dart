import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/fund_account.dart';
import '../../domain/providers/fund_providers.dart';

// Palette cycled for fund colours
const _kPalette = [
  Color(0xFF4A90D9), // blue
  Color(0xFF3DAA6E), // green
  Color(0xFF7B68EE), // purple
  Color(0xFFE8A838), // amber
  Color(0xFF2EC4B6), // teal
  Color(0xFFE05C5C), // rose
  Color(0xFF9B59B6), // violet
  Color(0xFF1ABC9C), // mint
];

class FundsScreen extends ConsumerWidget {
  const FundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(allFundAccountsProvider);
    final balances = ref.watch(fundBalancesProvider);
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('FUNDS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Fund',
            onPressed: () => _showAddFundSheet(context, ref),
          ),
        ],
      ),
      body: accounts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accountList) {
          if (accountList.isEmpty) {
            return const _EmptyState();
          }

          // Assign colours by index
          final colours = List.generate(
              accountList.length,
              (i) => _kPalette[i % _kPalette.length]);

          // Build segments (only positive balances count toward the chart)
          final segments = <_DonutSegment>[];
          for (int i = 0; i < accountList.length; i++) {
            final bal = balances[accountList[i].uuid] ?? 0.0;
            if (bal > 0) {
              segments.add(_DonutSegment(
                  label: accountList[i].name,
                  value: bal,
                  color: colours[i]));
            }
          }

          final totalBalance = balances.values
              .where((v) => v > 0)
              .fold<double>(0.0, (s, v) => s + v);

          return Column(
            children: [
              // Donut chart header
              _DonutChart(
                segments: segments,
                total: totalBalance,
                fmt: fmt,
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: accountList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final acc = accountList[index];
                    final balance = balances[acc.uuid] ?? 0.0;
                    return _FundCard(
                      account: acc,
                      balance: balance,
                      fmt: fmt,
                      color: colours[index],
                      onDelete: () => ref
                          .read(fundRepositoryProvider)
                          .deleteAccount(acc.uuid),
                      onEdit: () => _showEditFundSheet(context, ref, acc),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFundSheet(context, ref),
        backgroundColor: const Color(0xFF4A90D9),
        foregroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddFundSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _AddFundSheet(),
      ),
    );
  }

  void _showEditFundSheet(
      BuildContext context, WidgetRef ref, FundAccount account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _EditFundSheet(account: account),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fund card with swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────

class _FundCard extends StatelessWidget {
  const _FundCard({
    required this.account,
    required this.balance,
    required this.fmt,
    required this.color,
    required this.onDelete,
    required this.onEdit,
  });

  final FundAccount account;
  final double balance;
  final NumberFormat fmt;
  final Color color;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final balanceColor =
        isPositive ? const Color(0xFF3DAA6E) : AppColors.destructive;

    return Dismissible(
      key: ValueKey(account.uuid),
      direction: DismissDirection.horizontal,
      // Swipe right = edit
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withOpacity(0.15),
          border: Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Icon(Icons.edit_outlined,
            color: AppColors.accentBlue, size: 20),
      ),
      // Swipe left = delete
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.destructive.withOpacity(0.15),
          border:
              Border.all(color: AppColors.destructive.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Icon(Icons.delete_outline,
            color: AppColors.destructive, size: 20),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundElevated,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            title: const Text(
              'DELETE FUND?',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1,
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'Linked income and expense entries will remain but will no longer affect this fund\'s balance.',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('DELETE',
                    style: TextStyle(color: AppColors.destructive)),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            // Coloured icon box matching chart segment
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(
                account.name.toLowerCase() == 'cash'
                    ? Icons.account_balance_wallet_outlined
                    : Icons.savings_outlined,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            // Name
            Expanded(
              child: Text(
                account.name,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${fmt.format(balance.abs())}',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: balanceColor,
                  ),
                ),
                if (balance < 0)
                  const Text(
                    'OVERDRAWN',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: AppColors.destructive,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings_outlined,
              size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'NO FUND ACCOUNTS.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 12,
              letterSpacing: 2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to add Cash, Bank, or any source.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add fund bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Donut chart
// ─────────────────────────────────────────────────────────────────────────────

class _DonutSegment {
  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.segments,
    required this.total,
    required this.fmt,
  });

  final List<_DonutSegment> segments;
  final double total;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundPrimary,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Donut ring
              CustomPaint(
                size: const Size(240, 240),
                painter: _DonutPainter(
                  segments: segments,
                  total: total,
                ),
              ),
              // Centre text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${fmt.format(total)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (segments.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: segments.map((s) {
                        final pct =
                            total > 0 ? (s.value / total * 100) : 0.0;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 8,
                                color: s.color,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.total});

  final List<_DonutSegment> segments;
  final double total;

  static const _strokeWidth = 22.0;
  static const _gap = 0.03; // radians gap between segments

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (_strokeWidth / 2) - 2;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.cardBorder.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(centre, radius, trackPaint);

    if (total <= 0 || segments.isEmpty) return;

    final totalGap = _gap * segments.length;
    final availableAngle = 2 * math.pi - totalGap;

    double startAngle = -math.pi / 2; // start from top

    for (final seg in segments) {
      final sweep = (seg.value / total) * availableAngle;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweep, false, paint);

      // Subtle inner glow
      final glowPaint = Paint()
        ..color = seg.color.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(rect, startAngle, sweep, false, glowPaint);

      startAngle += sweep + _gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments || old.total != total;
}


class _AddFundSheet extends ConsumerStatefulWidget {
  const _AddFundSheet();

  @override
  ConsumerState<_AddFundSheet> createState() => _AddFundSheetState();
}

class _AddFundSheetState extends ConsumerState<_AddFundSheet> {
  final _nameCtrl = TextEditingController();
  final _openingBalanceCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _uuid = const Uuid();
  bool _saving = false;

  // Quick-pick suggestions
  static const _suggestions = ['Cash', 'Bank', 'Bank 2', 'Bank 3', 'Wallet'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _openingBalanceCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final openingBalance =
        double.tryParse(_openingBalanceCtrl.text.trim()) ?? 0.0;
    setState(() => _saving = true);

    final account = FundAccount()
      ..uuid = _uuid.v4()
      ..name = name
      ..openingBalance = openingBalance
      ..createdAt = DateTime.now();

    await ref.read(fundRepositoryProvider).saveAccount(account);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'ADD FUND',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetLabel('SUGGESTIONS'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((s) {
                    final isSelected = _nameCtrl.text == s;
                    return GestureDetector(
                      onTap: () => setState(() => _nameCtrl.text = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4A90D9).withOpacity(0.15)
                              : AppColors.backgroundElevated,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4A90D9)
                                : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            letterSpacing: 1,
                            color: isSelected
                                ? const Color(0xFF4A90D9)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const _SheetLabel('FUND NAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Cash, Bank, Savings...',
                  ),
                ),
                const SizedBox(height: 20),

                // Opening balance
                const _SheetLabel('CURRENT BALANCE (LKR)'),
                const SizedBox(height: 4),
                const Text(
                  'Set the initial current balance. Does not appear in income logs.',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _openingBalanceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixText: 'RS  ',
                    prefixStyle: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.backgroundPrimary,
                          ),
                        )
                      : const Text('CREATE FUND'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
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

// ─────────────────────────────────────────────────────────────────────────────
// Edit fund bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditFundSheet extends ConsumerStatefulWidget {
  const _EditFundSheet({required this.account});
  final FundAccount account;

  @override
  ConsumerState<_EditFundSheet> createState() => _EditFundSheetState();
}

class _EditFundSheetState extends ConsumerState<_EditFundSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _openingBalanceCtrl;
  bool _saving = false;

  static const _suggestions = ['Cash', 'Bank', 'Bank 2', 'Bank 3', 'Wallet'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account.name);
    
    // Initialise text field with current balance, not raw opening balance
    final currentBalance = ref.read(fundBalancesProvider)[widget.account.uuid] ?? widget.account.openingBalance;
    _openingBalanceCtrl = TextEditingController(
        text: currentBalance == 0
            ? ''
            : currentBalance.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _openingBalanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    
    final targetBalance =
        double.tryParse(_openingBalanceCtrl.text.trim()) ?? 0.0;
    setState(() => _saving = true);

    // Calculate new underlying opening balance to achieve the target current balance
    final currentBalance = ref.read(fundBalancesProvider)[widget.account.uuid] ?? widget.account.openingBalance;
    final netTransactions = currentBalance - widget.account.openingBalance;
    final newOpeningBalance = targetBalance - netTransactions;

    await ref.read(fundRepositoryProvider).updateAccount(
          uuid: widget.account.uuid,
          name: name,
          openingBalance: newOpeningBalance,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, keyboardHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'EDIT FUND',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetLabel('SUGGESTIONS'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions.map((s) {
                    final isSelected = _nameCtrl.text == s;
                    return GestureDetector(
                      onTap: () => setState(() => _nameCtrl.text = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4A90D9).withOpacity(0.15)
                              : AppColors.backgroundElevated,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4A90D9)
                                : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontSize: 12,
                            letterSpacing: 1,
                            color: isSelected
                                ? const Color(0xFF4A90D9)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const _SheetLabel('FUND NAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Cash, Bank, Savings...',
                  ),
                ),
                const SizedBox(height: 20),
                const _SheetLabel('CURRENT BALANCE (LKR)'),
                const SizedBox(height: 4),
                const Text(
                  'Adjust the current total balance. This overrides past transactions to match your input.',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _openingBalanceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixText: 'RS  ',
                    prefixStyle: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90D9),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.backgroundPrimary,
                          ),
                        )
                      : const Text('SAVE CHANGES'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
