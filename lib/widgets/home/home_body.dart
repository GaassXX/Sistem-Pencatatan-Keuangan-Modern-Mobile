import '../../pages/budget_page.dart';
import 'package:flutter/material.dart';

import '../../pages/add_transaction_page.dart';
import '../../pages/chat_bot_page.dart';
import '../../pages/savings_page.dart';
import '../../pages/wallets_page.dart';
import '../../utils/category_helper.dart';
import '../../utils/date_helper.dart';
import '../../utils/format_helper.dart';
import 'balance_card.dart';
import 'budget_card.dart';
import 'category_spending_card.dart';
import 'quick_action.dart';

/// Konten scrollable untuk tab Beranda FinChat.
class HomeBody extends StatelessWidget {
  final String name;
  final Map<String, dynamic> dashboard;
  final List<dynamic> recentTransactions;
  final Future<void> Function() onRefresh;
  final void Function(int) onChangePage;

  const HomeBody({
    super.key,
    required this.name,
    required this.dashboard,
    required this.recentTransactions,
    required this.onRefresh,
    required this.onChangePage,
  });

  dynamic _findValue(List<String> keys) {
    for (final key in keys) {
      if (dashboard.containsKey(key)) {
        return dashboard[key];
      }
    }
    return null;
  }

  String _formatDateShort(dynamic dateVal, dynamic createdAtVal) {
    final parsed = parseDate(dateVal) ?? parseDate(createdAtVal);
    if (parsed == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          // ── Greeting Header ──────────────────────────
          Text(
            'Halo, $name 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ringkasan keuangan pintar kamu hari ini',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(.62),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          // ── Saldo Card ───────────────────────────────
          BalanceCard(
            balance: formatRupiah(_findValue(['balance', 'saldo', 'net_balance', 'netBalance'])),
            income: formatRupiah(_findValue(['total_income', 'income', 'pemasukan', 'month_income'])),
            expense: formatRupiah(_findValue(['total_expense', 'expense', 'pengeluaran', 'month_expense'])),
          ),

          const SizedBox(height: 24),

          // ── 4 Tombol Aksi Cepat (Modern FinChat Grid) ─
          Row(
            children: [
              Expanded(
                child: QuickAction(
                  icon: Icons.add_rounded,
                  title: 'Catat\nBaru',
                  bgColor: const Color(0xFFEDE9FE), // Lavender / Light Indigo
                  iconColor: const Color(0xFF6366F1),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionPage(),
                      ),
                    );
                    if (result == true) {
                      await onRefresh();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.smart_toy_rounded,
                  title: 'FinChat',
                  bgColor: const Color(0xFFE0E7FF), // Soft Blue
                  iconColor: const Color(0xFF4F46E5),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatBotPage(),
                      ),
                    );
                    if (result == true) {
                      await onRefresh();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Dompet',
                  bgColor: const Color(0xFFFEF3C7), // Soft Amber / Gold
                  iconColor: const Color(0xFFD97706),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WalletsPage(),
                      ),
                    );
                    if (result == true) {
                      await onRefresh();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.savings_rounded,
                  title: 'Tabungan',
                  bgColor: const Color(0xFFD1FAE5), // Mint / Emerald
                  iconColor: const Color(0xFF10B981),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavingsPage(),
                      ),
                    );
                    if (result == true) {
                      await onRefresh();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // ── Anggaran Bulan Ini ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ANGGARAN BULAN INI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .7,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetPage()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const BudgetCard(),

          const SizedBox(height: 26),

          // ── Pengeluaran Terbanyak ────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PENGELUARAN TERBANYAK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .7,
                ),
              ),
              Text(
                ' ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CategorySpendingCard(
            categoryBreakdown: dashboard['category_breakdown'] is List
                ? dashboard['category_breakdown'] as List
                : [],
          ),

          const SizedBox(height: 26),

          // ── Transaksi Terbaru ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TRANSAKSI TERBARU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .7,
                ),
              ),
              GestureDetector(
                onTap: () => onChangePage(1),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Transaksi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Belum ada transaksi terbaru',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: recentTransactions.take(5).map((item) {
                final isIncome = item['type'] == 'income';
                final cat = categoryName(item);
                final description = item['description']?.toString() ?? '-';
                final amount = formatRupiahTx(item['amount']);
                final dateStr = _formatDateShort(item['date'], item['created_at']);
                final color = categoryColor(cat);
                final bgIcon = isDark ? const Color(0xFF0F172A) : color.withOpacity(0.10);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ── Icon Kategori ─────────────────────────
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: bgIcon,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcon(cat),
                          size: 20,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Nama & Kategori · Tanggal ──────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$cat · $dateStr',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withOpacity(.50),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ── Nominal ────────────────────────────────
                      Text(
                        isIncome ? '+$amount' : '-$amount',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isIncome
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
