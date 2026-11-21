import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/debt_item.dart';
import '../../models/wallet.dart';
import '../../services/api_service.dart';
import '../../utils/category_helper.dart';
import '../../utils/input_formatters.dart';

// ── Segmented Tab Selector ──────────────────────────────────────────────────
class DebtSegmentedTabs extends StatelessWidget {
  final int selectedTab; // 0 = Utang, 1 = Piutang
  final int utangCount;
  final int piutangCount;
  final ValueChanged<int> onTabChanged;

  const DebtSegmentedTabs({
    super.key,
    required this.selectedTab,
    required this.utangCount,
    required this.piutangCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              context: context,
              title: 'Utang',
              count: utangCount,
              isSelected: selectedTab == 0,
              onTap: () => onTabChanged(0),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTab(
              context: context,
              title: 'Piutang',
              count: piutangCount,
              isSelected: selectedTab == 1,
              onTap: () => onTabChanged(1),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const activeColor = Color(0xFF5B4DFF); // Purple FinChat
    final inactiveTextColor = isDark ? AppColors.textDarkSecondary : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : inactiveTextColor,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : inactiveTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Debt Card Widget (Sesuai Referensi Mockup) ──────────────────────────────
class DebtCardWidget extends StatelessWidget {
  final DebtItem item;
  final VoidCallback onHistory;
  final VoidCallback onPay;

  const DebtCardWidget({
    super.key,
    required this.item,
    required this.onHistory,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    final isPaid = item.isPaid;
    final progress = (item.percentPaid / 100).clamp(0.0, 1.0);

    // Menentukan icon dan warna icon berdasarkan nama / keterangan
    final descLower = (item.description ?? '').toLowerCase();
    final nameLower = item.personName.toLowerCase();
    final isShopping = descLower.contains('beli') ||
        descLower.contains('belanja') ||
        nameLower.contains('paylater') ||
        nameLower.contains('shopee') ||
        nameLower.contains('tokopedia');

    final iconBg = isPaid
        ? (isDark ? const Color(0xFF0F291E) : const Color(0xFFE0E7FF))
        : (isShopping
            ? (isDark ? const Color(0xFF3B2810) : const Color(0xFFFEF3C7))
            : (isDark ? const Color(0xFF1E2436) : const Color(0xFFE0E7FF)));

    final iconColor = isPaid
        ? const Color(0xFF4F46E5)
        : (isShopping ? const Color(0xFFD97706) : const Color(0xFF4F46E5));

    final iconData = isShopping ? Icons.shopping_bag_outlined : Icons.person_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Baris Atas: Icon + Judul/Subtitle + Status Badge ───
            Row(
              children: [
                // Icon Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),

                // Judul & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description != null && item.description!.isNotEmpty
                            ? '${item.personName} – ${item.description}'
                            : item.personName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.isDebt
                            ? (isShopping ? 'Paylater & Cicilan Retail' : 'Pinjaman Personal')
                            : 'Piutang / Tagihan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? (isDark ? const Color(0xFF0F3924) : const Color(0xFFD1FAE5))
                        : (isDark ? const Color(0xFF382312) : const Color(0xFFFFF3E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPaid ? '✓ ' : '• ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isPaid ? const Color(0xFF059669) : const Color(0xFFB45309),
                        ),
                      ),
                      Text(
                        isPaid ? 'Lunas' : 'Belum Lunas',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isPaid ? const Color(0xFF059669) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Box 3 Kolom Metrik: Total | Sisa | Jatuh Tempo ────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
              ),
              child: Row(
                children: [
                  // Kolom 1: Total
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(fontSize: 10.5, color: secondaryText),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatRupiahTx(item.amount),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kolom 2: Sisa (Otomatis berkurang saat diangsur)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sisa',
                          style: TextStyle(fontSize: 10.5, color: secondaryText),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isPaid ? 'Rp 0' : formatRupiahTx(item.remainingAmount),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isPaid
                                ? const Color(0xFF059669)
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kolom 3: Jatuh Tempo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jatuh Tempo',
                          style: TextStyle(fontSize: 10.5, color: secondaryText),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.formattedDueDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Baris Progress Bar Pelunasan ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPaid ? 'Status Pinjaman' : 'Pelunasan Pokok',
                  style: TextStyle(fontSize: 11, color: secondaryText),
                ),
                Text(
                  isPaid
                      ? '100% Selesai'
                      : (item.installmentsCount > 0
                          ? '${item.installmentsCount}x Angsur (${item.percentPaid.toStringAsFixed(0)}%)'
                          : '${item.percentPaid.toStringAsFixed(0)}% Terbayar'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPaid ? const Color(0xFF059669) : secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPaid ? const Color(0xFF059669) : const Color(0xFF34D399),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Tombol Aksi: Riwayat & Bayar ──────────────────────
            if (!isPaid)
              Row(
                children: [
                  // Tombol Riwayat (Melihat histori angsuran nyata)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onHistory,
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text(
                        item.installmentsCount > 0
                            ? 'Riwayat (${item.installmentsCount})'
                            : 'Riwayat',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tombol Bayar / Angsur
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPay,
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: Text(item.isDebt ? 'Bayar' : 'Terima'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: const Color(0xFF059669), // Emerald
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Jika sudah Lunas: tampilkan tombol Riwayat Pelunasan full width
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: Text('Riwayat Pelunasan (${item.installmentsCount} Transaksi)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Ringkasan Kewajiban Card (Dark Modern Card di Bawah) ────────────────────
class RingkasanKewajibanCard extends StatelessWidget {
  final double totalDebtUnpaid;
  final double totalReceivableUnpaid;
  final int activeDebtCount;
  final int activeReceivableCount;

  const RingkasanKewajibanCard({
    super.key,
    required this.totalDebtUnpaid,
    required this.totalReceivableUnpaid,
    required this.activeDebtCount,
    required this.activeReceivableCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Slate
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ringkasan Kewajiban',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Text(
                'FinChat Realtime',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2 Kolom: Utang Tersisa & Piutang Masuk
          Row(
            children: [
              // Kolom Utang Tersisa
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Utang Tersisa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiahTx(totalDebtUnpaid),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• $activeDebtCount Tagihan Aktif',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Kolom Piutang Masuk
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Piutang Masuk',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiahTx(totalReceivableUnpaid),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF34D399), // Mint green
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• $activeReceivableCount Belum Diterima',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Modal Form Pembayaran / Angsuran dengan Cara Bayar ──────────────────────
class PayDebtBottomSheet extends StatefulWidget {
  final DebtItem item;
  final Future<void> Function({
    required double amount,
    int? walletId,
    required String source,
    String? date,
    String? description,
  }) onConfirm;

  const PayDebtBottomSheet({
    super.key,
    required this.item,
    required this.onConfirm,
  });

  @override
  State<PayDebtBottomSheet> createState() => _PayDebtBottomSheetState();
}

class _PayDebtBottomSheetState extends State<PayDebtBottomSheet> {
  bool _isFullPayment = true;
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  List<Wallet> _wallets = [];
  bool _isLoadingWallets = true;
  int? _selectedWalletId;
  String _selectedSource = 'cash'; // 'cash', 'emoney', 'bank'

  final DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.item.remainingAmount
        .round()
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    _descController.text = widget.item.installmentsCount > 0
        ? 'Angsuran ke-${widget.item.installmentsCount + 1}'
        : (widget.item.isDebt ? 'Pembayaran pertama' : 'Penerimaan pertama');
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => _isLoadingWallets = true);
    try {
      final res = await ApiService.getWallets();
      final raw = res['wallets'] as List? ?? [];
      final List<Wallet> list = [];
      for (var item in raw) {
        if (item is Map<String, dynamic>) {
          final w = Wallet.fromJson(item);
          if (!w.isArchived) list.add(w);
        }
      }
      if (mounted) {
        setState(() {
          _wallets = list;
          _isLoadingWallets = false;
          if (_wallets.isNotEmpty) {
            _selectedWalletId = _wallets.first.id;
            _selectedSource = _wallets.first.type;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWallets = false);
      }
    }
  }

  Wallet? get _selectedWallet {
    if (_selectedWalletId == null || _wallets.isEmpty) return null;
    try {
      return _wallets.firstWhere((w) => w.id == _selectedWalletId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handlePay() async {
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0) {
      setState(() => _errorMessage = 'Nominal pembayaran harus lebih dari 0');
      return;
    }

    if (amount > widget.item.remainingAmount) {
      setState(() => _errorMessage = 'Nominal melebihi sisa tagihan (${formatRupiahTx(widget.item.remainingAmount)})');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = '${_paymentDate.year.toString().padLeft(4, '0')}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}';
      await widget.onConfirm(
        amount: amount,
        walletId: _selectedWalletId,
        source: _selectedSource,
        date: dateStr,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    final actionTitle = widget.item.isDebt ? 'Bayar Utang' : 'Terima Piutang';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  actionTitle,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Box Info Sisa Tagihan ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.isDebt ? 'Pemberi Pinjaman' : 'Peminjam',
                        style: TextStyle(fontSize: 11, color: secondaryText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.personName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Sisa yang Harus Dibayar',
                        style: TextStyle(fontSize: 11, color: secondaryText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiahTx(widget.item.remainingAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Pilihan Cepat: Lunasi Semua vs Angsur Sebagian ──────
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Lunasi Seluruh Sisa')),
                    selected: _isFullPayment,
                    selectedColor: const Color(0xFF059669),
                    labelStyle: TextStyle(
                      color: _isFullPayment ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _isFullPayment = true;
                          _amountController.text = widget.item.remainingAmount
                              .round()
                              .toString()
                              .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Bayar Sebagian / Cicil')),
                    selected: !_isFullPayment,
                    selectedColor: const Color(0xFF5B4DFF),
                    labelStyle: TextStyle(
                      color: !_isFullPayment ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _isFullPayment = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Input Nominal Pembayaran ───────────────────────────
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Nominal Bayar (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                final amt = double.tryParse(val.replaceAll('.', '')) ?? 0.0;
                if (amt < widget.item.remainingAmount && _isFullPayment) {
                  setState(() => _isFullPayment = false);
                } else if (amt == widget.item.remainingAmount && !_isFullPayment) {
                  setState(() => _isFullPayment = true);
                }
              },
            ),

            const SizedBox(height: 14),

            // ── Pilihan Cara Bayar / Sumber Dana ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item.isDebt ? 'Sumber Dana (Bayar dari)' : 'Rekening / Dompet Tujuan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (_selectedWallet != null)
                  Text(
                    'Saldo: ${formatRupiahTx(_selectedWallet!.currentBalance)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _selectedWallet!.currentBalance < 0
                          ? Colors.red
                          : const Color(0xFF059669),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            _buildWalletSelector(isDark, textColor, secondaryText),

            // Peringatan jika saldo dompet kurang dari jumlah pembayaran (khusus bayar utang)
            if (widget.item.isDebt && _selectedWallet != null) ...[
              Builder(
                builder: (context) {
                  final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
                  final amount = double.tryParse(amountText) ?? 0.0;
                  if (amount > _selectedWallet!.currentBalance) {
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade700.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Saldo ${_selectedWallet!.name} kurang dari nominal bayar. Saldo akan minus jika dilanjutkan.',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            const SizedBox(height: 14),

            // ── Field Catatan / Keterangan Angsuran ────────────────
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Catatan Pembayaran (Opsional)',
                hintText: 'Contoh: Angsuran ke-1, Cicilan bulan Okt',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tombol Konfirmasi Pembayaran ───────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handlePay,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isFullPayment ? 'Lunasi Sekarang' : 'Catat Angsuran',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector(bool isDark, Color textColor, Color secondaryText) {
    if (_isLoadingWallets) {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
            ),
            const SizedBox(width: 8),
            Text('Memuat dompet & rekening...', style: TextStyle(fontSize: 11.5, color: secondaryText)),
          ],
        ),
      );
    }

    if (_wallets.isEmpty) {
      return Row(
        children: [
          _buildSourceOption('cash', 'Tunai', Icons.payments_outlined, isDark),
          const SizedBox(width: 8),
          _buildSourceOption('emoney', 'E-Money', Icons.account_balance_wallet_outlined, isDark),
          const SizedBox(width: 8),
          _buildSourceOption('bank', 'Transfer Bank', Icons.account_balance_outlined, isDark),
        ],
      );
    }

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _wallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final w = _wallets[index];
          final isSelected = _selectedWalletId == w.id;
          final isMinus = w.currentBalance < 0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedWalletId = w.id;
                _selectedSource = w.type;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF059669).withOpacity(isDark ? 0.25 : 0.12)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF059669)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: w.parsedColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(w.iconData, size: 18, color: w.parsedColor),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        w.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF059669)
                              : textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiahTx(w.currentBalance),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isMinus
                              ? Colors.red
                              : (isSelected ? const Color(0xFF059669) : secondaryText),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourceOption(String code, String label, IconData icon, bool isDark) {
    final isSelected = _selectedSource == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSource = code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF059669).withOpacity(isDark ? 0.25 : 0.12)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF059669)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF059669) : (isDark ? Colors.white60 : Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF059669) : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Modal Riwayat Pembayaran Nyata (History Log) ────────────────────────────
class DebtHistoryBottomSheet extends StatelessWidget {
  final DebtItem item;

  const DebtHistoryBottomSheet({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    final payments = item.payments;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Pembayaran',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.personName} • ${item.isDebt ? 'Utang' : 'Piutang'}',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Ringkasan Nominal: Total, Terbayar, Sisa ───────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Pinjaman', style: TextStyle(fontSize: 10.5, color: secondaryText)),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiahTx(item.amount),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sudah Dibayar', style: TextStyle(fontSize: 10.5, color: secondaryText)),
                        const SizedBox(height: 2),
                        Text(
                          formatRupiahTx(item.paidAmount),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sisa Tagihan', style: TextStyle(fontSize: 10.5, color: secondaryText)),
                        const SizedBox(height: 2),
                        Text(
                          item.isPaid ? 'Rp 0' : formatRupiahTx(item.remainingAmount),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: item.isPaid ? const Color(0xFF059669) : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Header List Histori ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histori Transaksi (${payments.length})',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  '${item.percentPaid.toStringAsFixed(0)}% Selesai',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Daftar Riwayat Pembayaran ──────────────────────────
            if (payments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_outlined, size: 36, color: secondaryText),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat pembayaran',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Klik tombol Bayar pada kartu untuk mencatat angsuran.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: secondaryText),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final p = payments[index];
                  final isCash = p.source.toLowerCase() == 'cash' || p.source.toLowerCase() == 'tunai';
                  final isEmoney = p.source.toLowerCase().contains('emoney') || p.source.toLowerCase().contains('wallet');

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon Bayar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Detail Keterangan & Tanggal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.description != null && p.description!.isNotEmpty
                                    ? p.description!
                                    : (item.isDebt ? 'Pembayaran Angsuran' : 'Penerimaan Angsuran'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    p.formattedDate,
                                    style: TextStyle(fontSize: 10.5, color: secondaryText),
                                  ),
                                  const SizedBox(width: 8),
                                  // Badge Cara Bayar
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCash
                                              ? Icons.payments_outlined
                                              : (isEmoney
                                                  ? Icons.account_balance_wallet_outlined
                                                  : Icons.account_balance_outlined),
                                          size: 10,
                                          color: secondaryText,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          p.sourceLabel,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Nominal yang Dibayar
                        Text(
                          '+ ${formatRupiahTx(p.amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Modal Tambah Utang / Piutang Baru ───────────────────────────────────────
class AddDebtBottomSheet extends StatefulWidget {
  final int initialTab; // 0 = Utang, 1 = Piutang
  final Future<void> Function({
    required String type,
    required String personName,
    required double amount,
    String? dueDate,
    String? description,
  }) onSubmit;

  const AddDebtBottomSheet({
    super.key,
    required this.initialTab,
    required this.onSubmit,
  });

  @override
  State<AddDebtBottomSheet> createState() => _AddDebtBottomSheetState();
}

class _AddDebtBottomSheetState extends State<AddDebtBottomSheet> {
  late String _selectedType;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialTab == 0 ? 'debt' : 'receivable';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nama pihak wajib diisi');
      return;
    }
    if (amount <= 0) {
      setState(() => _errorMessage = 'Nominal harus lebih dari 0');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dueDateStr = _selectedDueDate != null
          ? '${_selectedDueDate!.year.toString().padLeft(4, '0')}-${_selectedDueDate!.month.toString().padLeft(2, '0')}-${_selectedDueDate!.day.toString().padLeft(2, '0')}'
          : null;

      await widget.onSubmit(
        type: _selectedType,
        personName: name,
        amount: amount,
        dueDate: dueDateStr,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catat Komitmen Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Pilihan Tipe: Utang vs Piutang
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Utang (Saya Berutang)')),
                    selected: _selectedType == 'debt',
                    selectedColor: const Color(0xFF5B4DFF),
                    labelStyle: TextStyle(
                      color: _selectedType == 'debt' ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = 'debt');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Piutang (Tagihan Saya)')),
                    selected: _selectedType == 'receivable',
                    selectedColor: const Color(0xFF5B4DFF),
                    labelStyle: TextStyle(
                      color: _selectedType == 'receivable' ? Colors.white : textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedType = 'receivable');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Field Nama Pihak
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _selectedType == 'debt' ? 'Nama Pemberi Pinjaman' : 'Nama Peminjam',
                hintText: _selectedType == 'debt' ? 'Contoh: SPayLater, Budi' : 'Contoh: Ahmad, Rian',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // Field Nominal
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                RupiahInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Nominal (Rp)',
                hintText: 'Contoh: 50.000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // Field Tanggal Jatuh Tempo
            InkWell(
              onTap: _pickDueDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tanggal Jatuh Tempo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(
                  _selectedDueDate != null
                      ? '${_selectedDueDate!.day} / ${_selectedDueDate!.month} / ${_selectedDueDate!.year}'
                      : 'Pilih tanggal (opsional)',
                  style: TextStyle(
                    color: _selectedDueDate != null ? textColor : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Field Keterangan
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Keterangan (Opsional)',
                hintText: 'Contoh: Beli Barang Elektronik',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan Komitmen',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
