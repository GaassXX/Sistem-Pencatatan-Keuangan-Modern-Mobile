import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../utils/category_helper.dart';

/// Widget visualisasi rekap pengeluaran per kategori bulan ini.
/// Desain: strip warna kiri + progress bar per baris + badge % berwarna.
class CategorySpendingCard extends StatelessWidget {
  final List<dynamic> categoryBreakdown;

  const CategorySpendingCard({
    super.key,
    required this.categoryBreakdown,
  });

  String _currentMonthLabel() {
    const months = [
      'Januari', 'Februari', 'Maret', 'April',
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    if (categoryBreakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'Belum ada pengeluaran bulan ini ✨',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight,
            ),
          ),
        ),
      );
    }

    final items = categoryBreakdown.take(4).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pengeluaran Per Kategori',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentMonthLabel(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Daftar Kategori ──────────────────────────────────────
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final catName = item['category']?.toString() ?? 'Lainnya';
            final amount = amountValue(item['amount']);
            final percent = amountValue(item['percentage']);
            final progress = (percent / 100).clamp(0.0, 1.0);
            final color = categoryColor(catName);
            final bgIcon = isDark ? const Color(0xFF0F172A) : color.withOpacity(0.10);
            final isLast = i == items.length - 1;

            return Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Strip warna di kiri ──────────────────────
                      Container(
                        width: 4,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Konten item ──────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 10,
                            bottom: isLast ? 14 : 8,
                            right: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Icon kategori
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: bgIcon,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      categoryIcon(catName),
                                      size: 17,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Nama + nominal
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          catName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          formatRupiahTx(amount),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.textDarkSecondary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Badge persentase berwarna
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(isDark ? 0.18 : 0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${percent.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Progress bar berwarna
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: isDark
                                      ? color.withOpacity(0.12)
                                      : color.withOpacity(0.10),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider tipis antar item (kecuali item terakhir)
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
