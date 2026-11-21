import 'budget_page.dart';
import 'dart:math';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../utils/category_helper.dart';
import '../widgets/reports/donut_chart.dart';
import '../widgets/reports/export_report_modal.dart';

enum ReportFilterType {
  thisMonth,
  lastMonth,
  quarter,
  year,
  customMonth,
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Data transaksi & grafik dari backend
  List<dynamic> _transactions = [];
  List<dynamic> _dashboardChart = [];
  Map<String, dynamic> _budgetSummary = {};

  // Filter Periode Global
  DateTime _selectedMonth = DateTime.now();
  ReportFilterType _filterType = ReportFilterType.thisMonth;

  static const List<String> _monthsFull = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final txFuture = ApiService.getTransactions();
      final chartFuture = ApiService.getDashboardChart();
      final budgetFuture = ApiService.getBudgets();

      final results = await Future.wait([txFuture, chartFuture, budgetFuture]);

      final txList = results[0] as List<dynamic>;
      final chartResp = results[1] as Map<String, dynamic>;
      final budgetResp = results[2] as Map<String, dynamic>;
      final rawChart = chartResp['data'];
      final rawSummary = budgetResp['summary'];

      setState(() {
        _transactions = txList;
        _budgetSummary = (rawSummary is Map<String, dynamic>) ? rawSummary : {};
        if (rawChart is List<dynamic>) {
          _dashboardChart = rawChart;
        } else if (rawChart is Map<String, dynamic> && rawChart['monthly_data'] is List<dynamic>) {
          _dashboardChart = rawChart['monthly_data'];
        } else {
          _dashboardChart = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Helper Rentang Tanggal ──────────────────────────────────────

  int _getQuarter(int month) => ((month - 1) ~/ 3) + 1;

  String _getDateRangeLabel() {
    final y = _selectedMonth.year;
    final m = _selectedMonth.month;

    switch (_filterType) {
      case ReportFilterType.thisMonth:
      case ReportFilterType.lastMonth:
      case ReportFilterType.customMonth:
        final lastDay = DateTime(y, m + 1, 0).day;
        final mShort = _monthsShort[m - 1];
        return '01 $mShort $y - $lastDay $mShort $y';

      case ReportFilterType.quarter:
        final q = _getQuarter(m);
        final startM = (q - 1) * 3 + 1;
        final endM = q * 3;
        final lastDay = DateTime(y, endM + 1, 0).day;
        return '01 ${_monthsShort[startM - 1]} $y - $lastDay ${_monthsShort[endM - 1]} $y';

      case ReportFilterType.year:
        return '01 Jan $y - 31 Des $y';
    }
  }

  String _getPeriodTitle() {
    final y = _selectedMonth.year;
    final m = _selectedMonth.month;

    switch (_filterType) {
      case ReportFilterType.thisMonth:
        return 'Bulan Ini (${_monthsShort[m - 1]} $y)';
      case ReportFilterType.lastMonth:
        return 'Bulan Lalu (${_monthsShort[m - 1]} $y)';
      case ReportFilterType.customMonth:
        return '${_monthsFull[m - 1]} $y';
      case ReportFilterType.quarter:
        return 'Q${_getQuarter(m)} $y';
      case ReportFilterType.year:
        return 'Tahun $y';
    }
  }

  String _getPeriodShortBadge() {
    final y = _selectedMonth.year;
    final m = _selectedMonth.month;

    switch (_filterType) {
      case ReportFilterType.thisMonth:
      case ReportFilterType.lastMonth:
      case ReportFilterType.customMonth:
        return '${_monthsShort[m - 1]} $y';
      case ReportFilterType.quarter:
        return 'Q${_getQuarter(m)} $y';
      case ReportFilterType.year:
        return 'Tahun $y';
    }
  }

  // ── Filter Transaksi Berdasarkan Periode Global ──────────────────

  List<dynamic> _getFilteredTransactions() {
    final y = _selectedMonth.year;
    final m = _selectedMonth.month;

    return _transactions.where((tx) {
      final dateStr = tx['date']?.toString();
      if (dateStr == null) return false;
      final txDate = DateTime.tryParse(dateStr);
      if (txDate == null) return false;

      switch (_filterType) {
        case ReportFilterType.thisMonth:
        case ReportFilterType.lastMonth:
        case ReportFilterType.customMonth:
          return txDate.year == y && txDate.month == m;

        case ReportFilterType.quarter:
          final q = _getQuarter(m);
          final startM = (q - 1) * 3 + 1;
          final endM = q * 3;
          return txDate.year == y && txDate.month >= startM && txDate.month <= endM;

        case ReportFilterType.year:
          return txDate.year == y;
      }
    }).toList();
  }

  List<CategoryDonutData> _getCategoryDonutItems(List<dynamic> filteredExpenses) {
    if (filteredExpenses.isEmpty) return [];

    final Map<String, double> categorySums = {};

    for (final tx in filteredExpenses) {
      final cat = categoryName(tx);
      final rawAmount = tx['amount'] ?? 0;
      final amount = (rawAmount is num)
          ? rawAmount.toDouble()
          : (double.tryParse(rawAmount.toString()) ?? 0.0);
      categorySums[cat] = (categorySums[cat] ?? 0.0) + amount;
    }

    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<Color> palette = [
      AppColors.brandBlue,
      AppColors.expense,
      AppColors.income,
      AppColors.warning,
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF64748B), // Slate
    ];

    return List.generate(sortedEntries.length, (i) {
      final entry = sortedEntries[i];
      final color = palette[i % palette.length];
      final icon = categoryIcon(entry.key);
      return CategoryDonutData(
        name: entry.key,
        amount: entry.value,
        color: color,
        icon: icon,
      );
    });
  }

  // ── Modal Bottom Sheet "Pilih Bulan" (Sama dengan Transaksi) ─────

  Future<void> _showMonthPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int tempYear = _selectedMonth.year;
    int tempMonth = _selectedMonth.month;

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF292F2B) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pilih Bulan Laporan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Bar Ganti Tahun
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setSheetState(() => tempYear--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '$tempYear',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setSheetState(() => tempYear++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Grid 12 Bulan
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final m = i + 1;
                    final isSelected = m == tempMonth && tempYear == _selectedMonth.year;
                    const selectedBg = Color(0xFF5B4DFF); // Purple FinChat
                    final unselectedBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
                    final unselectedText = isDark ? AppColors.textDarkSecondary : const Color(0xFF475569);

                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => tempMonth = m);
                        setState(() {
                          _selectedMonth = DateTime(tempYear, m);
                          final now = DateTime.now();
                          if (tempYear == now.year && m == now.month) {
                            _filterType = ReportFilterType.thisMonth;
                          } else if (tempYear == now.year && m == now.month - 1) {
                            _filterType = ReportFilterType.lastMonth;
                          } else {
                            _filterType = ReportFilterType.customMonth;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? selectedBg : unselectedBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _monthsShort[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : unselectedText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openExportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExportReportModal(selectedMonth: _selectedMonth),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5B4DFF)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.expense),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadReportData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Hitung seluruh agregasi berdasarkan transaksi periode aktif
    final periodTransactions = _getFilteredTransactions();

    double periodIncome = 0.0;
    double periodExpense = 0.0;
    final List<dynamic> periodExpenseTxs = [];

    for (final tx in periodTransactions) {
      final type = tx['type']?.toString().toLowerCase();
      final rawAmount = tx['amount'] ?? 0;
      final amt = (rawAmount is num)
          ? rawAmount.toDouble()
          : (double.tryParse(rawAmount.toString()) ?? 0.0);

      if (type == 'income' || type == 'pemasukan') {
        periodIncome += amt;
      } else if (type == 'expense' || type == 'pengeluaran') {
        periodExpense += amt;
        periodExpenseTxs.add(tx);
      }
    }

    final periodNetBalance = periodIncome - periodExpense;
    final donutItems = _getCategoryDonutItems(periodExpenseTxs);

    final now = DateTime.now();
    final currentQ = _getQuarter(now.month);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReportData,
          color: const Color(0xFF5B4DFF),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Header: Laporan Keuangan + Tombol Unduh ───────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B4DFF).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            size: 22,
                            color: Color(0xFF5B4DFF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan Keuangan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ikhtisar performa & akun personal',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Tombol Ekspor (Unduh PDF / Excel)
                    GestureDetector(
                      onTap: _openExportModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4DFF),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5B4DFF).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_rounded, size: 15, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Unduh',
                              style: TextStyle(
                                fontSize: 11.5,
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

                const SizedBox(height: 14),

                // ── 2. Card Pemilih Rentang Tanggal (Date Bar) ───────
                GestureDetector(
                  onTap: _showMonthPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Color(0xFF5B4DFF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _getDateRangeLabel(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.expand_more,
                          size: 20,
                          color: secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── 3. Quick Filter Period Chips ────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Bulan Ini
                      _buildQuickPill(
                        label: 'Bulan Ini',
                        isSelected: _filterType == ReportFilterType.thisMonth,
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime(now.year, now.month);
                            _filterType = ReportFilterType.thisMonth;
                          });
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Bulan Lalu
                      _buildQuickPill(
                        label: 'Bulan Lalu',
                        isSelected: _filterType == ReportFilterType.lastMonth,
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime(now.year, now.month - 1);
                            _filterType = ReportFilterType.lastMonth;
                          });
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Kuartal (Q3 2026 dll)
                      _buildQuickPill(
                        label: 'Q$currentQ ${now.year}',
                        isSelected: _filterType == ReportFilterType.quarter,
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime(now.year, (currentQ - 1) * 3 + 1);
                            _filterType = ReportFilterType.quarter;
                          });
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),

                      // Tahun Ini
                      _buildQuickPill(
                        label: 'Tahun ${now.year}',
                        isSelected: _filterType == ReportFilterType.year,
                        onTap: () {
                          setState(() {
                            _selectedMonth = DateTime(now.year, 1);
                            _filterType = ReportFilterType.year;
                          });
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── 4. Card Arus Kas Periode Terpilih ────────────────
                _buildCashFlowCard(
                  isDark: isDark,
                  net: periodNetBalance,
                  income: periodIncome,
                  expense: periodExpense,
                  periodTitle: _getPeriodTitle(),
                ),

                const SizedBox(height: 16),

                // ── 4.5. Card Total Seluruh Anggaran ─────────────────
                _buildOverallBudgetCard(isDark),

                const SizedBox(height: 16),

                // ── 5. Card Donut Kategori Pengeluaran (Filter lokal dihapus!) ──
                _buildCategoryDonutCard(
                  isDark: isDark,
                  donutItems: donutItems,
                  totalPeriodExpense: periodExpense,
                  badgeLabel: _getPeriodShortBadge(),
                ),

                const SizedBox(height: 16),

                // ── 6. Grafik Tren Perbandingan 6 Bulan ──────────────
                _buildComparisonChart(isDark),

                const SizedBox(height: 16),

                // ── 7. Indikator Kesehatan Finansial ─────────────────
                _buildHealthCheckCard(isDark, periodIncome, periodExpense),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget Quick Pill ─────────────────────────────────────────────

  Widget _buildQuickPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const activeColor = Color(0xFF5B4DFF);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textDarkSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ── Cash Flow Card ────────────────────────────────────────────────

  Widget _buildCashFlowCard({
    required bool isDark,
    required double net,
    required double income,
    required double expense,
    required String periodTitle,
  }) {
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4DFF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, color: Color(0xFF5B4DFF), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arus Kas $periodTitle',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Ringkasan mutasi keuangan',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Baris Saldo Bersih
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo Bersih',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
                Text(
                  formatRupiahTx(net),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: net >= 0 ? const Color(0xFF059669) : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Pemasukan & Pengeluaran
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  label: 'Pemasukan',
                  amount: income,
                  color: const Color(0xFF059669),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  label: 'Pengeluaran',
                  amount: expense,
                  color: const Color(0xFFEF4444),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRupiahTx(amount),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overall Budget Card (Seluruh Anggaran Pengguna) ────────────

  Widget _buildOverallBudgetCard(bool isDark) {
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    final totalLimit = amountValue(_budgetSummary['total_limit']);
    final totalSpent = amountValue(_budgetSummary['total_spent']);
    final totalRemaining = amountValue(_budgetSummary['total_remaining']);
    final overallPercent = _budgetSummary['overall_percentage'] != null
        ? amountValue(_budgetSummary['overall_percentage'])
        : 0.0;
    final hasBudget = totalLimit > 0;
    final isOver = _budgetSummary['is_over_limit'] == true || (hasBudget && totalSpent > totalLimit);
    final isNear = overallPercent >= 80.0 && !isOver;

    final Color statusColor;
    final Color badgeBg;
    final String badgeText;

    if (isOver) {
      statusColor = const Color(0xFFEF4444);
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = 'Melebihi Batas!';
    } else if (isNear) {
      statusColor = const Color(0xFFF59E0B);
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = '${overallPercent.toInt()}% (Waspada)';
    } else {
      statusColor = const Color(0xFF10B981);
      badgeBg = isDark ? const Color(0xFF0F3924) : const Color(0xFFD1FAE5);
      badgeText = '${overallPercent.toInt()}% (Aman)';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOver ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Total Anggaran',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Akumulasi seluruh batas pengeluaran',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? statusColor.withOpacity(0.18) : badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasBudget ? badgeText : 'Belum Ada',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Limit', style: TextStyle(fontSize: 10.5, color: secondaryText)),
                      const SizedBox(height: 2),
                      Text(
                        hasBudget ? formatRupiahTx(totalLimit) : 'Rp 0',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Terpakai', style: TextStyle(fontSize: 10.5, color: secondaryText)),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiahTx(totalSpent),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isOver ? Colors.red : textColor),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sisa', style: TextStyle(fontSize: 10.5, color: secondaryText)),
                      const SizedBox(height: 2),
                      Text(
                        formatRupiahTx(totalRemaining),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: hasBudget ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetPage()),
              );
              _loadReportData();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasBudget ? 'Kelola rincian anggaran per kategori' : 'Tentukan batas anggaran sekarang',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B4DFF),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF5B4DFF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Donut Category Card (Filter lokal dihapus!) ───────────────────

  Widget _buildCategoryDonutCard({
    required bool isDark,
    required List<CategoryDonutData> donutItems,
    required double totalPeriodExpense,
    required String badgeLabel,
  }) {
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.donut_large_rounded, color: AppColors.expense, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori Pengeluaran',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Distribusi porsi biaya',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Badge Periode Aktif
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4DFF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B4DFF),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Donut Chart Widget
          Center(
            child: DonutChartWidget(
              items: donutItems,
              centerTitle: 'Total Pengeluaran',
              centerSubtitle: formatShortRupiah(totalPeriodExpense),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6-Month Comparison Chart ──────────────────────────────────────

  Widget _buildComparisonChart(bool isDark) {
    final monthlyData = _dashboardChart;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF06B6D4), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perbandingan Arus Kas',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Tren pemasukan & pengeluaran historis',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (monthlyData.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Belum ada data grafik perbandingan')),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildLegendItem(const Color(0xFF059669), 'Pemasukan', isDark),
                const SizedBox(width: 14),
                _buildLegendItem(const Color(0xFFEF4444), 'Pengeluaran', isDark),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: _buildBarChart(monthlyData, isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, bool isDark) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<dynamic> monthlyData, bool isDark) {
    double maxVal = 1;
    for (final item in monthlyData) {
      final inc = (item['income'] ?? 0).toDouble();
      final exp = (item['expense'] ?? 0).toDouble();
      maxVal = max(maxVal, max(inc, exp));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyData.map((item) {
        final month = item['month'] ?? '';
        final inc = (item['income'] ?? 0).toDouble();
        final exp = (item['expense'] ?? 0).toDouble();

        final incHeight = (inc / maxVal) * 100;
        final expHeight = (exp / maxVal) * 100;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 7,
                    height: max(4.0, incHeight),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 7,
                    height: max(4.0, expHeight),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                month.length > 3 ? month.substring(0, 3) : month,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Financial Health Indicator ────────────────────────────────────

  Widget _buildHealthCheckCard(bool isDark, double income, double expense) {
    final double ratio = income > 0 ? (expense / income) * 100 : (expense > 0 ? 100.0 : 0.0);

    String healthStatus;
    Color healthColor;
    String healthAdvice;

    if (income == 0 && expense == 0) {
      healthStatus = 'Netral';
      healthColor = AppColors.brandBlue;
      healthAdvice = 'Belum ada transaksi pada periode yang dipilih.';
    } else if (ratio <= 50) {
      healthStatus = 'Sangat Sehat';
      healthColor = const Color(0xFF059669);
      healthAdvice = 'Pengeluaran Anda terkontrol dengan baik di bawah 50% dari pemasukan!';
    } else if (ratio <= 80) {
      healthStatus = 'Cukup Baik';
      healthColor = const Color(0xFFF59E0B);
      healthAdvice = 'Pengeluaran mendekati batas ideal. Tetap jaga alokasi tabungan Anda.';
    } else {
      healthStatus = 'Perlu Waspada';
      healthColor = const Color(0xFFEF4444);
      healthAdvice = 'Pengeluaran melampaui 80% pemasukan. Evaluasi pengeluaran non-primer.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: healthColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.favorite_rounded, color: healthColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kondisi Finansial',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: healthColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        healthStatus,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: healthColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  healthAdvice,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
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
