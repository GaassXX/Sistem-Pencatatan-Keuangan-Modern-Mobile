import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../utils/category_helper.dart';
import '../utils/input_formatters.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  Map<String, dynamic> _summary = {};
  List<dynamic> _budgets = [];
  List<dynamic> _expenseCategories = [];

  bool _loading = true;
  bool _showTips = true;

  static const List<String> _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getBudgets();
      final cats = await ApiService.getCategories('expense');
      if (!mounted) return;
      setState(() {
        _summary = res['summary'] is Map<String, dynamic>
            ? res['summary'] as Map<String, dynamic>
            : {};
        _budgets = res['budgets'] is List ? res['budgets'] as List : [];
        _expenseCategories = cats;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat anggaran: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSetBudgetDialog([dynamic existingBudget]) {
    int? selectedCatId = existingBudget?['category_id'];
    final amountCtrl = TextEditingController(
      text: existingBudget != null
          ? amountValue(existingBudget['limit_amount'])
              .round()
              .toString()
              .replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (m) => '.',
              )
          : '',
    );

    if (selectedCatId == null && _expenseCategories.isNotEmpty) {
      selectedCatId = _expenseCategories.first['id'];
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingBudget != null
                            ? '✏️ Edit Batas Anggaran'
                            : '🎯 Buat Batas Anggaran',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Kategori Pengeluaran',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedCatId,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        items: _expenseCategories
                            .map<DropdownMenuItem<int>>((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['id'],
                            child: Text(cat['name'].toString()),
                          );
                        }).toList(),
                        onChanged: existingBudget != null
                            ? null
                            : (val) {
                                setDialogState(() => selectedCatId = val);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Batas Maksimal Bulanan (Rp)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: 'Contoh: 1.000.000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBrand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedCatId == null) return;
                        final rawAmt = amountCtrl.text
                            .replaceAll('.', '')
                            .replaceAll(',', '')
                            .trim();
                        final val = double.tryParse(rawAmt);
                        if (val == null || val <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nominal batas harus lebih dari 0'),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(dialogCtx);
                        try {
                          await ApiService.setBudget(
                            categoryId: selectedCatId!,
                            limitAmount: val,
                            period: 'monthly',
                          );
                          _loadData();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Batas anggaran berhasil disimpan!'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan anggaran: $e'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Simpan Anggaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (existingBudget != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.expense,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              title: const Text('Hapus Batas Anggaran?'),
                              content: Text(
                                  'Hapus batas budget kategori "${existingBudget['category_name']}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(d, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(d, true),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                            await ApiService.deleteBudget(existingBudget['id']);
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus Batas Anggaran Ini'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTipsContent() {
    final overBudget = _budgets.firstWhere(
      (b) =>
          b['is_over_limit'] == true ||
          amountValue(b['spent_amount']) > amountValue(b['limit_amount']),
      orElse: () => null,
    );

    if (overBudget != null) {
      final overName = overBudget['category_name']?.toString() ?? 'Kategori';
      final deficit = amountValue(overBudget['spent_amount']) -
          amountValue(overBudget['limit_amount']);

      final safeBudget = _budgets.firstWhere(
        (b) =>
            b != overBudget &&
            (amountValue(b['limit_amount']) - amountValue(b['spent_amount'])) >
                50000,
        orElse: () => null,
      );

      if (safeBudget != null) {
        final safeName =
            safeBudget['category_name']?.toString() ?? 'Belanja Harian';
        return RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Pengeluaran '),
              TextSpan(
                text: overName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' melebihi batas '),
              TextSpan(
                text: formatRupiahTx(deficit),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF86EFAC),
                ),
              ),
              const TextSpan(
                  text: '. Pertimbangkan untuk mengalihkan sisa anggaran dari '),
              TextSpan(
                text: safeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        );
      } else {
        return RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Pengeluaran '),
              TextSpan(
                text: overName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' melebihi batas '),
              TextSpan(
                text: formatRupiahTx(deficit),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF86EFAC),
                ),
              ),
              const TextSpan(
                  text: '. Batasi pengeluaran tambahan untuk pos ini hingga akhir bulan.'),
            ],
          ),
        );
      }
    }

    final nearBudget = _budgets.firstWhere(
      (b) => b['is_near_limit'] == true,
      orElse: () => null,
    );
    if (nearBudget != null) {
      final nearName = nearBudget['category_name']?.toString() ?? 'Kategori';
      return Text(
        'Pengeluaran $nearName sudah mendekati batas anggaran bulanan (80%+). Pantau terus pengeluaran harianmu.',
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
      );
    }

    if (_budgets.isNotEmpty) {
      return const Text(
        'Seluruh pos anggaran dalam kondisi aman. Pertahankan ritme belanja agar target tabungan tercapai!',
        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
      );
    }

    return const Text(
      'Atur batas pos pengeluaran bulananmu agar arus kas tetap terencana dan terhindar dari pemborosan.',
      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final monthName = _monthNames[now.month];

    final totalLimit = amountValue(_summary['total_limit']);
    final totalSpent = amountValue(_summary['total_spent']);
    final totalRemaining = amountValue(_summary['total_remaining']);
    final overallPercentage = amountValue(_summary['overall_percentage']);
    final remainingPercentage = (100 - overallPercentage).clamp(0, 100);

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final subTextColor =
        isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── 1. Top Header ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDarkHigh
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: isDark
                                    ? AppColors.textDarkPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Anggaran Bulan Ini',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$monthName ${now.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showSetBudgetDialog(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBrand,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── 2. Total Anggaran vs Terpakai Card ─────────
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBrand.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 18,
                                  color: AppColors.primaryBrand,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total Anggaran vs Terpakai',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF312E81)
                                      : AppColors.brandBlueLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  monthName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBrand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Anggaran',
                                    style: TextStyle(
                                        fontSize: 11.5, color: subTextColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiahTx(totalLimit),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Terpakai',
                                    style: TextStyle(
                                        fontSize: 11.5, color: subTextColor),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBrand,
                                      ),
                                      children: [
                                        TextSpan(
                                            text: formatRupiahTx(totalSpent)),
                                        TextSpan(
                                          text:
                                              ' (${overallPercentage.round()}%)',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: totalLimit > 0
                                  ? (totalSpent / totalLimit).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? AppColors.surfaceDarkHigh
                                  : AppColors.brandBlueLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _summary['is_over_limit'] == true
                                    ? AppColors.expense
                                    : AppColors.primaryBrand,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sisa Kuota: ${formatRupiahTx(totalRemaining)}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                ),
                              ),
                              Text(
                                'Tersisa ${remainingPercentage.round()}%',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── 3. Sub-Header: Kategori Anggaran & X Pos Aktif ─
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kategori Anggaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${_budgets.length} Pos Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── 4. Daftar Kartu Kategori Anggaran ───────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (_budgets.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 40,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Belum ada batasan anggaran',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tentukan batas maksimal belanja untuk mencegah pengeluaran berlebih.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBrand,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _showSetBudgetDialog(),
                                    child: const Text(
                                      'Buat Anggaran Sekarang',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._budgets.map((b) {
                              final catName =
                                  b['category_name']?.toString() ?? 'Kategori';
                              final limit = amountValue(b['limit_amount']);
                              final spent = amountValue(b['spent_amount']);
                              final percentage = limit > 0
                                  ? (spent / limit * 100)
                                  : 0;
                              final isOver = b['is_over_limit'] == true ||
                                  spent > limit;
                              final isNear = b['is_near_limit'] == true ||
                                  (percentage >= 80 && !isOver);

                              final Color badgeBg;
                              final Color badgeText;
                              final String badgeLabel;
                              final Color progressColor;

                              if (isOver) {
                                badgeBg = AppColors.expenseLight;
                                badgeText = const Color(0xFFBE123C);
                                badgeLabel = '${percentage.round()}% Overbudget!';
                                progressColor = const Color(0xFF991B1B);
                              } else if (isNear) {
                                badgeBg = AppColors.warningLight;
                                badgeText = const Color(0xFFC2410C);
                                badgeLabel = '${percentage.round()}% Waspada';
                                progressColor = const Color(0xFF92400E);
                              } else {
                                badgeBg = AppColors.incomeLight;
                                badgeText = const Color(0xFF047857);
                                badgeLabel = '${percentage.round()}% Aman';
                                progressColor = const Color(0xFF065F46);
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isOver
                                        ? const Color(0xFFFECDD3)
                                        : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                          isDark ? 0.15 : 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.bgDark
                                                : categoryBackground(catName),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            categoryIcon(catName),
                                            size: 22,
                                            color: isDark
                                                ? AppColors.accent
                                                : categoryIconColor(catName),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                catName,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Batas ${formatRupiahTx(limit)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: subTextColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            badgeLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: badgeText,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          onTap: () =>
                                              _showSetBudgetDialog(b),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.surfaceDarkHigh
                                                  : const Color(0xFFF1F5F9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: 15,
                                              color: subTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isOver
                                              ? 'Defisit Pengeluaran'
                                              : 'Sisa Anggaran',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: isOver
                                                ? const Color(0xFFBE123C)
                                                : subTextColor,
                                          ),
                                        ),
                                        Text(
                                          isOver
                                              ? '-${formatRupiahTx((spent - limit).abs())}'
                                              : formatRupiahTx((limit - spent)
                                                  .clamp(0, double.infinity)),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isOver
                                                ? const Color(0xFFBE123C)
                                                : textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: limit > 0
                                            ? (spent / limit).clamp(0.0, 1.0)
                                            : 0.0,
                                        minHeight: 6,
                                        backgroundColor: isDark
                                            ? AppColors.surfaceDarkHigh
                                            : const Color(0xFFF1F5F9),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                progressColor),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                          // ── 5. Tips FinChat Card (Tanpa "AI") ──────
                          if (_showTips)
                            Container(
                              margin:
                                  const EdgeInsets.only(top: 8, bottom: 24),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF28238C),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF28238C)
                                        .withOpacity(0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.smart_toy_outlined,
                                          size: 16,
                                          color: Color(0xFF28238C),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Tips FinChat',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Solusi Cepat',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTipsContent(),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFF28238C),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                        ),
                                        onPressed: () => _showSetBudgetDialog(),
                                        child: const Text(
                                          'Alihkan Anggaran',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => setState(
                                            () => _showTips = false),
                                        child: const Text(
                                          'Tutup',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
      ),
    );
  }
}
