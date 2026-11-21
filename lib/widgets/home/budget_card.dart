import 'dart:math';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../pages/budget_page.dart';
import '../../services/api_service.dart';
import '../../utils/category_helper.dart';

/// Widget kartu anggaran terbesar di Beranda yang menampilkan 1 anggaran terbesar pengguna.
class BudgetCard extends StatefulWidget {
  const BudgetCard({super.key});

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  Map<String, dynamic>? _topBudget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBudget();
  }

  Future<void> _fetchBudget() async {
    try {
      final res = await ApiService.getBudgets();
      if (!mounted) return;

      final rawBudgets = res['budgets'] is List ? res['budgets'] as List : [];
      if (rawBudgets.isNotEmpty) {
        // Urutkan berdasarkan limit_amount terbesar
        rawBudgets.sort((a, b) {
          final limitA = amountValue(a['limit_amount']);
          final limitB = amountValue(b['limit_amount']);
          return limitB.compareTo(limitA);
        });
        setState(() {
          _topBudget = Map<String, dynamic>.from(rawBudgets.first as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _topBudget = null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    if (_isLoading) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Color(0xFF5B4DFF), strokeWidth: 2),
          ),
        ),
      );
    }

    // ── Jika Belum Ada Anggaran yang Dibuat ─────────────────────────
    if (_topBudget == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetPage()),
          );
          _fetchBudget();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4DFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 22,
                  color: Color(0xFF5B4DFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum ada anggaran',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tetapkan batas pengeluaran bulan ini',
                      style: TextStyle(fontSize: 11, color: secondaryText),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4DFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Atur',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Jika Ada Anggaran: Tampilkan 1 Anggaran Terbesar Sesuai Mockup ─
    final catName = _topBudget!['category_name']?.toString() ?? 'Kategori';
    final limit = amountValue(_topBudget!['limit_amount']);
    final spent = amountValue(_topBudget!['spent_amount']);
    final remaining = amountValue(_topBudget!['remaining_amount']);
    final percent = amountValue(_topBudget!['percentage']);
    final isOver = _topBudget!['is_over_limit'] == true || spent > limit;
    final isNear = percent >= 80.0 && !isOver;

    // Sisa Hari dalam Bulan Ini
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = max(0, lastDay - now.day);

    // Status Warna & Label Badge
    final Color statusColor;
    final Color badgeBg;
    final String badgeText;
    final String statusInfo;

    if (isOver) {
      statusColor = const Color(0xFFEF4444);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = '• ${percent.toInt()}% (Over)';
      statusInfo = 'Melebihi Limit ($daysRemaining hari tersisa)';
    } else if (isNear) {
      statusColor = const Color(0xFFF59E0B);
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = '• ${percent.toInt()}% (Warning)';
      statusInfo = 'Batas Menipis ($daysRemaining hari tersisa)';
    } else {
      statusColor = const Color(0xFF10B981);
      badgeBg = isDark ? const Color(0xFF0F3924) : const Color(0xFFD1FAE5);
      badgeText = '• ${percent.toInt()}% (Aman)';
      statusInfo = 'Kondisi Aman ($daysRemaining hari tersisa)';
    }

    final catCol = categoryColor(catName);
    final iconBg = catCol.withOpacity(isDark ? 0.2 : 0.12);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetPage()),
        );
        _fetchBudget();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOver ? const Color(0xFFEF4444) : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris Atas: Icon + Nama Kategori & Sisa + Badge Status ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Kategori
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    categoryIcon(catName),
                    size: 20,
                    color: catCol,
                  ),
                ),
                const SizedBox(width: 12),

                // Nama Kategori & Info Sisa
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sisa: ${formatRupiahTx(remaining)} dari ${formatRupiahTx(limit)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge Persentase & Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? statusColor.withOpacity(0.18) : badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Progress Bar ─────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: (spent / (limit > 0 ? limit : 1)).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),

            const SizedBox(height: 10),

            // ── Baris Bawah: Terpakai & Batas Menipis ─────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terpakai: ${formatRupiahTx(spent)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: secondaryText,
                  ),
                ),
                Text(
                  statusInfo,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isNear || isOver ? statusColor : secondaryText,
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
