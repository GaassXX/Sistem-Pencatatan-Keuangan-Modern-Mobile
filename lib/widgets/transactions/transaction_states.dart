import 'package:flutter/material.dart';

/// State kosong ketika tidak ada transaksi pada periode yang dipilih.
class TransactionEmptyState extends StatelessWidget {
  const TransactionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? const Color(0xFF1E2420) : const Color(0xFFEAF0FA);
    final iconColor = isDark ? const Color(0xFF10B981) : const Color(0xFF64748B);
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark ? const Color(0xFF737D75) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 30,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Transaksi pada periode ini akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// State error ketika gagal memuat transaksi.
class TransactionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TransactionErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? const Color(0xFF737D75) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42, color: subtitleColor),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat transaksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: subtitleColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
