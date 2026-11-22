import 'package:flutter/material.dart';

import '../../utils/category_helper.dart';
import '../../utils/date_helper.dart';

/// Kartu satu item transaksi — Modern FinChat Design.
class TransactionCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = item['type'] == 'income';
    final cat = categoryName(item);
    final description = item['description']?.toString() ?? '-';
    final amount = formatRupiahTx(item['amount']);
    final source = paymentMethodName(item['payment_source'] ?? item['source'] ?? '');
    final timeStr = formatTime(item['created_at']);

    // Apakah dicatat via ChatBot
    final viaChat = item['via_chat'] == true || item['source'] == 'chat' || item['input_method'] == 'chat';

    final cardBg = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final mutedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    const expenseColor = Color(0xFFEF4444);
    const incomeColor = Color(0xFF10B981);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon Kategori ──────────────────────
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : categoryBackground(cat),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    categoryIcon(cat),
                    size: 22,
                    color: isDark ? const Color(0xFF818CF8) : categoryIconColor(cat),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Deskripsi & Meta ───────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Kategori · Metode · Jam
                      Text(
                        [
                          cat,
                          if (source.isNotEmpty) source,
                          if (timeStr.isNotEmpty) timeStr,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: subtitleColor),
                      ),

                      const SizedBox(height: 6),

                      // Badge sumber input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: viaChat
                              ? const Color(0xFFEEF2FF)
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: viaChat
                                ? const Color(0xFFC7D2FE)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              viaChat ? Icons.smart_toy_outlined : Icons.edit_note_rounded,
                              size: 10,
                              color: viaChat ? const Color(0xFF4F46E5) : mutedColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              viaChat ? 'Auto-catat via Chat' : 'Pencatatan Manual',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: viaChat ? const Color(0xFF4F46E5) : mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Jumlah & Panah ─────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}$amount',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? incomeColor : expenseColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: mutedColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
