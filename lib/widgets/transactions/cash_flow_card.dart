import 'package:flutter/material.dart';

import '../../utils/category_helper.dart';

/// Kartu ringkasan arus kas — Modern FinChat Design.
class CashFlowCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final int incomeCount;
  final int expenseCount;

  const CashFlowCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    this.incomeCount = 0,
    this.expenseCount = 0,
  });

  double get netCashFlow => totalIncome - totalExpense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = netCashFlow >= 0;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────
          Row(
            children: [
              Text(
                'Arus Kas Periode Ini',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              // Surplus / Defisit badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${isPositive ? 'Surplus +' : 'Defisit -'}${formatRupiahTx(netCashFlow.abs())}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Divider tipis ──────────────────────────
          Container(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),

          const SizedBox(height: 14),

          // ── Mini cards ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Pemasukan',
                  amount: formatRupiahTx(totalIncome),
                  count: incomeCount,
                  isIncome: true,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryBox(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Pengeluaran',
                  amount: formatRupiahTx(totalExpense),
                  count: expenseCount,
                  isIncome: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final int count;
  final bool isIncome;
  final bool isDark;

  const _SummaryBox({
    required this.icon,
    required this.label,
    required this.amount,
    required this.count,
    required this.isIncome,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isIncome
        ? (isDark ? const Color(0xFF064E3B).withOpacity(.5) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF450A0A).withOpacity(.4) : const Color(0xFFFEF2F2));
    final iconColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final amountColor = isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isIncome ? '+' : '-'}$amount',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count transaksi',
            style: TextStyle(
              fontSize: 10,
              color: amountColor.withOpacity(.6),
            ),
          ),
        ],
      ),
    );
  }
}
