import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants/app_colors.dart';
import '../utils/category_helper.dart';
import '../utils/input_formatters.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> with SingleTickerProviderStateMixin {
  List<dynamic> _savings = [];
  bool _loading = true;
  int _filterIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadSavings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSavings() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getSavings();
      setState(() {
        _savings = data;
        _loading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<dynamic> get _filtered {
    if (_filterIndex == 1) return _savings.where((s) => (s['status'] ?? '') == 'active').toList();
    if (_filterIndex == 2) return _savings.where((s) => (s['status'] ?? '') == 'completed').toList();
    return _savings;
  }

  double get _totalCollected => _savings.fold(0.0, (sum, s) => sum + amountValue(s['current_amount']));
  double get _totalTarget => _savings.fold(0.0, (sum, s) => sum + amountValue(s['target_amount']));
  double get _overallProgress => _totalTarget > 0 ? (_totalCollected / _totalTarget).clamp(0.0, 1.0) : 0.0;
  int get _activeCount => _savings.where((s) => (s['status'] ?? '') == 'active').length;
  int get _completedCount => _savings.where((s) => (s['status'] ?? '') == 'completed').length;

  String _emojiForSaving(dynamic s) {
    final name = ((s['name'] ?? '') + (s['category'] ?? '')).toLowerCase();
    if (name.contains('laptop') || name.contains('komputer') || name.contains('pc') || name.contains('gadget') || name.contains('hp') || name.contains('phone')) return '\u{1F4BB}';
    if (name.contains('liburan') || name.contains('travel') || name.contains('wisata') || name.contains('jalan')) return '\u{2708}\u{FE0F}';
    if (name.contains('motor') || name.contains('mobil') || name.contains('kendaraan')) return '\u{1F697}';
    if (name.contains('rumah') || name.contains('properti') || name.contains('tanah')) return '\u{1F3E0}';
    if (name.contains('nikah') || name.contains('menikah') || name.contains('pernikahan') || name.contains('wedding')) return '\u{1F48D}';
    if (name.contains('darurat') || name.contains('emergency')) return '\u{1F6A8}';
    if (name.contains('pendidikan') || name.contains('kuliah') || name.contains('sekolah') || name.contains('kursus')) return '\u{1F4DA}';
    if (name.contains('investasi') || name.contains('saham') || name.contains('reksa')) return '\u{1F4C8}';
    return '\u{1F3AF}';
  }

  String _daysLabel(dynamic s) {
    final td = s['target_date'];
    if (td == null || td.toString().isEmpty) return '';
    try {
      final date = DateTime.parse(td.toString());
      final now = DateTime.now();
      final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff < 0) return '\u26A0\uFE0F Melewati deadline';
      if (diff == 0) return '\u{1F525} Deadline hari ini!';
      if (diff == 1) return '\u23F0 Besok deadline';
      return '\u{1F4C5} $diff hari lagi';
    } catch (_) {
      return '';
    }
  }

  Future<void> _showAddSavingSheet([dynamic existing]) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final amtCtrl = TextEditingController(
      text: existing != null ? formatRupiahTx(existing['target_amount']).replaceAll('Rp', '').trim() : '',
    );
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    String? selectedCategory = existing?['category'];
    DateTime? selectedDate;
    if (existing?['target_date'] != null && existing!['target_date'].toString().isNotEmpty) {
      try { selectedDate = DateTime.parse(existing['target_date'].toString()); } catch (_) {}
    }

    final categories = [
      {'emoji': '\u{1F3AF}', 'label': 'Umum', 'value': 'umum'},
      {'emoji': '\u{1F4BB}', 'label': 'Gadget', 'value': 'gadget'},
      {'emoji': '\u{2708}\u{FE0F}', 'label': 'Liburan', 'value': 'liburan'},
      {'emoji': '\u{1F697}', 'label': 'Kendaraan', 'value': 'kendaraan'},
      {'emoji': '\u{1F3E0}', 'label': 'Properti', 'value': 'properti'},
      {'emoji': '\u{1F4DA}', 'label': 'Pendidikan', 'value': 'pendidikan'},
      {'emoji': '\u{1F48D}', 'label': 'Menikah', 'value': 'menikah'},
      {'emoji': '\u{1F6A8}', 'label': 'Darurat', 'value': 'darurat'},
    ];

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AnimatedPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          duration: const Duration(milliseconds: 200),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 45, height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(children: [
                    Text(
                      existing == null ? '\u{1F3AF} Target Tabungan Baru' : '\u270F\uFE0F Edit Target',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                    ),
                  ]),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategori', style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                        )),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: categories.map((c) {
                            final sel = selectedCategory == c['value'];
                            return GestureDetector(
                              onTap: () => setModal(() => selectedCategory = c['value'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.primaryBrand : (isDark ? AppColors.bgDark : AppColors.bgLight),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel ? AppColors.primaryBrand : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                ),
                                child: Text(
                                  '${c['emoji']} ${c['label']}',
                                  style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        _inputLabel('Nama Target', isDark),
                        const SizedBox(height: 8),
                        _textField(nameCtrl, 'contoh: Beli Laptop Gaming', isDark),
                        const SizedBox(height: 16),
                        _inputLabel('Target Nominal', isDark),
                        const SizedBox(height: 8),
                        TextField(
                          controller: amtCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                          style: TextStyle(color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
                          decoration: _inputDeco('Rp 0', isDark),
                        ),
                        const SizedBox(height: 16),
                        _inputLabel('Target Tanggal (opsional)', isDark),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2040),
                              builder: (ctx2, child) => Theme(
                                data: Theme.of(ctx2).copyWith(
                                  colorScheme: ColorScheme.fromSeed(
                                    seedColor: AppColors.primaryBrand,
                                    brightness: isDark ? Brightness.dark : Brightness.light,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) setModal(() => selectedDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.bgDark : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today_rounded, size: 18,
                                  color: selectedDate != null ? AppColors.primaryBrand : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary)),
                              const SizedBox(width: 10),
                              Text(
                                selectedDate != null
                                    ? '${selectedDate!.day.toString().padLeft(2,'0')}/${selectedDate!.month.toString().padLeft(2,'0')}/${selectedDate!.year}'
                                    : 'Pilih tanggal target',
                                style: TextStyle(
                                  color: selectedDate != null
                                      ? (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary)
                                      : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                                  fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              if (selectedDate != null)
                                GestureDetector(
                                  onTap: () => setModal(() => selectedDate = null),
                                  child: Icon(Icons.close_rounded, size: 18, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                                ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _inputLabel('Deskripsi (opsional)', isDark),
                        const SizedBox(height: 8),
                        _textField(descCtrl, 'catatan tambahan...', isDark, maxLines: 2),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: saving ? null : () async {
                              final name = nameCtrl.text.trim();
                              final rawAmt = amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                              if (name.isEmpty || rawAmt.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Nama dan nominal target wajib diisi'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setModal(() => saving = true);
                              try {
                                await ApiService.createSaving(
                                  name: name,
                                  targetAmount: double.parse(rawAmt),
                                  category: selectedCategory,
                                  targetDate: selectedDate != null
                                      ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}'
                                      : null,
                                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                );
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                await _loadSavings();
                              } catch (e) {
                                setModal(() => saving = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBrand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    existing == null ? 'Buat Target' : 'Simpan Perubahan',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDepositSheet(dynamic s) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final remaining = amountValue(s['remaining_amount']);
    bool saving = false;
    final quickAmounts = [50000.0, 100000.0, 250000.0, 500000.0];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final rawAmt = double.tryParse(amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final afterDeposit = amountValue(s['current_amount']) + rawAmt;
          final target = amountValue(s['target_amount']);
          final previewPct = target > 0 ? (afterDeposit / target * 100).clamp(0.0, 100.0) : 0.0;

          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 45, height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('\u{1F4B0} Setor Tabungan', style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                        )),
                        Text(s['name'] ?? '', style: TextStyle(
                          fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                        )),
                      ]),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(
                          'Terkumpul: ${formatRupiahTx(s['current_amount'])}',
                          style: TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Target: ${formatRupiahTx(s['target_amount'])}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: amountValue(s['progress']) / 100,
                          backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBrand),
                          minHeight: 8,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _inputLabel('Jumlah Cepat', isDark),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              ...quickAmounts.map((amt) => GestureDetector(
                                onTap: () {
                                  final f = RupiahInputFormatter();
                                  final newVal = f.formatEditUpdate(amtCtrl.value, TextEditingValue(text: amt.toStringAsFixed(0)));
                                  amtCtrl.value = newVal;
                                  setModal(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.bgDark : AppColors.bgLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                  child: Text(
                                    '+${formatRupiahTx(amt)}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBrand),
                                  ),
                                ),
                              )),
                              if (remaining > 0)
                                GestureDetector(
                                  onTap: () {
                                    final f = RupiahInputFormatter();
                                    final newVal = f.formatEditUpdate(amtCtrl.value, TextEditingValue(text: remaining.toStringAsFixed(0)));
                                    amtCtrl.value = newVal;
                                    setModal(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.income),
                                    ),
                                    child: Text(
                                      '\u{1F3AF} Penuhi Target',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.income),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _inputLabel('Jumlah Setoran', isDark),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amtCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [RupiahInputFormatter()],
                            onChanged: (_) => setModal(() {}),
                            style: TextStyle(color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
                            decoration: _inputDeco('Rp 0', isDark),
                          ),
                          if (rawAmt > 0) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBrand.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryBrand),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Setelah setor: ${formatRupiahTx(afterDeposit)} / ${formatRupiahTx(target)} (${previewPct.toStringAsFixed(1)}%)',
                                    style: TextStyle(fontSize: 12, color: AppColors.primaryBrand, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _inputLabel('Catatan (opsional)', isDark),
                          const SizedBox(height: 8),
                          _textField(noteCtrl, 'tambah catatan...', isDark, maxLines: 2),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: saving ? null : () async {
                                final raw = amtCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                                if (raw.isEmpty || double.parse(raw) <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Masukkan jumlah setoran'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                setModal(() => saving = true);
                                try {
                                  final now = DateTime.now();
                                  await ApiService.addSavingDeposit(
                                    savingId: s['id'] as int,
                                    amount: double.parse(raw),
                                    date: '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}',
                                    note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                                  );
                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  await _loadSavings();
                                } catch (e) {
                                  setModal(() => saving = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.income,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: saving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Setor Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showHistorySheet(dynamic s) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<dynamic>? deposits;
    bool loadingDeposits = true;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          if (loadingDeposits) {
            final savingId = (s['id'] is num) ? (s['id'] as num).toInt() : (int.tryParse(s['id']?.toString() ?? '') ?? 0);
            ApiService.getSavingDeposits(savingId).then((data) {
              setModal(() { deposits = data; loadingDeposits = false; });
            }).catchError((e) {
              setModal(() { errorMsg = e.toString().replaceFirst('Exception: ', ''); loadingDeposits = false; });
            });
          }

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 45, height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('\u{1F4CB} Riwayat Setoran', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      )),
                      Text(s['name'] ?? '', style: TextStyle(
                        fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                      )),
                    ]),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                    ),
                  ]),
                ),
                const Divider(height: 1),
                Flexible(
                  child: loadingDeposits
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ))
                      : errorMsg != null
                          ? Center(child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text('Gagal memuat: $errorMsg', style: const TextStyle(color: Colors.red)),
                            ))
                          : (deposits == null || deposits!.isEmpty)
                              ? Center(child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                                    const Text('\u{1F4B8}', style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 12),
                                    Text('Belum ada setoran', style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                    )),
                                    const SizedBox(height: 4),
                                    Text('Mulai setor untuk mencapai target!', style: TextStyle(
                                      fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                                    )),
                                  ]),
                                ))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  itemCount: deposits!.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final d = deposits![i];
                                    final dateStr = d['date']?.toString() ?? '';
                                    String formattedDate = dateStr;
                                    try {
                                      final dt = DateTime.parse(dateStr);
                                      formattedDate = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
                                    } catch (_) {}
                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.bgDark : AppColors.bgLight,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.income.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Center(child: Text('\u{1F4B0}', style: TextStyle(fontSize: 20))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(formatRupiahTx(d['amount']), style: TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 15,
                                            color: AppColors.income,
                                          )),
                                          if (d['note'] != null && d['note'].toString().isNotEmpty)
                                            Text(d['note'].toString(), style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                                            )),
                                        ])),
                                        Text(formattedDate, style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                                        )),
                                      ]),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(dynamic s) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Target?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Target "${s['name']}" dan semua riwayat setorannya akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.deleteSaving(s['id'] as int);
        await _loadSavings();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _inputLabel(String text, bool isDark) => Text(text, style: TextStyle(
    fontWeight: FontWeight.w700, fontSize: 13,
    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
  ));

  Widget _textField(TextEditingController ctrl, String hint, bool isDark, {int maxLines = 1}) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    style: TextStyle(color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
    decoration: _inputDeco(hint, isDark),
  );

  InputDecoration _inputDeco(String hint, bool isDark) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary, fontSize: 14),
    filled: true,
    fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primaryBrand, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Target Tabungan',
          style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 20,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadSavings,
            icon: Icon(Icons.refresh_rounded, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSavings,
              color: AppColors.primaryBrand,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  slivers: [
                    // Summary Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text('\u{1F3AF}', style: TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(width: 12),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Total Terkumpul', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(
                                    formatRupiahTx(_totalCollected),
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                  ),
                                ]),
                                const Spacer(),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$_activeCount Aktif',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$_completedCount Tercapai',
                                      style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ]),
                              ]),
                              const SizedBox(height: 16),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(
                                  'Target: ${formatRupiahTx(_totalTarget)}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                Text(
                                  '${(_overallProgress * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _overallProgress,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                  minHeight: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Filter Chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: List.generate(3, (i) {
                            final labels = ['Semua', 'Berjalan', 'Tercapai'];
                            final sel = _filterIndex == i;
                            return GestureDetector(
                              onTap: () => setState(() => _filterIndex = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.primaryBrand : (isDark ? AppColors.surfaceDark : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel ? AppColors.primaryBrand : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                  boxShadow: sel
                                      ? [BoxShadow(color: AppColors.primaryBrand.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: sel ? Colors.white : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    // List / Empty
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('\u{1F3AF}', style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(
                                _savings.isEmpty ? 'Belum ada target tabungan' : 'Tidak ada data',
                                style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _savings.isEmpty ? 'Yuk buat target pertamamu!' : 'Coba pilih filter lain',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                                ),
                              ),
                              if (_savings.isEmpty) ...[
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _showAddSavingSheet,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Buat Target'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBrand,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _SavingCard(
                                s: filtered[i],
                                isDark: isDark,
                                emoji: _emojiForSaving(filtered[i]),
                                daysLabel: _daysLabel(filtered[i]),
                                onDeposit: () => _showDepositSheet(filtered[i]),
                                onHistory: () => _showHistorySheet(filtered[i]),
                                onDelete: () => _confirmDelete(filtered[i]),
                              ),
                            ),
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSavingSheet,
        backgroundColor: AppColors.primaryBrand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Target Baru', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SavingCard extends StatelessWidget {
  final dynamic s;
  final bool isDark;
  final String emoji;
  final String daysLabel;
  final VoidCallback onDeposit;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  const _SavingCard({
    required this.s,
    required this.isDark,
    required this.emoji,
    required this.daysLabel,
    required this.onDeposit,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = (s['status'] ?? '') == 'completed';
    final progress = amountValue(s['progress']) / 100;
    final remaining = amountValue(s['remaining_amount']);
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isCompleted ? AppColors.income : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isCompleted ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.income.withOpacity(0.12)
                      : AppColors.primaryBrand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  s['name'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                  ),
                ),
                if (s['description'] != null && s['description'].toString().isNotEmpty)
                  Text(
                    s['description'].toString(),
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                if (s['category'] != null && s['category'].toString().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s['category'].toString(),
                      style: TextStyle(fontSize: 10, color: AppColors.primaryBrand, fontWeight: FontWeight.w600),
                    ),
                  ),
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.income.withOpacity(0.12) : AppColors.primaryBrand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? 'Lunas \u{1F389}' : '${amountValue(s['progress']).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: isCompleted ? AppColors.income : AppColors.primaryBrand,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.income : AppColors.primaryBrand),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.savings_rounded, size: 14, color: AppColors.income),
                const SizedBox(width: 4),
                Text(
                  formatRupiahTx(s['current_amount']),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.income),
                ),
              ]),
              Text(
                '/ ${formatRupiahTx(s['target_amount'])}',
                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
              ),
            ]),
            if (!isCompleted && (remaining > 0 || daysLabel.isNotEmpty)) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (remaining > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Kurang ${formatRupiahTx(remaining)} lagi',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (daysLabel.isNotEmpty)
                  Flexible(
                    child: Text(daysLabel, style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    )),
                  ),
              ]),
            ],
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCompleted ? null : onDeposit,
                  icon: const Text('\u{1F4B0}', style: TextStyle(fontSize: 14)),
                  label: const Text('Setor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.income,
                    side: BorderSide(color: isCompleted ? (isDark ? AppColors.borderDark : AppColors.borderLight) : AppColors.income),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHistory,
                  icon: const Text('\u{1F4CB}', style: TextStyle(fontSize: 14)),
                  label: const Text('Riwayat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: Size.zero,
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
