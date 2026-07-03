import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../domain/providers/fund_providers.dart';

class TotalCashCard extends ConsumerWidget {
  const TotalCashCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(allFundAccountsProvider);
    final balances = ref.watch(fundBalancesProvider);
    final fmt = NumberFormat('#,##0.00', 'en_US');

    final allAccounts = accountsAsync.value ?? [];
    final trackedAccounts = allAccounts.take(2).toList();

    // Sum total cash at hand across tracked fund sources
    final totalBalance = trackedAccounts.fold<double>(
      0.0,
      (sum, acc) => sum + (balances[acc.uuid] ?? 0.0),
    );

    return GestureDetector(
      onTap: () => context.go('/funds'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL CASH AT HAND',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VIEW FUNDS',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 9,
                        letterSpacing: 1,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Prominent total figure
            Text(
              'RS ${fmt.format(totalBalance)}',
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                fontSize: 34,
                height: 1.1,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 16),
            // Side-by-side beautiful display for the first 2 fund sources
            if (trackedAccounts.isNotEmpty) ...[
              Row(
                children: trackedAccounts.map((acc) {
                  final bal = balances[acc.uuid] ?? 0.0;
                  final isPositive = bal >= 0;
                  final isCash = acc.name.toLowerCase().contains('cash');

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: acc == trackedAccounts.first && trackedAccounts.length > 1
                            ? 6
                            : 0,
                        left: acc == trackedAccounts.last && trackedAccounts.length > 1
                            ? 6
                            : 0,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundElevated,
                        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isCash
                                    ? Icons.account_balance_wallet_outlined
                                    : Icons.savings_outlined,
                                size: 13,
                                color: AppColors.accentBlue,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  acc.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'RS ${fmt.format(bal)}',
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: isPositive
                                  ? AppColors.textPrimary
                                  : AppColors.destructive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const Text(
                'NO FUND ACCOUNTS SET UP.',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
