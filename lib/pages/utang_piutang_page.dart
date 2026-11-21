import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/debt_item.dart';
import '../services/api_service.dart';
import '../utils/category_helper.dart';
import '../widgets/utang_piutang/utang_widgets.dart';

class UtangPiutangPage extends StatefulWidget {
  const UtangPiutangPage({super.key});

  @override
  State<UtangPiutangPage> createState() => _UtangPiutangPageState();
}

class _UtangPiutangPageState extends State<UtangPiutangPage> {
  int _selectedTab = 0; // 0 = Utang, 1 = Piutang
  bool _loading = true;
  String? _error;

  List<DebtItem> _debts = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.getDebts();
      final listRaw = res['data'] as List<dynamic>? ?? [];
      final summaryRaw = res['summary'] as Map<String, dynamic>? ?? {};

      final items = listRaw.map((e) {
        if (e is Map<String, dynamic>) return DebtItem.fromJson(e);
        return DebtItem.fromJson(Map<String, dynamic>.from(e as Map));
      }).toList();

      if (mounted) {
        setState(() {
          _debts = items;
          _summary = summaryRaw;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _loading = false;
        });
      }
    }
  }

  void _showAddModal() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddDebtBottomSheet(
        initialTab: _selectedTab,
        onSubmit: ({
          required String type,
          required String personName,
          required double amount,
          String? dueDate,
          String? description,
        }) async {
          await ApiService.createDebt(
            type: type,
            personName: personName,
            amount: amount,
            dueDate: dueDate,
            description: description,
          );
          _loadData();
        },
      ),
    );
  }

  void _openPayModal(DebtItem item) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PayDebtBottomSheet(
        item: item,
        onConfirm: ({
          required double amount,
          int? walletId,
          required String source,
          String? date,
          String? description,
        }) async {
          final res = await ApiService.payDebt(
            item.id,
            amount: amount,
            walletId: walletId,
            source: source,
            date: date,
            description: description,
          );
          if (mounted) {
            final warning = res['warning']?.toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  warning != null && warning.isNotEmpty
                      ? '${res['message']}\n$warning'
                      : (res['message']?.toString() ?? 'Pembayaran berhasil dicatat!'),
                ),
                backgroundColor: warning != null ? Colors.amber.shade800 : const Color(0xFF059669),
              ),
            );
            _loadData();
          }
        },
      ),
    );
  }

  void _showHistoryModal(DebtItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DebtHistoryBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    // Filter daftar berdasarkan tab
    final currentType = _selectedTab == 0 ? 'debt' : 'receivable';
    final filteredList = _debts.where((d) => d.type == currentType).toList();

    // Hitung jumlah untuk badge tab
    final utangCount = _debts.where((d) => d.type == 'debt').length;
    final piutangCount = _debts.where((d) => d.type == 'receivable').length;

    // Hitung aktif belum lunas
    final activeDebtCount = _debts.where((d) => d.type == 'debt' && !d.isPaid).length;
    final activeReceivableCount = _debts.where((d) => d.type == 'receivable' && !d.isPaid).length;

    final totalDebtUnpaid = amountValue(_summary['total_debt_unpaid']);
    final totalReceivableUnpaid = amountValue(_summary['total_receivable_unpaid']);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF5B4DFF),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              // ── Header: Utang & Piutang + Tombol Catat ─────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utang & Piutang',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manajemen komitmen & tagihan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),

                  // Tombol + Catat (Pill Purple)
                  GestureDetector(
                    onTap: _showAddModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4DFF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B4DFF).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Catat',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Segmented Tab Selector (Utang vs Piutang) ──────────
              DebtSegmentedTabs(
                selectedTab: _selectedTab,
                utangCount: utangCount,
                piutangCount: piutangCount,
                onTabChanged: (tab) => setState(() => _selectedTab = tab),
              ),

              const SizedBox(height: 16),

              // ── Body Konten: Loading / Error / Empty / List ────────
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF5B4DFF)),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 36),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondaryText, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4DFF),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              else if (filteredList.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4DFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                          size: 26,
                          color: Color(0xFF5B4DFF),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _selectedTab == 0
                            ? 'Belum ada catatan utang'
                            : 'Belum ada catatan piutang',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTab == 0
                            ? 'Catat kewajiban utangmu agar tidak terlambat bayar.'
                            : 'Catat piutangmu agar mudah memantau penagihan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: secondaryText),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showAddModal,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(_selectedTab == 0 ? 'Catat Utang Baru' : 'Catat Piutang Baru'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5B4DFF),
                          side: const BorderSide(color: Color(0xFF5B4DFF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Daftar Card Utang/Piutang
                ...filteredList.map((item) {
                  return DebtCardWidget(
                    item: item,
                    onHistory: () => _showHistoryModal(item),
                    onPay: () => _openPayModal(item),
                  );
                }),

              // ── Ringkasan Kewajiban Card di Bawah ──────────────────
              RingkasanKewajibanCard(
                totalDebtUnpaid: totalDebtUnpaid,
                totalReceivableUnpaid: totalReceivableUnpaid,
                activeDebtCount: activeDebtCount,
                activeReceivableCount: activeReceivableCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
