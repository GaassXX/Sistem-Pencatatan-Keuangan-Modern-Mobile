import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../utils/category_helper.dart';
import '../utils/date_helper.dart';
import '../utils/format_helper.dart';
import 'add_transaction_page.dart';

// ─── Konstanta Tema FinChat ───────────────────────
const _cNavy    = Color(0xFF172033);
const _cIndigo  = Color(0xFF4F46E5);
const _cGreen   = Color(0xFF16A34A);
const _cRed     = Color(0xFFEF4444);
const _cSubtext = Color(0xFF64748B);

class TransactionDetailPage extends StatefulWidget {
  final dynamic transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;
  bool _didMutate = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  /// Menghasilkan format ID yang dijamin valid (misal: 'exp-1' atau 'inc-1')
  String _resolveTransactionId() {
    final rawId = (data?['id'] ?? widget.transaction['id'])?.toString() ?? '';
    if (rawId.startsWith('exp-') || rawId.startsWith('inc-')) {
      return rawId;
    }
    final isIncome = (data?['type'] ?? widget.transaction['type']) == 'income';
    return '${isIncome ? 'inc' : 'exp'}-$rawId';
  }

  Future<void> _loadDetail() async {
    try {
      final txId = _resolveTransactionId();
      final detail = await ApiService.getTransactionDetail(txId);

      if (!mounted) return;

      // Pastikan ID asli ber-prefix tetap dipertahankan
      detail['id'] = txId;

      setState(() {
        data = detail;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';
    return '${date.day} ${fullMonthName(date.month)} ${date.year}';
  }

  String _formatTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    String str = value.toString().trim();
    if (!str.endsWith('Z') && !str.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(str)) {
      str += 'Z';
    }
    final date = DateTime.tryParse(str);
    if (date == null) return '-';
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _editTransaction() async {
    if (data == null) return;
    final editData = Map<String, dynamic>.from(data!);
    editData['id'] = _resolveTransactionId();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(transactionToEdit: editData),
      ),
    );

    if (result == true) {
      _didMutate = true;
      setState(() {
        loading = true;
        error = null;
      });
      _loadDetail();
    }
  }

  void _confirmDelete() {
    if (data == null) return;
    final txId = _resolveTransactionId();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _cRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _cRed, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Hapus Transaksi?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDarkPrimary : _cNavy,
                ),
              ),
            ],
          ),
          content: Text(
            'Transaksi yang dihapus tidak dapat dikembalikan dan saldo dompet akan disesuaikan kembali.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.textDarkSecondary : _cSubtext,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: isDark ? AppColors.textDarkSecondary : _cSubtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cRed,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ApiService.deleteTransaction(txId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Transaksi berhasil dihapus'),
                      backgroundColor: _cGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: _cRed,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDarkPrimary : _cNavy;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _didMutate);
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context, _didMutate),
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
          ),
          title: Text(
            'Detail Transaksi',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          actions: const [],
        ),
        body: loading
            ? Center(child: CircularProgressIndicator(color: isDark ? AppColors.primaryBrand : _cNavy))
            : error != null
                ? _buildError(isDark, textColor)
                : _buildDetail(isDark, textColor, cardBg),
      ),
    );
  }

  Widget _buildError(bool isDark, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: isDark ? AppColors.textDarkSecondary : _cSubtext),
            const SizedBox(height: 12),
            Text(
              'Gagal mengambil detail transaksi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : _cSubtext),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.primaryBrand : _cNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  loading = true;
                  error = null;
                });
                _loadDetail();
              },
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(bool isDark, Color textColor, Color cardBg) {
    final transaction = data!;
    final isIncome = transaction['type'] == 'income';
    final typeColor = isIncome ? _cGreen : _cRed;
    final description = transaction['description']?.toString() ?? '-';

    final categoryData = transaction['category'];
    final category = categoryData is Map ? categoryData['name']?.toString() ?? '-' : categoryData?.toString() ?? '-';

    final walletName = transaction['wallet_name'] ?? transaction['wallet']?['name'] ?? paymentMethodName(transaction['source']);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final dividerColor = isDark ? AppColors.borderDark : const Color(0xFFF1F5F9);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // ── Hero Card (Nominal & Jenis) ─────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Icon bulat lembut
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: typeColor,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 16),

                // Deskripsi transaksi
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Nominal tebal
                Text(
                  '${isIncome ? '+' : '-'}${formatRupiah(transaction['amount'])}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: typeColor,
                  ),
                ),

                const SizedBox(height: 12),

                // Pill status jenis
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(isDark ? 0.2 : 0.09),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isIncome ? 'Pemasukan' : 'Pengeluaran',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Detail Info Card ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.category_rounded,
                  iconBg: isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
                  iconColor: isDark ? const Color(0xFFA5B4FC) : _cIndigo,
                  title: 'Kategori',
                  value: category,
                  textColor: textColor,
                  isDark: isDark,
                ),
                Divider(height: 22, color: dividerColor),
                _buildInfoRow(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: isDark ? const Color(0xFF78350F).withOpacity(0.4) : const Color(0xFFFEF3C7),
                  iconColor: isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
                  title: 'Sumber Dana',
                  value: walletName.toString(),
                  textColor: textColor,
                  isDark: isDark,
                ),
                Divider(height: 22, color: dividerColor),
                _buildInfoRow(
                  icon: Icons.calendar_today_rounded,
                  iconBg: isDark ? const Color(0xFF075985).withOpacity(0.4) : const Color(0xFFE0F2FE),
                  iconColor: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
                  title: 'Tanggal',
                  value: _formatDate(transaction['date']),
                  textColor: textColor,
                  isDark: isDark,
                ),
                Divider(height: 22, color: dividerColor),
                _buildInfoRow(
                  icon: Icons.schedule_rounded,
                  iconBg: isDark ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9),
                  iconColor: isDark ? AppColors.textDarkSecondary : const Color(0xFF475569),
                  title: 'Waktu Catat',
                  value: _formatTime(transaction['created_at']),
                  textColor: textColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Tombol Aksi Bawah ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _editTransaction,
                    icon: Icon(Icons.edit_outlined, size: 18, color: textColor),
                    label: Text(
                      'Edit Transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? AppColors.borderDark : _cNavy, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: cardBg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cRed,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required Color textColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textDarkSecondary : _cSubtext,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
