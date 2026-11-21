import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../utils/format_helper.dart';
import '../utils/input_formatters.dart';

// ─── Konstanta Warna Tema App ─────────────────────
const _cNavy       = Color(0xFF172033);
const _cGreen      = Color(0xFF16A34A);
const _cRed        = Color(0xFFEF4444);
const _cBg         = Color(0xFFF8FAFC);
const _cBorder     = Color(0xFFE2E8F0);
const _cSubtext    = Color(0xFF64748B);

class AddTransactionPage extends StatefulWidget {
  final dynamic transactionToEdit;

  const AddTransactionPage({
    super.key,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _type;
  late String _source;
  int? _selectedWalletId;
  List<Wallet> _wallets = [];
  bool _loadingWallets = true;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  bool _loadingCategories = true;
  bool _saving = false;

  late DateTime _selectedDate;

  bool get isEditing => widget.transactionToEdit != null;

  // Index tab: 0=expense, 1=income
  int get _typeIndex => _type == 'income' ? 1 : 0;

  @override
  void initState() {
    super.initState();
    final tx = widget.transactionToEdit;

    _type   = tx?['type']?.toString() ?? 'expense';
    _source = tx?['source']?.toString() ?? 'cash';

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _typeIndex,
    );
    _tabController.addListener(_onTabChanged);

    if (tx != null && tx['wallet_id'] != null) {
      _selectedWalletId = tx['wallet_id'] is int
          ? tx['wallet_id']
          : int.tryParse(tx['wallet_id'].toString());
    }

    if (tx != null) {
      final double amt = (tx['amount'] is num)
          ? (tx['amount'] as num).toDouble()
          : (double.tryParse(tx['amount']?.toString() ?? '0') ?? 0);
      final formattedAmt = amt
          .round()
          .toString()
          .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
      _amountController.text = formattedAmt;
      _descriptionController.text = tx['description']?.toString() ?? '';

      final cat = tx['category'];
      if (cat is Map && cat['id'] != null) {
        _selectedCategoryId = cat['id'] is int
            ? cat['id']
            : int.tryParse(cat['id'].toString());
      } else if (tx['category_id'] != null) {
        _selectedCategoryId = tx['category_id'] is int
            ? tx['category_id']
            : int.tryParse(tx['category_id'].toString());
      }

      final parsedD =
          DateTime.tryParse(tx['date']?.toString() ?? '') ??
          DateTime.tryParse(tx['created_at']?.toString() ?? '');
      _selectedDate = parsedD ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }

    _loadCategories();
    _loadWallets();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final newType = _tabController.index == 1 ? 'income' : 'expense';
    if (_type != newType) {
      setState(() {
        _type = newType;
        _selectedCategoryId = null;
      });
      _loadCategories();
    }
  }

  Future<void> _loadWallets() async {
    setState(() => _loadingWallets = true);
    try {
      final res  = await ApiService.getWallets();
      final raw  = res['wallets'] as List? ?? [];
      final List<Wallet> loaded = [];
      for (var item in raw) {
        if (item is Map<String, dynamic>) loaded.add(Wallet.fromJson(item));
      }
      if (!mounted) return;
      setState(() {
        _wallets = loaded;
        if (_selectedWalletId == null && loaded.isNotEmpty) {
          _selectedWalletId = loaded.first.id;
          _source           = loaded.first.type;
        } else if (_selectedWalletId != null) {
          final m = loaded.where((w) => w.id == _selectedWalletId);
          if (m.isNotEmpty) _source = m.first.type;
        }
        _loadingWallets = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingWallets = false);
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final cats = await ApiService.getCategories(_type);
      if (!mounted) return;
      setState(() {
        _categories = cats;
        if (_selectedCategoryId == null ||
            !cats.any((c) => c['id'] == _selectedCategoryId)) {
          _selectedCategoryId =
              cats.isNotEmpty ? cats.first['id'] : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengambil kategori: $e');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.trim().isEmpty) {
      _showMessage('Nominal wajib diisi');
      return;
    }
    if (_selectedCategoryId == null) {
      _showMessage('Kategori wajib dipilih');
      return;
    }

    final amountText = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessage('Nominal tidak valid');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Catatan wajib diisi');
      return;
    }

    // FR-103: saldo tidak cukup
    if (_type == 'expense' &&
        _selectedWalletId != null &&
        _wallets.isNotEmpty) {
      final m = _wallets.where((w) => w.id == _selectedWalletId);
      if (m.isNotEmpty && amount > m.first.currentBalance) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _cRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: _cRed, size: 20),
                ),
                const SizedBox(width: 10),
                Text('Saldo Tidak Cukup',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkPrimary : _cNavy)),
              ]),
              content: Text(
                'Nominal pengeluaran (${formatRupiah(amount)}) melebihi '
                'saldo dompet "${m.first.name}" '
                '(${formatRupiah(m.first.currentBalance)}).\n\n'
                'Saldo akan menjadi minus. Tetap simpan?',
                style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? AppColors.textDarkSecondary : _cNavy),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Batal',
                      style: TextStyle(color: isDark ? AppColors.textDarkSecondary : _cSubtext)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Tetap Simpan',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
        if (proceed != true) return;
      }
    }

    setState(() => _saving = true);
    try {
      if (isEditing) {
        var txId = widget.transactionToEdit['id']?.toString() ?? '';
        if (!txId.startsWith('exp-') && !txId.startsWith('inc-')) {
          txId = '${_type == 'income' ? 'inc' : 'exp'}-$txId';
        }
        await ApiService.updateTransaction(
          txId,
          type: _type,
          amount: amount,
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          source: _source,
          walletId: _selectedWalletId,
          date: _formatApiDate(_selectedDate),
        );
      } else {
        await ApiService.createTransaction(
          type: _type,
          amount: amount,
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          source: _source,
          walletId: _selectedWalletId,
          date: _formatApiDate(_selectedDate),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEditing
            ? 'Transaksi berhasil diperbarui'
            : 'Transaksi berhasil disimpan'),
        backgroundColor: _cGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
                  primary: AppColors.primaryBrand,
                  onPrimary: Colors.white,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textDarkPrimary,
                )
              : const ColorScheme.light(
                  primary: _cNavy,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: _cNavy,
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatApiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ─── Helpers ──────────────────────────────────────

  Wallet? get _selectedWallet {
    if (_selectedWalletId == null || _wallets.isEmpty) return null;
    final m = _wallets.where((w) => w.id == _selectedWalletId);
    return m.isNotEmpty ? m.first : null;
  }

  double get _previewBalance {
    final w = _selectedWallet;
    if (w == null) return 0;
    final clean = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final amt = double.tryParse(clean) ?? 0.0;
    return _type == 'income' ? w.currentBalance + amt : w.currentBalance - amt;
  }

  // ─── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == 'expense';
    final typeColor = isExpense ? _cRed : _cGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : _cBg;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : _cBorder;
    final textColor = isDark ? AppColors.textDarkPrimary : _cNavy;
    final subtextColor = isDark ? AppColors.textDarkSecondary : _cSubtext;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header Gradient ──────────────────────
          _buildHeader(isExpense, typeColor),

          // ── Form Body ───────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sumber Dana
                  _buildSectionLabel('Sumber Dana', subtextColor),
                  const SizedBox(height: 10),
                  _buildWalletChips(isDark, cardBg, borderColor, textColor, subtextColor),

                  // Balance preview
                  if (_selectedWallet != null) ...[
                    const SizedBox(height: 10),
                    _buildBalancePreview(isDark),
                  ],

                  const SizedBox(height: 20),

                  // Kategori
                  _buildSectionLabel('Kategori', subtextColor),
                  const SizedBox(height: 10),
                  _buildCategoryDropdown(isDark, cardBg, borderColor, textColor, subtextColor),

                  const SizedBox(height: 20),

                  // Tanggal
                  _buildSectionLabel('Tanggal', subtextColor),
                  const SizedBox(height: 10),
                  _buildDatePicker(isDark, cardBg, borderColor, textColor, subtextColor),

                  const SizedBox(height: 20),

                  // Catatan
                  _buildSectionLabel('Catatan', subtextColor),
                  const SizedBox(height: 10),
                  _buildNoteField(isDark, cardBg, borderColor, textColor, subtextColor),

                  const SizedBox(height: 28),

                  // Tombol Simpan
                  _buildSaveButton(typeColor),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header: AppBar + Tab Jenis + Nominal ──────────
  Widget _buildHeader(bool isExpense, Color typeColor) {
    return Container(
      decoration: BoxDecoration(
        color: typeColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Transaksi' : 'Catat Transaksi',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance for back button
                ],
              ),
            ),

            // Tab Pengeluaran / Pemasukan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: typeColor,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: '↓  Pengeluaran'),
                    Tab(text: '↑  Pemasukan'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nominal input besar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Ubah Nominal' : 'Nominal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rp',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Theme(
                          data: ThemeData(
                            textSelectionTheme: const TextSelectionThemeData(
                              cursorColor: Colors.white,
                              selectionColor: Colors.white30,
                              selectionHandleColor: Colors.white,
                            ),
                            inputDecorationTheme: const InputDecorationTheme(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                          child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: (_) => setState(() {}),
                          cursorColor: Colors.white,
                          cursorWidth: 2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        ),  // Theme
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────
  Widget _buildSectionLabel(String text, Color subtextColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: subtextColor,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Wallet Chips ──────────────────────────────────
  Widget _buildWalletChips(bool isDark, Color cardBg, Color borderColor, Color textColor, Color subtextColor) {
    if (_loadingWallets) {
      return _LoadingBox(text: 'Memuat dompet...', cardBg: cardBg, borderColor: borderColor, subtextColor: subtextColor);
    }
    if (_wallets.isEmpty) {
      return _LoadingBox(text: 'Belum ada sumber dana', cardBg: cardBg, borderColor: borderColor, subtextColor: subtextColor);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wallets.map((w) {
        final isSel = _selectedWalletId == w.id;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedWalletId = w.id;
            _source = w.type;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSel
                  ? (isDark ? const Color(0xFF312E81).withOpacity(0.4) : _cNavy.withOpacity(0.07))
                  : cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSel ? (isDark ? const Color(0xFF818CF8) : _cNavy) : borderColor,
                width: isSel ? 1.8 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: (isSel ? (isDark ? const Color(0xFF818CF8) : _cNavy) : w.parsedColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    w.iconData,
                    size: 13,
                    color: isSel ? (isDark ? const Color(0xFF818CF8) : _cNavy) : w.parsedColor,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  w.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSel ? (isDark ? const Color(0xFFA5B4FC) : _cNavy) : textColor,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  formatRupiah(w.currentBalance),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSel
                        ? (isDark ? const Color(0xFFA5B4FC).withOpacity(0.8) : _cNavy.withOpacity(0.65))
                        : subtextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Balance Preview ───────────────────────────────
  Widget _buildBalancePreview(bool isDark) {
    final w    = _selectedWallet!;
    final bal  = _previewBalance;
    final isNeg = bal < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isNeg
            ? _cRed.withOpacity(isDark ? 0.15 : 0.07)
            : _cGreen.withOpacity(isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNeg
              ? _cRed.withOpacity(isDark ? 0.4 : 0.25)
              : _cGreen.withOpacity(isDark ? 0.4 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNeg
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: isNeg ? _cRed : _cGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isNeg
                  ? 'Saldo ${w.name} akan minus: ${formatRupiah(bal)}'
                  : 'Sisa di ${w.name}: ${formatRupiah(bal)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isNeg ? _cRed : _cGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Dropdown ─────────────────────────────
  Widget _buildCategoryDropdown(bool isDark, Color cardBg, Color borderColor, Color textColor, Color subtextColor) {
    if (_loadingCategories) {
      return _LoadingBox(text: 'Memuat kategori...', cardBg: cardBg, borderColor: borderColor, subtextColor: subtextColor);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: cardBg,
          value: _selectedCategoryId,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Pilih kategori',
                style: TextStyle(color: subtextColor)),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: subtextColor),
          ),
          borderRadius: BorderRadius.circular(14),
          items: _categories.map<DropdownMenuItem<int>>((cat) {
            return DropdownMenuItem<int>(
              value: cat['id'],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  cat['name'].toString(),
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
      ),
    );
  }

  // ── Date Picker ───────────────────────────────────
  Widget _buildDatePicker(bool isDark, Color cardBg, Color borderColor, Color textColor, Color subtextColor) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDarkHigh : _cNavy.withOpacity(0.07),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.calendar_month_outlined,
                  size: 18, color: isDark ? AppColors.textDarkPrimary : _cNavy),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDisplayDate(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: subtextColor),
          ],
        ),
      ),
    );
  }

  // ── Note Field ────────────────────────────────────
  Widget _buildNoteField(bool isDark, Color cardBg, Color borderColor, Color textColor, Color subtextColor) {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      decoration: InputDecoration(
        hintText: 'Contoh: Makan siang di kantin, gaji bulan ini...',
        hintStyle:
            TextStyle(color: subtextColor, fontSize: 13),
        filled: true,
        fillColor: cardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: isDark ? AppColors.primaryBrand : _cNavy, width: 1.5),
        ),
      ),
    );
  }

  // ── Save Button ───────────────────────────────────
  Widget _buildSaveButton(Color typeColor) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: typeColor,
          disabledBackgroundColor: typeColor.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditing ? 'Perbarui Transaksi' : 'Simpan Transaksi',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ─── Shared Widget ────────────────────────────────
class _LoadingBox extends StatelessWidget {
  final String text;
  final Color cardBg;
  final Color borderColor;
  final Color subtextColor;

  const _LoadingBox({
    required this.text,
    required this.cardBg,
    required this.borderColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Text(text,
          style: TextStyle(color: subtextColor, fontSize: 13)),
    );
  }
}
