import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../utils/format_helper.dart';
import '../utils/input_formatters.dart';

String _formatNumber(double value) {
  return value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
}

class WalletsPage extends StatefulWidget {
  const WalletsPage({super.key});

  @override
  State<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends State<WalletsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;

  double _totalBalance = 0;
  List<Wallet> _activeWallets = [];
  List<Wallet> _archivedWallets = [];

  bool _hideBalance = false;

  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get bg => isDarkMode ? AppColors.bgDark : const Color(0xFFF8FAFC);
  Color get cardBg => isDarkMode ? AppColors.surfaceDark : Colors.white;
  Color get inputBg => isDarkMode ? AppColors.bgDark : const Color(0xFFF8FAFC);
  Color get borderColor => isDarkMode ? AppColors.borderDark : const Color(0xFFE2E8F0);
  Color get textColor => isDarkMode ? AppColors.textDarkPrimary : const Color(0xFF1E293B);
  Color get subtextColor => isDarkMode ? AppColors.textDarkSecondary : const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadWallets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.getWallets(includeArchived: true);
      final rawWallets = (res['wallets'] as List? ?? []);

      final List<Wallet> active = [];
      final List<Wallet> archived = [];

      for (var item in rawWallets) {
        if (item is Map<String, dynamic>) {
          final w = Wallet.fromJson(item);
          if (w.isArchived) {
            archived.add(w);
          } else {
            active.add(w);
          }
        }
      }

