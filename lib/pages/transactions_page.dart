import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/category_helper.dart';
import '../utils/date_helper.dart';
import '../widgets/transactions/cash_flow_card.dart';
import '../widgets/transactions/filter_chip_bar.dart';
import '../widgets/transactions/transaction_card.dart';
import '../widgets/transactions/transaction_states.dart';
import 'add_transaction_page.dart';
import 'transaction_detail_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool loading = true;
  String? error;

  List<dynamic> transactions = [];

  String searchQuery = '';
  String selectedType = 'Semua';
  String selectedCategory = ''; // '' = semua kategori

  /// Bulan yang sedang dilihat.
  DateTime selectedMonth = DateTime.now();

  /// null = semua tanggal dalam bulan; ada value = filter tanggal tertentu.
  DateTime? selectedDate;

  // ── Lifecycle ───────────────────────────────────

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // ── Data ────────────────────────────────────────

  Future<void> loadTransactions() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.getTransactions();
      if (!mounted) return;
      setState(() {
        transactions = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  // ── Filter ──────────────────────────────────────

  List<dynamic> get monthTransactions {
    return transactions.where((item) {
      final date = parseDate(item['date']);
      if (date == null) return false;
      return date.year == selectedMonth.year && date.month == selectedMonth.month;
    }).toList();
  }

  List<dynamic> get filteredTransactions {
    var result = List<dynamic>.from(monthTransactions);

    if (selectedDate != null) {
      result = result.where((item) {
        final date = parseDate(item['date']);
        if (date == null) return false;
        return date.year == selectedDate!.year &&
            date.month == selectedDate!.month &&
            date.day == selectedDate!.day;
      }).toList();
    }

    if (selectedType == 'Pemasukan') result = result.where((i) => i['type'] == 'income').toList();
    if (selectedType == 'Pengeluaran') result = result.where((i) => i['type'] == 'expense').toList();

    if (selectedCategory.isNotEmpty) {
      result = result.where((i) => categoryName(i).toLowerCase() == selectedCategory.toLowerCase()).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((item) {
        final desc = item['description']?.toString().toLowerCase() ?? '';
        final cat = categoryName(item).toLowerCase();
        final src = paymentMethodName(item['source']).toLowerCase();
        return desc.contains(query) || cat.contains(query) || src.contains(query);
      }).toList();
    }

    result.sort((a, b) {
      final dateA = parseDateTime(a['created_at'], a['date']);
      final dateB = parseDateTime(b['created_at'], b['date']);
      return dateB.compareTo(dateA);
    });

    return result;
  }

  // ── Cash flow ───────────────────────────────────

  double get totalIncome => monthTransactions
      .where((i) => i['type'] == 'income')
      .fold(0, (sum, i) => sum + amountValue(i['amount']));

  double get totalExpense => monthTransactions
      .where((i) => i['type'] == 'expense')
      .fold(0, (sum, i) => sum + amountValue(i['amount']));

  int get incomeCount => monthTransactions.where((i) => i['type'] == 'income').length;
  int get expenseCount => monthTransactions.where((i) => i['type'] == 'expense').length;

  // ── Actions ─────────────────────────────────────

  void clearDateFilter() => setState(() => selectedDate = null);

  Future<void> pickSpecificDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Pilih tanggal',
    );
    if (selected == null) return;
    setState(() {
      selectedMonth = DateTime(selected.year, selected.month);
      selectedDate = selected;
    });
  }

  Future<void> pickMonth() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int tempYear = selectedMonth.year;
    int tempMonth = selectedMonth.month;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  'Pilih Bulan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // Tahun
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setSheetState(() => tempYear++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Grid bulan
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
                    final isSelected = m == tempMonth;
                    final selectedBg = isDark ? const Color(0xFF10B981) : Colors.black;
                    final selectedText = isDark ? Colors.black : Colors.white;
                    final unselectedBg = isDark ? const Color(0xFF1E2420) : const Color(0xFFF1F5F9);
                    final unselectedText = isDark ? const Color(0xFF9CA69E) : const Color(0xFF475569);

                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => tempMonth = m);
                        setState(() {
                          selectedMonth = DateTime(tempYear, tempMonth);
                          selectedDate = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? selectedBg : unselectedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          fullMonthName(m).substring(0, 3),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? selectedText : unselectedText,
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

  // ── Category Picker ─────────────────────────────
  Future<void> _showCategoryPicker() async {
    // Jika sudah ada kategori dipilih, langsung reset
    if (selectedCategory.isNotEmpty) {
      setState(() => selectedCategory = '');
      return;
    }

    // Kumpulkan semua kategori unik dari transaksi bulan ini
    final allCats = monthTransactions
        .map((i) => categoryName(i))
        .toSet()
        .toList()
      ..sort();

    if (allCats.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter Kategori',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih kategori untuk menyaring transaksi',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allCats.map((cat) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedCategory = cat);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon(cat),
                            size: 16,
                            color: isDark ? const Color(0xFF818CF8) : categoryIconColor(cat),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionPage()),
    );
    if (result == true && mounted) await loadTransactions();
  }

  Future<void> openDetail(dynamic item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionDetailPage(transaction: item)),
    );
    if (result == true && mounted) {
      await loadTransactions();
    }
  }

  // ── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? TransactionErrorState(message: error!, onRetry: loadTransactions)
                : _buildBody(),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────

  Widget _buildBody() {
    final items = filteredTransactions;
    final grouped = _groupTransactions(items);

    return RefreshIndicator(
      onRefresh: loadTransactions,
      child: CustomScrollView(
        slivers: [
          // Header bulan
          SliverToBoxAdapter(child: _buildHeader()),

          // Cash flow card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: CashFlowCard(totalIncome: totalIncome, totalExpense: totalExpense, incomeCount: incomeCount, expenseCount: expenseCount),
            ),
          ),

          // Search bar
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            sliver: SliverToBoxAdapter(child: _buildSearchBar()),
          ),

          // Filter chips
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: FilterChipBar(
                selectedType: selectedType,
                onTypeChanged: (t) => setState(() => selectedType = t),
                selectedCategory: selectedCategory,
                onCategoryTap: _showCategoryPicker,
              ),
            ),
          ),

          // Daftar transaksi per grup
          if (items.isEmpty)
            const SliverFillRemaining(child: TransactionEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final key = grouped.keys.elementAt(i);
                    return _buildTransactionGroup(key, grouped[key]!);
                  },
                  childCount: grouped.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark ? const Color(0xFF64748B) : const Color(0xFF4F46E5);
    final selectedDateBg = const Color(0xFF4F46E5);
    final selectedDateFg = Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Judul & Tombol Catat ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Transaksi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Sinkronisasi otomatis real-time',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: openAddTransaction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Catat',
                        style: TextStyle(
                          fontSize: 13,
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

          // ── Filter Bulan & Tanggal ───────────────
          Row(
            children: [
              // Pilih bulan
              Expanded(
                child: GestureDetector(
                  onTap: pickMonth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 16, color: iconColor),
                        const SizedBox(width: 7),
                        Text(
                          '${fullMonthName(selectedMonth.month)} ${selectedMonth.year}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: iconColor),
                        ),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: iconColor.withOpacity(.5)),
                      ],
                    ),
                  ),
                ),
              ),

          const SizedBox(width: 10),

          // Pilih tanggal spesifik
          GestureDetector(
            onTap: pickSpecificDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selectedDate != null ? selectedDateBg : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: selectedDate != null ? selectedDateFg : subtitleColor,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    selectedDate == null
                        ? 'Pilih tanggal'
                        : '${selectedDate!.day} ${monthName(selectedDate!.month)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selectedDate != null ? selectedDateFg : subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (selectedDate != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: clearDateFilter,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(.55),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Search ───────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Cari transaksi, kategori, metode...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.45),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 21,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.65),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ── Group ─────────────────────────────────────────

  Map<String, List<dynamic>> _groupTransactions(List<dynamic> items) {
    final grouped = <String, List<dynamic>>{};
    for (final item in items) {
      final key = dayLabel(item['date']);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }
    return grouped;
  }

  Widget _buildTransactionGroup(String title, List<dynamic> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double income = 0;
    double expense = 0;
    for (final item in items) {
      if (item['type'] == 'income') {
        income += amountValue(item['amount']);
      } else {
        expense += amountValue(item['amount']);
      }
    }
    final net = income - expense;
    final labelColor = isDark ? const Color(0xFF737D75) : const Color(0xFF475569);

    return Padding(
      padding: const EdgeInsets.only(top: 9, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: net >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                      color: labelColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: net >= 0
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${net >= 0 ? '+' : '-'}${formatShortRupiah(net.abs())}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: net >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),

          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: TransactionCard(item: item, onTap: () => openDetail(item)),
            ),
          ),
        ],
      ),
    );
  }
}
