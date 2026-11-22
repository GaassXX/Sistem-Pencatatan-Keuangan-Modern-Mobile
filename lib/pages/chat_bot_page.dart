import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../utils/category_helper.dart';
import 'add_transaction_page.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? transactionData;
  final Map<String, dynamic>? confirmationData;
  final bool isError;
  bool isCancelled;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.transactionData,
    this.confirmationData,
    this.isError = false,
    this.isCancelled = false,
  });
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isSending = false;
  String _userName = 'Sobat FinChat';

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
    _loadUserProfile();
    _initWelcomeMessage();
  }

  Future<void> _loadUserProfile() async {
    try {
      final res = await ApiService.getProfile();
      final user = res['data'] ?? res['user'];
      if (user != null && user['name'] != null && mounted) {
        setState(() {
          _userName = user['name'].toString().split(' ').first;
        });
      }
    } catch (_) {
      // Fallback tetap menggunakan default
    }
  }

  void _initWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: 'Halo! Ketik transaksi harianmu dengan bahasa santai, atau tap template kilat di bawah:',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDateHeader(DateTime date) {
    return 'Hari ini, ${date.day} ${_monthNames[date.month]} ${date.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  /// Deteksi cerdas multi-nominal (misal: "Kopi 2 gelas 50rb")
  Map<String, dynamic>? _checkMultiNominal(String input) {
    final text = input.toLowerCase().trim();

    // Pola: kuantitas + unit (misal: 2 gelas, 3 porsi, 2 bungkus, 4 pcs, dll.)
    final qtyRegex = RegExp(
      r'(\d+)\s*(gelas|porsi|bungkus|buah|pcs|item|biji|cup|mangkok|piring|botol|kaleng|kotak|lembar|tiket|buku|pasang|orang|pack|pax|paket)',
      caseSensitive: false,
    );
    final qtyMatch = qtyRegex.firstMatch(text);

    // Pola: nominal uang (misal: 50rb, 50k, 50.000, 50000)
    final nominalRegex = RegExp(
      r'(\d+(?:[\.,]\d+)?)\s*(rb|k|ribu|jt|juta|000)',
      caseSensitive: false,
    );
    final nominalMatch = nominalRegex.firstMatch(text);

    if (qtyMatch != null && nominalMatch != null) {
      final qtyStr = qtyMatch.group(1)!;
      final unitStr = qtyMatch.group(2)!;
      final qty = int.tryParse(qtyStr) ?? 2;

      // Hitung nominal rekomendasi
      final nomNumStr = nominalMatch.group(1)!.replaceAll('.', '').replaceAll(',', '');
      final nomUnit = nominalMatch.group(2)!.toLowerCase();
      double recAmount = double.tryParse(nomNumStr) ?? 0;
      if (nomUnit == 'rb' || nomUnit == 'k' || nomUnit == 'ribu' || nomUnit == '000') {
        if (!nomNumStr.endsWith('000')) {
          recAmount *= 1000;
        }
      } else if (nomUnit == 'jt' || nomUnit == 'juta') {
        recAmount *= 1000000;
      }

      // Pastikan kuantitas berbeda dengan nominal rekomendasi
      if (recAmount > qty && recAmount >= 1000) {
        String catGuess = 'Minuman / Kafe';
        if (text.contains('makan') || text.contains('nasi') || text.contains('ayam') || text.contains('bakso')) {
          catGuess = 'Makanan & Minuman';
        } else if (text.contains('baju') || text.contains('kaos') || text.contains('buku') || text.contains('sepatu')) {
          catGuess = 'Belanja Harian';
        }

        return {
          'qty': qty,
          'unit': unitStr,
          'qty_amount': qty * 1000.0,
          'qty_label': '$qty item total',
          'rec_amount': recAmount,
          'rec_label': 'Total belanja',
          'category': catGuess,
          'raw_message': input,
        };
      }
    }
    return null;
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    if (presetText == null) {
      _textController.clear();
    }

    final now = DateTime.now();
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: now,
        ),
      );
      _isSending = true;
    });

    _scrollToBottom();

    // 1. Cek apakah butuh konfirmasi multi-nominal
    final multiCheck = _checkMultiNominal(text);
    if (multiCheck != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Ada dua angka di pesanmu (${multiCheck['qty']} dan ${formatRupiahTx(multiCheck['rec_amount']).replaceAll('Rp ', '')}). Nominal total mana yang ingin dicatat?',
            isUser: false,
            timestamp: DateTime.now(),
            confirmationData: multiCheck,
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
      return;
    }

    // 2. Kirim pesan ke backend NLP
    await _sendToBackend(text);
  }

  Future<void> _sendToBackend(String text) async {
    try {
      final res = await ApiService.sendChatMessage(text);
      final message = res['message']?.toString() ?? 'Transaksi berhasil dicatat!';
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : null;

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: message,
            isUser: false,
            timestamp: DateTime.now(),
            transactionData: data,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _messages.add(
          ChatMessage(
            text: '❌ $errorMsg\n\nTips: Pastikan menyertakan angka/nominal, contoh: "Kopi 20k" atau "Makan siang 15000"',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _cancelTransaction(ChatMessage msg) async {
    final txId = msg.transactionData?['id'];
    if (txId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: const Text('Transaksi yang baru dicatat ini akan dihapus dari catatan keuangan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Kembali')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteTransaction(txId);
        if (mounted) {
          setState(() {
            msg.isCancelled = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dibatalkan.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membatalkan transaksi: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final subTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    const primaryBrand = Color(0xFF5B4DFF);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.pop(context, true),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: textColor,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryBrand,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryBrand.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FinChat Assistant',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const Row(
                  children: [
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text(
                      'Bot Parser Siap',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Date Pill Header di Bagian Atas ──────────────────
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatDateHeader(DateTime.now()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),

            // ── List Pesan Chat ──────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isFirstWelcome = index == 0 && !msg.isUser;
                  return _buildMessageItem(msg, isDark, isFirstWelcome);
                },
              ),
            ),

            // ── Loading Bot Processing Indicator ────────────────
            if (_isSending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5B4DFF)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bot sedang memproses transaksi...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Input Bar Bawah Modern ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tulis transaksi, misal: Kopi 20k...',
                          hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryBrand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBrand.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Template Kilat Card Item ────────────────────────────────────
  Widget _buildQuickTemplateCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String amount,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textDarkSecondary : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool isDark, bool isFirstWelcome) {
    final subTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    const primaryBrand = Color(0xFF5B4DFF);

    // ── 1. Gelembung Pesan Pengguna (Kanan, Ungu FinChat) ─────────
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.76,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryBrand,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBrand.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatTime(msg.timestamp),
                  style: TextStyle(fontSize: 10.5, color: subTextColor),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 14, color: primaryBrand),
              ],
            ),
          ],
        ),
      );
    }

    // ── 2. Pesan Bot (Kiri, Putih Elegan) ─────────────────────────
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Bot Bulat Ungu
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: primaryBrand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBrand.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),

          // Konten Pesan Bot
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pesan Selamat Datang dengan Template Kilat
                if (isFirstWelcome) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                            ),
                            children: [
                              const TextSpan(text: 'Halo '),
                              TextSpan(
                                text: '$_userName! 👋 ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryBrand,
                                ),
                              ),
                              const TextSpan(
                                text: 'Ketik transaksi harianmu dengan bahasa santai, atau tap template kilat di bawah:',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Baris Template Kilat Interaktif
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickTemplateCard(
                                icon: Icons.restaurant_rounded,
                                iconBg: const Color(0xFFFFEDD5),
                                iconColor: const Color(0xFFC2410C),
                                title: 'Makan',
                                amount: '15rb',
                                isDark: isDark,
                                onTap: () => _sendMessage('Makan siang 15rb'),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickTemplateCard(
                                icon: Icons.directions_car_rounded,
                                iconBg: const Color(0xFFFFE4E6),
                                iconColor: const Color(0xFFBE123C),
                                title: 'Bensin',
                                amount: '50rb',
                                isDark: isDark,
                                onTap: () => _sendMessage('Bensin motor 50rb'),
                              ),
                              const SizedBox(width: 8),
                              _buildQuickTemplateCard(
                                icon: Icons.payments_rounded,
                                iconBg: const Color(0xFFFEF3C7),
                                iconColor: const Color(0xFFB45309),
                                title: 'Gaji',
                                amount: '5jt',
                                isDark: isDark,
                                onTap: () => _sendMessage('Gaji bulanan 5jt'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (msg.transactionData != null) ...[
                  // Kartu Transaksi Tercatat Sesuai Mockup
                  _buildTransactionRecordedCard(msg, isDark),
                ] else if (msg.confirmationData != null) ...[
                  // Kartu Butuh Konfirmasi Multi-Nominal Sesuai Mockup
                  _buildConfirmationCard(msg, isDark),
                ] else ...[
                  // Bubble Teks Biasa / Error
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: msg.isError
                            ? const Color(0xFFFCA5A5)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isError
                            ? const Color(0xFFDC2626)
                            : (isDark ? Colors.white : AppColors.textPrimary),
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 4),
                Text(
                  _formatTime(msg.timestamp),
                  style: TextStyle(fontSize: 10.5, color: subTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu "Transaksi Tercatat!" (Sesuai Mockup) ───────────────────
  Widget _buildTransactionRecordedCard(ChatMessage msg, bool isDark) {
    final data = msg.transactionData!;
    final isIncome = data['type'] == 'income';
    final amountFormatted = data['formatted_amount']?.toString() ?? formatRupiahTx(data['amount']);
    final category = data['category']?.toString() ?? 'Lainnya';
    final description = data['description']?.toString() ?? '-';
    final source = data['source_label']?.toString() ?? paymentMethodName(data['source']);
    final isCancelled = msg.isCancelled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCancelled
              ? Colors.grey.shade400
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
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
          // Header Bar: Badge Hijau Transaksi Tercatat & Otomatisasi NLP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.grey.shade200
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline_rounded,
                      size: 13,
                      color: isCancelled ? Colors.grey : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCancelled ? 'Dibatalkan' : 'Transaksi Tercatat!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCancelled ? Colors.grey : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Otomatisasi NLP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini Kotak Rincian Transaksi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Icon Kategori
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : categoryBackground(category),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    categoryIcon(category),
                    size: 20,
                    color: isDark ? AppColors.accentDark : categoryIconColor(category),
                  ),
                ),
                const SizedBox(width: 10),

                // Nama Kategori & Catatan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isIncome ? 'Pemasukan' : 'Pengeluaran'} • $description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nominal & Sumber Dompet
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}$amountFormatted',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      source.isNotEmpty ? source : 'Dompet Utama',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!isCancelled) ...[
            const SizedBox(height: 12),
            // Baris Tombol Aksi: Ubah & Batalkan
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTransactionPage(transactionToEdit: data),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF4F46E5)),
                    label: const Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE4E6),
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _cancelTransaction(msg),
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFBE123C)),
                    label: const Text(
                      'Batalkan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBE123C),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Kartu "Butuh Konfirmasi" Multi-Nominal (Sesuai Mockup) ─────────
  Widget _buildConfirmationCard(ChatMessage msg, bool isDark) {
    final conf = msg.confirmationData!;
    final qty = conf['qty'];
    final qtyAmount = conf['qty_amount'] as double;
    final qtyLabel = conf['qty_label']?.toString() ?? '$qty item total';
    final recAmount = conf['rec_amount'] as double;
    final recLabel = conf['rec_label']?.toString() ?? 'Total belanja';
    final category = conf['category']?.toString() ?? 'Minuman / Kafe';
    final rawMsg = conf['raw_message']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
          // Header Bar: Badge Butuh Konfirmasi & Multi-nominal terdeteksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFC2410C)),
                    SizedBox(width: 4),
                    Text(
                      'Butuh Konfirmasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Multi-nominal terdeteksi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Teks Pertanyaan
          Text(
            'Ada dua angka di pesanmu ($qty dan ${formatRupiahTx(recAmount).replaceAll('Rp ', '')}). Nominal total mana yang ingin dicatat?',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // 2 Pilihan Kotak Nominal (Opsi Jumlah vs Rekomendasi Sistem)
          Row(
            children: [
              // Opsi 1: Opsi Jumlah
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Catat opsi jumlah
                    _sendToBackend('$category $qtyAmount');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Opsi Jumlah',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatRupiahTx(qtyAmount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          qtyLabel,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Opsi 2: Rekomendasi Sistem (Ungu Solid)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Catat rekomendasi sistem
                    _sendToBackend('$category $recAmount');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B4DFF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B4DFF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Rekomendasi Sistem',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.check_circle_rounded, size: 11, color: Colors.white),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatRupiahTx(recAmount),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recLabel,
                          style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Footer Bar: Kategori & Ketik Manual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'Kategori: $category',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  _textController.text = rawMsg;
                },
                child: const Text(
                  'Ketik manual',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B4DFF),
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