      setState(() {
        _totalBalance = (res['total_balance'] is num)
            ? (res['total_balance'] as num).toDouble()
            : double.tryParse(res['total_balance']?.toString() ?? '0') ?? 0;
        _activeWallets = active;
        _archivedWallets = archived;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Dialog Tambah / Edit Dompet ───────────────────────
  void _showAddEditWalletDialog([Wallet? walletToEdit]) {
    final isEdit = walletToEdit != null;
    final nameController = TextEditingController(text: walletToEdit?.name ?? '');
    final initialBalanceController = TextEditingController(
      text: isEdit ? '' : '0',
    );

    String selectedType = walletToEdit?.type ?? 'cash';
    String selectedColor = walletToEdit?.color ?? '#10B981';

    final colors = [
      '#10B981', // Emerald
      '#3B82F6', // Blue
      '#6366F1', // Indigo
      '#8B5CF6', // Purple
      '#EC4899', // Pink
      '#F59E0B', // Amber
      '#EF4444', // Red
      '#6B7280', // Gray
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                      color: isDarkMode ? AppColors.borderDark : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEdit ? 'Edit Dompet' : 'Tambah Dompet Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit
                      ? 'Ubah nama, jenis, atau tema warna dompet'
                      : 'Kelola sumber dana terpisah seperti tunai, rekening bank, atau e-wallet',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 18),

                // Nama Dompet
                Text(
                  'Nama Dompet',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Misal: BCA Utama, Dompet Fisik, GoPay',
                    hintStyle: TextStyle(fontSize: 13, color: subtextColor),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Jenis Dompet
                Text(
                  'Jenis Sumber Dana',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeChip('cash', '💵 Tunai', selectedType, (val) {
                      setModalState(() => selectedType = val);
                    }),
                    _buildTypeChip('bank', '🏦 Bank / M-Banking', selectedType, (val) {
                      setModalState(() => selectedType = val);
                    }),
                    _buildTypeChip('emoney', '📱 E-Wallet / E-Money', selectedType, (val) {
                      setModalState(() => selectedType = val);
                    }),
                    _buildTypeChip('other', '📦 Lainnya', selectedType, (val) {
                      setModalState(() => selectedType = val);
                    }),
                  ],
                ),
                const SizedBox(height: 14),

                // Saldo Awal (hanya create)
                if (!isEdit) ...[
                  Text(
                    'Saldo Awal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: initialBalanceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                      hintText: '0',
                      hintStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Warna Tema
                Text(
                  'Warna Identitas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((c) {
                    final isSel = selectedColor.toUpperCase() == c.toUpperCase();
                    final colorVal = Color(int.parse(c.replaceAll('#', 'FF'), radix: 16));
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: textColor, width: 3) : null,
                        ),
                        child: isSel
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama dompet wajib diisi')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      setState(() => _loading = true);

                      try {
                        if (isEdit) {
                          await ApiService.updateWallet(
                            walletToEdit.id,
                            name: name,
                            type: selectedType,
                            color: selectedColor,
                          );
                        } else {
                          final cleanStr = initialBalanceController.text.replaceAll('.', '').trim();
                          final initialAmt = double.tryParse(cleanStr) ?? 0.0;

                          await ApiService.createWallet(
                            name: name,
                            type: selectedType,
                            initialBalance: initialAmt,
                            color: selectedColor,
                          );
                        }
                        await _loadWallets();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit ? 'Dompet berhasil diubah' : 'Dompet baru berhasil dibuat',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _loading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceFirst('Exception: ', '')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      isEdit ? 'Simpan Perubahan' : 'Buat Dompet',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _buildTypeChip(String type, String label, String currentSelected, Function(String) onSelect) {
    final isSelected = type == currentSelected;
    return GestureDetector(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5).withOpacity(0.15)
              : (isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF818CF8) : (isDarkMode ? AppColors.textDarkPrimary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ── Dialog Transfer Antar Dompet (FR-104) ─────────────
  void _showTransferDialog() {
    if (_activeWallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda membutuhkan minimal 2 dompet aktif untuk melakukan transfer')),
      );
      return;
    }

    int fromId = _activeWallets.first.id;
    int toId = _activeWallets[1].id;
    final amountController = TextEditingController();
    final adminFeeController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: isDarkMode ? AppColors.borderDark : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transfer Antar Dompet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pindahkan dana tanpa mengotori laporan pengeluaran & pemasukan',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 18),

                  // Dari Dompet
                  Text('Dari Sumber Dana (Asal)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor: cardBg,
                        isExpanded: true,
                        value: fromId,
                        items: _activeWallets.map((w) {
                          return DropdownMenuItem<int>(
                            value: w.id,
                            child: Row(
                              children: [
                                Icon(w.iconData, size: 18, color: w.parsedColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(w.name, style: TextStyle(fontSize: 13, color: textColor))),
                                Text(
                                  formatRupiah(w.currentBalance),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: subtextColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal == null) return;
                          setModalState(() {
                            fromId = newVal;
                            if (toId == fromId) {
                              toId = _activeWallets.firstWhere((w) => w.id != fromId).id;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ke Dompet
                  Text('Ke Sumber Dana (Tujuan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        dropdownColor: cardBg,
                        isExpanded: true,
                        value: toId,
                        items: _activeWallets.where((w) => w.id != fromId).map((w) {
                          return DropdownMenuItem<int>(
                            value: w.id,
                            child: Row(
                              children: [
                                Icon(w.iconData, size: 18, color: w.parsedColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(w.name, style: TextStyle(fontSize: 13, color: textColor))),
                                Text(
                                  formatRupiah(w.currentBalance),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: subtextColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) setModalState(() => toId = newVal);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nominal Transfer
                  Text('Nominal Transfer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                      hintText: '0',
                      hintStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Biaya Admin (opsional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Biaya Admin (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                      Text(
                        'Dicatat sbg Pengeluaran',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: adminFeeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                      hintText: '0',
                      hintStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Catatan
                  Text('Catatan (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Misal: Top up GoPay dari BCA',
                      hintStyle: TextStyle(color: subtextColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Kirim
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final cleanAmt = amountController.text.replaceAll('.', '').trim();
                        final amt = double.tryParse(cleanAmt) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nominal transfer harus lebih dari 0')),
                          );
                          return;
                        }

                        final cleanFee = adminFeeController.text.replaceAll('.', '').trim();
                        final fee = double.tryParse(cleanFee) ?? 0.0;

                        Navigator.pop(ctx);
                        setState(() => _loading = true);

                        try {
                          await ApiService.transferWallet(
                            fromWalletId: fromId,
                            toWalletId: toId,
                            amount: amt,
                            adminFee: fee,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                          await _loadWallets();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Transfer ${formatRupiah(amt)} berhasil diproses!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => _loading = false);
                          final errStr = e.toString().replaceFirst('Exception: ', '');
                          if (errStr.contains('Saldo tidak cukup') && mounted) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Saldo Tidak Cukup'),
                                content: Text('$errStr\n\nApakah Anda ingin tetap melanjutkan transfer dan membiarkan saldo dompet menjadi negatif (minus)?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text('Ya, Izinkan Minus', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              setState(() => _loading = true);
                              try {
                                final res = await ApiService.transferWallet(
                                  fromWalletId: fromId,
                                  toWalletId: toId,
                                  amount: amt,
                                  adminFee: fee,
                                  allowNegative: true,
                                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                );
                                await _loadWallets();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? 'Transfer dengan saldo minus berhasil'),
                                      backgroundColor: const Color(0xFFF59E0B),
                                    ),
                                  );
                                }
                              } catch (err2) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(err2.toString().replaceFirst('Exception: ', '')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _loading = false);
                              }
                              return;
                            }
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errStr),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Konfirmasi Transfer', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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

  // ── Dialog Sesuaikan Saldo Riil (FR-105) ──────────────
  void _showAdjustBalanceDialog(Wallet wallet) {
    final realBalanceController = TextEditingController(
      text: _formatNumber(wallet.currentBalance),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cleanInput = realBalanceController.text.replaceAll('.', '').trim();
          final realVal = double.tryParse(cleanInput) ?? 0.0;
          final diff = realVal - wallet.currentBalance;

          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                        color: isDarkMode ? AppColors.borderDark : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sesuaikan Saldo (${wallet.name})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan saldo riil yang ada di rekening / tangan Anda saat ini',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  const SizedBox(height: 16),

                  // Info Saldo Tercatat
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo di Aplikasi:', style: TextStyle(fontSize: 12, color: subtextColor)),
                        Text(
                          formatRupiah(wallet.currentBalance),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Saldo Riil
                  Text('Saldo Riil Sebenarnya', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: realBalanceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    onChanged: (_) => setModalState(() {}),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info Selisih
                  if (diff.abs() > 0.01)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: diff > 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            diff > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 16,
                            color: diff > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              diff > 0
                                  ? 'Selisih +${formatRupiah(diff)} akan dicatat sebagai Penyesuaian Saldo (Pemasukan)'
                                  : 'Selisih -${formatRupiah(diff.abs())} akan dicatat sebagai Penyesuaian Saldo (Pengeluaran)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: diff > 0 ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _loading = true);

                        try {
                          await ApiService.adjustWalletBalance(wallet.id, realVal);
                          await _loadWallets();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saldo dompet berhasil diselaraskan'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => _loading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Simpan Penyesuaian', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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

  String _formatMutationDateTime(dynamic createdAt, dynamic date) {
    if (createdAt != null && createdAt.toString().trim().isNotEmpty) {
      String s = createdAt.toString().trim();
      if (!s.endsWith('Z') && !s.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(s)) {
        s += 'Z';
      }
      final dt = DateTime.tryParse(s)?.toLocal();
      if (dt != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final itemDate = DateTime(dt.year, dt.month, dt.day);
        final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        
        if (today == itemDate) {
          return 'Hari ini, $timeStr';
        } else if (today.difference(itemDate).inDays == 1) {
          return 'Kemarin, $timeStr';
        } else {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
          return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $timeStr';
        }
      }
    }

    if (date != null && date.toString().trim().isNotEmpty) {
      String raw = date.toString().trim();
      if (raw.contains('T')) {
        raw = raw.split('T').first;
      }
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    }

    return '-';
  }

  // ── Mutasi Dompet (FR-111) ────────────────────────────
  void _showMutationsDialog(Wallet wallet) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: ApiService.getWalletTransactions(wallet.id),
        builder: (ctx, snapshot) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.borderDark : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Mutasi: ${wallet.name}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: wallet.parsedColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Saldo Saat Ini: ${formatRupiah(wallet.currentBalance)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: wallet.parsedColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textColor),
                      style: IconButton.styleFrom(
                        backgroundColor: isDarkMode ? AppColors.surfaceDarkHigh : Colors.grey.shade100,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Gagal memuat mutasi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Builder(builder: (ctx) {
                    final txs = (snapshot.data?['transactions'] as List? ?? []);
                    if (txs.isEmpty) {
                      return Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? AppColors.surfaceDarkHigh : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.receipt_long_outlined, size: 36, color: subtextColor),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Belum Ada Mutasi',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Semua transaksi dari dompet ini akan tercatat di sini',
                                style: TextStyle(fontSize: 12, color: subtextColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Expanded(
                      child: ListView.separated(
                        itemCount: txs.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final tx = txs[idx];
                          final type = tx['type']?.toString() ?? '';
                          final isIncome = type == 'income' || type == 'transfer_in';
                          final amt = (tx['amount'] is num) ? (tx['amount'] as num).toDouble() : 0.0;
                          final formattedDate = _formatMutationDateTime(tx['created_at'], tx['date']);

                          IconData icon = Icons.arrow_upward_rounded;
                          Color color = const Color(0xFFEF4444);

                          if (type == 'income') {
                            icon = Icons.arrow_downward_rounded;
                            color = const Color(0xFF10B981);
                          } else if (type == 'transfer_in') {
                            icon = Icons.swap_horiz_rounded;
                            color = const Color(0xFF3B82F6);
                          } else if (type == 'transfer_out') {
                            icon = Icons.swap_horiz_rounded;
                            color = const Color(0xFFF59E0B);
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode ? AppColors.borderDark : const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['description']?.toString() ?? '-',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDarkMode ? Colors.black26 : const Color(0xFFE2E8F0),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tx['category']?.toString() ?? '-',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: subtextColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(fontSize: 11, color: subtextColor),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${isIncome ? '+' : '-'}${formatRupiah(amt)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Arsipkan Dompet (FR-106) ──────────────────────────
  void _confirmArchiveWallet(Wallet wallet) {
    int? transferToId;
    final otherWallets = _activeWallets.where((w) => w.id != wallet.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            wallet.isArchived ? 'Pulihkan Dompet?' : 'Arsipkan Dompet?',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.isArchived
                    ? 'Dompet "${wallet.name}" akan kembali aktif dan dapat dipilih untuk transaksi.'
                    : 'Dompet "${wallet.name}" tidak akan muncul pada pilihan transaksi baru. Riwayat transaksi masa lalu tetap tersimpan.',
                style: TextStyle(fontSize: 13, color: textColor),
              ),
              if (!wallet.isArchived && wallet.currentBalance > 0 && otherWallets.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pindahkan sisa saldo ${formatRupiah(wallet.currentBalance)} ke:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? AppColors.textDarkPrimary : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButton<int?>(
                        dropdownColor: cardBg,
                        isExpanded: true,
                        value: transferToId,
                        hint: Text('Pilih dompet tujuan (opsional)', style: TextStyle(fontSize: 12, color: subtextColor)),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Biarkan di dompet ini (tidak ditransfer)', style: TextStyle(fontSize: 12, color: textColor)),
                          ),
                          ...otherWallets.map((w) => DropdownMenuItem<int?>(
                                value: w.id,
                                child: Text('${w.name} (${formatRupiah(w.currentBalance)})', style: TextStyle(fontSize: 12, color: textColor)),
                              )),
                        ],
                        onChanged: (val) => setDialogState(() => transferToId = val),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: wallet.isArchived ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _loading = true);

                try {
                  await ApiService.archiveWallet(wallet.id, transferToWalletId: transferToId);
                  await _loadWallets();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(wallet.isArchived ? 'Dompet berhasil dipulihkan' : 'Dompet berhasil diarsipkan'),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                }
              },
              child: Text(
                wallet.isArchived ? 'Pulihkan' : 'Arsipkan',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build UI Utama ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        title: Text(
          'Dompet & Sumber Dana',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF4F46E5), size: 26),
            tooltip: 'Tambah Dompet',
            onPressed: () => _showAddEditWalletDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: subtextColor,
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Aktif (${_activeWallets.length})'),
            Tab(text: 'Diarsipkan (${_archivedWallets.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadWallets, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWallets,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActiveTab(),
                      _buildArchivedTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildActiveTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ── Card Total Saldo Aktif ─────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL SALDO AKTIF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _hideBalance = !_hideBalance),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hideBalance ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _hideBalance ? 'Tampilkan' : 'Sembunyikan',
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _hideBalance ? '••••••••' : formatRupiah(_totalBalance),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 14),

              // 2 Tombol Aksi Cepat Transfer & Tambah
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Transfer Dana',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _showTransferDialog,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF4338CA), size: 18),
                      label: const Text(
                        'Tambah Dompet',
                        style: TextStyle(color: Color(0xFF4338CA), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showAddEditWalletDialog(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── List Dompet ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Sumber Dana',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              '${_activeWallets.length} Akun',
              style: TextStyle(fontSize: 12, color: subtextColor),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_activeWallets.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 48, color: subtextColor),
                const SizedBox(height: 8),
                Text('Belum ada dompet aktif', style: TextStyle(color: subtextColor)),
              ],
            ),
          )
        else
          ..._activeWallets.map((wallet) => _buildWalletCard(wallet)),
      ],
    );
  }

  Widget _buildArchivedTab() {
    if (_archivedWallets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 48, color: subtextColor),
            const SizedBox(height: 12),
            Text('Tidak ada dompet yang diarsipkan', style: TextStyle(fontSize: 13, color: subtextColor)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: _archivedWallets.map((wallet) => _buildWalletCard(wallet, isArchived: true)).toList(),
    );
  }

  Widget _buildWalletCard(Wallet wallet, {bool isArchived = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMutationsDialog(wallet),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: wallet.parsedColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(wallet.iconData, color: wallet.parsedColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Nama & Jenis
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        wallet.typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Saldo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _hideBalance ? '••••••' : formatRupiah(wallet.currentBalance),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: wallet.currentBalance < 0 ? const Color(0xFFEF4444) : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ketuk utk mutasi',
                      style: TextStyle(fontSize: 10, color: subtextColor),
                    ),
                  ],
                ),

                // Menu Popup
                PopupMenuButton<String>(
                  color: cardBg,
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: subtextColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'adjust') {
                      _showAdjustBalanceDialog(wallet);
                    } else if (val == 'edit') {
                      _showAddEditWalletDialog(wallet);
                    } else if (val == 'archive') {
                      _confirmArchiveWallet(wallet);
                    } else if (val == 'mutations') {
                      _showMutationsDialog(wallet);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'mutations',
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 10),
                          Text('Lihat Mutasi', style: TextStyle(fontSize: 13, color: textColor)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'adjust',
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Text('Sesuaikan Saldo', style: TextStyle(fontSize: 13, color: textColor)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 10),
                          Text('Edit Dompet', style: TextStyle(fontSize: 13, color: textColor)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(
                            isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                            size: 18,
                            color: isArchived ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isArchived ? 'Pulihkan Dompet' : 'Arsipkan Dompet',
                            style: TextStyle(
                              fontSize: 13,
                              color: isArchived ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
        ),
      ),
    );
  }
}
