import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/fund_account.dart';
import '../../data/models/account_transfer.dart';
import '../../domain/providers/fund_providers.dart';
import '../../domain/providers/account_transfer_providers.dart';

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

class FundsScreen extends ConsumerStatefulWidget {
  const FundsScreen({super.key});

  @override
  ConsumerState<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends ConsumerState<FundsScreen> {
  int _selectedTab = 0; // 0 = Accounts, 1 = Transfers

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allFundAccountsProvider);
    final balances = ref.watch(fundBalancesProvider);
    final transfersAsync = ref.watch(allAccountTransfersProvider);
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('FUNDS'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 22),
            tooltip: 'Transfer Funds',
            onPressed: () => _showTransferSheet(context, ref),
          ),
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
              // Segmented switch / tab bar
              Container(
                color: AppColors.backgroundSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'ACCOUNTS (${accountList.length})',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TabButton(
                        label: 'TRANSFERS',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _selectedTab == 0
                    ? ListView.separated(
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
                      )
                    : transfersAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.accentGold),
                        ),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (transferList) {
                          if (transferList.isEmpty) {
                            return const _TransfersEmptyState();
                          }
                          final accountMap = {for (var a in accountList) a.uuid: a};
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: transferList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final t = transferList[index];
                              return _TransferCard(
                                transfer: t,
                                fromAccount: accountMap[t.fromFundUuid],
                                toAccount: accountMap[t.toFundUuid],
                                fmt: fmt,
                                onDelete: () => ref
                                    .read(accountTransferRepositoryProvider)
                                    .deleteTransfer(t.uuid),
                                onEdit: () => _showEditTransferSheet(context, ref, t),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: null,
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

  void _showTransferSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _TransferSheet(),
      ),
    );
  }

  void _showEditTransferSheet(
      BuildContext context, WidgetRef ref, AccountTransfer transfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _EditTransferSheet(transfer: transfer),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab Button
// ─────────────────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : AppColors.cardBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1.2,
            color: isSelected ? AppColors.accentGold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transfers Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _TransfersEmptyState extends StatelessWidget {
  const _TransfersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'NO RECENT TRANSFERS',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Move funds between accounts easily.\nTap the ⇄ icon in the top right to start a transfer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transfer Card
// ─────────────────────────────────────────────────────────────────────────────

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    required this.fromAccount,
    required this.toAccount,
    required this.fmt,
    required this.onDelete,
    required this.onEdit,
  });

  final AccountTransfer transfer;
  final FundAccount? fromAccount;
  final FundAccount? toAccount;
  final NumberFormat fmt;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final fromName = fromAccount?.name ?? 'Unknown Account';
    final toName = toAccount?.name ?? 'Unknown Account';

    return Dismissible(
      key: Key('transfer-${transfer.uuid}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.backgroundSurface,
              title: const Text(
                'DELETE TRANSFER?',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              content: const Text(
                'Deleting will reverse this transfer and adjust both account balances accordingly.',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                  ),
                  child: const Text('DELETE'),
                ),
              ],
            ),
          );
        } else if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        }
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF4A90D9)),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.edit, color: Color(0xFF4A90D9)),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: AppColors.destructive.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.destructive),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: AppColors.destructive),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF4A90D9)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.swap_horiz,
                color: Color(0xFF4A90D9),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          fromName,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          toName,
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (transfer.note != null && transfer.note!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      transfer.note!,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RS ${fmt.format(transfer.amount)}',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF4A90D9),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d MMM, HH:mm').format(transfer.transferAt),
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    color: AppColors.textSecondary,
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
// Transfer Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TransferSheet extends ConsumerStatefulWidget {
  const _TransferSheet();

  @override
  ConsumerState<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<_TransferSheet> {
  String? _fromFundUuid;
  String? _toFundUuid;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _initAccounts(List<FundAccount> accounts) {
    if (_fromFundUuid == null && accounts.isNotEmpty) {
      _fromFundUuid = accounts[0].uuid;
      if (accounts.length > 1) {
        _toFundUuid = accounts[1].uuid;
      }
    }
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ENTER A VALID AMOUNT'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    if (_fromFundUuid == null || _toFundUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SELECT SOURCE AND DESTINATION ACCOUNTS'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    if (_fromFundUuid == _toFundUuid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CANNOT TRANSFER TO THE SAME ACCOUNT'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final transfer = AccountTransfer()
        ..uuid = const Uuid().v4()
        ..fromFundUuid = _fromFundUuid!
        ..toFundUuid = _toFundUuid!
        ..amount = amt
        ..note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()
        ..transferAt = DateTime.now();

      await ref.read(accountTransferRepositoryProvider).saveTransfer(transfer);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allFundAccountsProvider).value ?? [];
    final balances = ref.watch(fundBalancesProvider);
    final fmt = NumberFormat('#,##0.00', 'en_US');

    _initAccounts(accounts);

    if (accounts.length < 2) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.accentGold),
            const SizedBox(height: 16),
            const Text(
              'MORE ACCOUNTS NEEDED',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You need at least 2 fund accounts created to transfer funds between them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GOT IT'),
            ),
          ],
        ),
      );
    }

    final fromBalance = balances[_fromFundUuid] ?? 0.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRANSFER FUNDS',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // From Account Selector
          const Text(
            'FROM ACCOUNT',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _fromFundUuid,
            dropdownColor: AppColors.backgroundSurface,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: accounts.map((acc) {
              final bal = balances[acc.uuid] ?? 0.0;
              return DropdownMenuItem(
                value: acc.uuid,
                child: Text('${acc.name} (RS ${fmt.format(bal)})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _fromFundUuid = val;
                  if (_toFundUuid == val) {
                    final other = accounts.firstWhere((a) => a.uuid != val, orElse: () => accounts.first);
                    _toFundUuid = other.uuid != val ? other.uuid : null;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          // To Account Selector
          const Text(
            'TO ACCOUNT',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _toFundUuid,
            dropdownColor: AppColors.backgroundSurface,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: accounts.where((acc) => acc.uuid != _fromFundUuid).map((acc) {
              final bal = balances[acc.uuid] ?? 0.0;
              return DropdownMenuItem(
                value: acc.uuid,
                child: Text('${acc.name} (RS ${fmt.format(bal)})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _toFundUuid = val);
              }
            },
          ),
          const SizedBox(height: 16),
          // Amount & Quick buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AMOUNT (LKR)',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'AVAIL: RS ${fmt.format(fromBalance)}',
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10,
                  color: Color(0xFF4A90D9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 15,
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
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(label: '25%', onTap: () {
                  _amountCtrl.text = (fromBalance * 0.25).toStringAsFixed(2);
                }),
                const SizedBox(width: 6),
                _QuickChip(label: '50%', onTap: () {
                  _amountCtrl.text = (fromBalance * 0.50).toStringAsFixed(2);
                }),
                const SizedBox(width: 6),
                _QuickChip(label: 'MAX', onTap: () {
                  _amountCtrl.text = fromBalance.toStringAsFixed(2);
                }),
                const SizedBox(width: 6),
                _QuickChip(label: 'RS 1,000', onTap: () {
                  _amountCtrl.text = '1000';
                }),
                const SizedBox(width: 6),
                _QuickChip(label: 'RS 5,000', onTap: () {
                  _amountCtrl.text = '5000';
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Note
          const Text(
            'NOTE (OPTIONAL)',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. ATM withdrawal, savings deposit',
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
                : const Text('TRANSFER FUNDS'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A90D9),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Transfer Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _EditTransferSheet extends ConsumerStatefulWidget {
  const _EditTransferSheet({required this.transfer});

  final AccountTransfer transfer;

  @override
  ConsumerState<_EditTransferSheet> createState() => _EditTransferSheetState();
}

class _EditTransferSheetState extends ConsumerState<_EditTransferSheet> {
  late String _fromFundUuid;
  late String _toFundUuid;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fromFundUuid = widget.transfer.fromFundUuid;
    _toFundUuid = widget.transfer.toFundUuid;
    _amountCtrl = TextEditingController(text: widget.transfer.amount.toStringAsFixed(2));
    _noteCtrl = TextEditingController(text: widget.transfer.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ENTER A VALID AMOUNT'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    if (_fromFundUuid == _toFundUuid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CANNOT TRANSFER TO THE SAME ACCOUNT'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(accountTransferRepositoryProvider).updateTransfer(
            uuid: widget.transfer.uuid,
            fromFundUuid: _fromFundUuid,
            toFundUuid: _toFundUuid,
            amount: amt,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            transferAt: widget.transfer.transferAt,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(allFundAccountsProvider).value ?? [];
    final balances = ref.watch(fundBalancesProvider);
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EDIT TRANSFER',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // From Account Selector
          const Text(
            'FROM ACCOUNT',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _fromFundUuid,
            dropdownColor: AppColors.backgroundSurface,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: accounts.map((acc) {
              final bal = balances[acc.uuid] ?? 0.0;
              return DropdownMenuItem(
                value: acc.uuid,
                child: Text('${acc.name} (RS ${fmt.format(bal)})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _fromFundUuid = val;
                  if (_toFundUuid == val) {
                    final other = accounts.firstWhere((a) => a.uuid != val, orElse: () => accounts.first);
                    _toFundUuid = other.uuid != val ? other.uuid : _toFundUuid;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          // To Account Selector
          const Text(
            'TO ACCOUNT',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _toFundUuid,
            dropdownColor: AppColors.backgroundSurface,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: accounts.where((acc) => acc.uuid != _fromFundUuid).map((acc) {
              final bal = balances[acc.uuid] ?? 0.0;
              return DropdownMenuItem(
                value: acc.uuid,
                child: Text('${acc.name} (RS ${fmt.format(bal)})'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _toFundUuid = val);
              }
            },
          ),
          const SizedBox(height: 16),
          // Amount
          const Text(
            'AMOUNT (LKR)',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 15,
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
          const SizedBox(height: 16),
          // Note
          const Text(
            'NOTE (OPTIONAL)',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. ATM withdrawal, savings deposit',
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
    );
  }
}

