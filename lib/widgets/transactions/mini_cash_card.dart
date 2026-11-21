import 'package:flutter/material.dart';

/// Kartu mini untuk menampilkan nominal pemasukan atau pengeluaran.
class MiniCashCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final bool positive;

  const MiniCashCard({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2420) : const Color(0xFFF8FAFC);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark ? const Color(0xFF9CA69E) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: positive ? const Color(0xFFDDFCE8) : const Color(0xFFFFE7E7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 17,
              color: positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9, color: subtitleColor),
                ),
                const SizedBox(height: 1),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
