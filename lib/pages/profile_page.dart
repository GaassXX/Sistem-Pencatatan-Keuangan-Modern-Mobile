import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../main.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/currency_service.dart';
import '../services/permission_service.dart';
import '../widgets/profile/menu_card.dart';
import '../widgets/profile/profile_card.dart';
import '../widgets/profile/stat_card.dart';
import 'budget_page.dart';
import 'savings_page.dart';
import 'login_page.dart';
import 'wallets_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  late User _currentUser;

  int _transactionCount = 0;
  int _walletCount = 0;
  int _savingCount = 0;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadStats();
    _fetchFreshProfile();
  }

  Future<void> _fetchFreshProfile() async {
    try {
      final res = await ApiService.getProfile();
      if (res['data'] is Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _currentUser = User.fromJson(Map<String, dynamic>.from(res['data']));
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        ApiService.getTransactions(),
        ApiService.getWallets(),
        ApiService.getSavings(),
      ]);

      final transactions = results[0] as List<dynamic>? ?? [];
      final walletsData = results[1] as Map<String, dynamic>? ?? {};
      final rawWallets = walletsData['wallets'] as List<dynamic>? ?? [];
      final savings = results[2] as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _transactionCount = transactions.length;
        _walletCount = rawWallets.length;
        _savingCount = savings.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get backgroundColor => isDarkMode ? AppColors.bgDark : AppColors.bgLight;
  Color get cardColor => isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;
  Color get primaryText => isDarkMode ? AppColors.textDarkPrimary : AppColors.textPrimary;
  Color get secondaryText => isDarkMode ? AppColors.textDarkSecondary : AppColors.textSecondary;
  Color get limeColor => AppColors.accent;
  Color get softLime => isDarkMode ? const Color(0xFF312E81).withOpacity(0.4) : const Color(0xFFEEF2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENGATURAN PENGGUNA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Profil & Preferensi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 16),
                ProfileCard(
                  user: _currentUser,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  softLime: softLime,
                  limeColor: limeColor,
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  onChangePhoto: _showChangePhoto,
                  onEditProfile: _editProfile,
                ),
                const SizedBox(height: 14),
                _buildStats(),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'REKENING & DOMPET',
                  _loading ? '...' : '$_walletCount Sumber Dana',
                ),
                const SizedBox(height: 10),
                _buildAccountCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('PERENCANAAN FINANSIAL', ''),
                const SizedBox(height: 10),
                _buildPlanningCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('AKUN & PREFERENSI', ''),
                const SizedBox(height: 10),
                _buildPreferenceCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('KEAMANAN & PRIVASI', ''),
                const SizedBox(height: 10),
                _buildSecurityCard(),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: _loading ? '...' : '$_transactionCount',
            label: 'Transaksi',
            valueColor: primaryText,
            cardColor: cardColor,
            secondaryText: secondaryText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            value: _loading ? '...' : '$_walletCount',
            label: 'Dompet',
            valueColor: primaryText,
            cardColor: cardColor,
            secondaryText: secondaryText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            value: _loading ? '...' : '$_savingCount',
            label: 'Tabungan',
            valueColor: isDarkMode ? limeColor : const Color(0xFF16A34A),
            cardColor: cardColor,
            secondaryText: secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: secondaryText,
          ),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? limeColor : const Color(0xFF16A34A),
            ),
          ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return MenuCard(
      cardColor: cardColor,
      children: [
        MenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Sumber Dana / Dompet',
          subtitle: 'Kelola rekening, e-wallet, dan uang tunai',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletsPage()),
            );
            _loadStats();
          },
          softLime: softLime,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
        const Divider(height: 1, indent: 54),
        ValueListenableBuilder<CurrencyModel>(
          valueListenable: CurrencyService.currencyNotifier,
          builder: (context, activeCurrency, _) {
            final isIdr = activeCurrency.code == 'IDR';
            return MenuItem(
              icon: Icons.currency_exchange_rounded,
              title: 'Mata Uang (Multi-Currency)',
              subtitle: isIdr
                  ? 'Mata Uang Aktif: 🇮🇩 IDR (Rp)'
                  : 'Mata Uang Aktif: ${activeCurrency.flag} ${activeCurrency.code} (${activeCurrency.symbol})',
              onTap: _showCurrencySheet,
              softLime: softLime,
              primaryText: primaryText,
              secondaryText: secondaryText,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlanningCard() {
    return MenuCard(
      cardColor: cardColor,
      children: [
        MenuItemWithBadge(
          icon: Icons.pie_chart_outline_rounded,
          title: 'Anggaran Bulanan',
          subtitle: 'Atur batas maksimal pengeluaran',
          badge: 'Aktif',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetPage()),
            );
          },
          softLime: softLime,
          limeColor: limeColor,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
        const Divider(height: 1, indent: 54),
        MenuItem(
          icon: Icons.savings_outlined,
          title: 'Target Tabungan',
          subtitle: 'Pantau impian & simpanan masa depan',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavingsPage()),
            );
            _loadStats();
          },
          softLime: softLime,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
      ],
    );
  }

  Widget _buildPreferenceCard() {
    return MenuCard(
      cardColor: cardColor,
      children: [
        MenuItem(
          icon: Icons.category_outlined,
          title: 'Kategori Transaksi',
          subtitle: 'Kelola, ubah & hapus kategori',
          onTap: _showCategoryManagementSheet,
          softLime: softLime,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
        const Divider(height: 1, indent: 54),
        MenuItem(
          icon: Icons.dark_mode_outlined,
          title: 'Tampilan & Tema',
          subtitle: isDarkMode ? 'Mode Gelap' : 'Mode Terang',
          onTap: _showThemeSheet,
          softLime: softLime,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
        const Divider(height: 1, indent: 54),
        MenuItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifikasi & Pengingat',
          subtitle: 'Pengingat & persetujuan aktif',
          onTap: _showNotificationSettingsSheet,
          softLime: softLime,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return MenuCard(
      cardColor: cardColor,
      children: [
        MenuItemWithSwitch(
          icon: Icons.fingerprint_rounded,
          title: 'Kunci Aplikasi Biometrik',
          subtitle: 'Sidik jari & Face ID',
          value: _biometricEnabled,
          onChanged: (val) => setState(() => _biometricEnabled = val),
          softLime: softLime,
          limeColor: limeColor,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
        const Divider(height: 1, indent: 54),
        MenuItem(
          icon: Icons.lock_outline_rounded,
          title: 'Ubah Kata Sandi',
          subtitle: 'Perbarui kata sandi akun Anda',
          onTap: _editProfile,
          softLime: softLime,
          primaryText: primaryText,
          secondaryText: secondaryText,
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _currentUser.name);
    final emailController = TextEditingController(text: _currentUser.email);
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, bottomInset + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: secondaryText.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: softLime,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: isDarkMode ? const Color(0xFFA5B4FC) : AppColors.primaryBrand,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profil',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primaryText,
                              ),
                            ),
                            Text(
                              'Perbarui informasi akun Anda',
                              style: TextStyle(fontSize: 12, color: secondaryText),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Field Nama
                    Text(
                      'Nama Lengkap',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap',
                        hintStyle: TextStyle(color: secondaryText.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9),
                        prefixIcon: Icon(Icons.badge_outlined, size: 20, color: secondaryText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field Email
                    Text(
                      'Alamat Email',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
                      decoration: InputDecoration(
                        hintText: 'nama@email.com',
                        hintStyle: TextStyle(color: secondaryText.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9),
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: secondaryText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field Password (Opsional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kata Sandi Baru',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryText),
                        ),
                        Text(
                          'Opsional',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryText),
                      decoration: InputDecoration(
                        hintText: 'Kosongkan jika tidak ingin diubah (min 6 karakter)',
                        hintStyle: TextStyle(color: secondaryText.withOpacity(0.6), fontSize: 12),
                        filled: true,
                        fillColor: isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9),
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: secondaryText),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: secondaryText,
                          ),
                          onPressed: () => setSheetState(() => obscurePassword = !obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();

                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nama lengkap wajib diisi')),
                                  );
                                  return;
                                }

                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Alamat email wajib diisi')),
                                  );
                                  return;
                                }

                                if (password.isNotEmpty && password.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kata sandi minimal 6 karakter')),
                                  );
                                  return;
                                }

                                setSheetState(() => isSaving = true);

                                try {
                                  final res = await ApiService.updateProfile(
                                    name: name,
                                    email: email,
                                    password: password.isEmpty ? null : password,
                                  );

                                  if (mounted) {
                                    setState(() {
                                      _currentUser = User.fromJson(
                                        Map<String, dynamic>.from(res['data'] ?? {}),
                                      );
                                    });
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Profil berhasil diperbarui!'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setSheetState(() => isSaving = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    Navigator.pop(context);
    try {
      final bool hasPermission;
      if (source == ImageSource.camera) {
        hasPermission = await PermissionService.requestCameraPermission(context);
      } else {
        hasPermission = await PermissionService.requestPhotosPermission(context);
      }

      if (!hasPermission) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Mengunggah foto profil...'),
            ],
          ),
          duration: Duration(seconds: 15),
        ),
      );

      final file = File(pickedFile.path);
      final res = await ApiService.uploadAvatar(file);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (!mounted) return;
      if (res['data'] != null) {
        setState(() {
          _currentUser = User.fromJson(Map<String, dynamic>.from(res['data']));
        });
      } else {
        await _fetchFreshProfile();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Foto profil berhasil diperbarui!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAvatar() async {
    Navigator.pop(context);
    try {
      final res = await ApiService.deleteAvatar();
      if (!mounted) return;
      if (res['data'] != null) {
        setState(() {
          _currentUser = User.fromJson(Map<String, dynamic>.from(res['data']));
        });
      } else {
        await _fetchFreshProfile();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Foto profil berhasil dihapus'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangePhoto() {
    final hasAvatar = _currentUser.avatarUrl != null && _currentUser.avatarUrl!.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: secondaryText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Foto Profil',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  onTap: () => _pickAndUploadAvatar(ImageSource.camera),
                  leading: Icon(Icons.camera_alt_outlined, color: primaryText),
                  title: Text(
                    'Ambil Foto',
                    style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                ListTile(
                  onTap: () => _pickAndUploadAvatar(ImageSource.gallery),
                  leading: Icon(Icons.photo_library_outlined, color: primaryText),
                  title: Text(
                    'Pilih dari Galeri',
                    style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                if (hasAvatar) ...[
                  const Divider(height: 16),
                  ListTile(
                    onTap: _deleteAvatar,
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    title: const Text(
                      'Hapus Foto Profil',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryManagementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _CategoryManagementView(
          isDarkMode: isDarkMode,
          cardColor: cardColor,
          primaryText: primaryText,
          secondaryText: secondaryText,
          limeColor: limeColor,
          softLime: softLime,
        );
      },
    );
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: secondaryText.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tampilan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _themeOption(
                      icon: Icons.light_mode_outlined,
                      title: 'Terang',
                      selected: !isDark,
                      onTap: () {
                        themeNotifier.value = ThemeMode.light;
                        Navigator.pop(sheetContext);
                      },
                    ),
                    const SizedBox(height: 10),
                    _themeOption(
                      icon: Icons.dark_mode_outlined,
                      title: 'Gelap',
                      selected: isDark,
                      onTap: () {
                        themeNotifier.value = ThemeMode.dark;
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? softLime
              : (isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryText),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: limeColor),
          ],
        ),
      ),
    );
  }

  void _showCurrencySheet() {
    final searchCtrl = TextEditingController();
    String searchQuery = '';
    int filterTab = 0; // 0 = Semua, 1 = Populer

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final active = CurrencyService.current;
            final query = searchQuery.trim().toLowerCase();

            final filteredList = CurrencyService.currencies.where((c) {
              if (filterTab == 1 && !c.isPopular) return false;
              if (query.isEmpty) return true;
              return c.code.toLowerCase().contains(query) ||
                  c.name.toLowerCase().contains(query) ||
                  c.symbol.toLowerCase().contains(query);
            }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: secondaryText.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mata Uang Tampilan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Konversi tampilan global. Data asli tetap tersimpan dalam Rupiah.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: Icon(Icons.close_rounded, color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                      style: TextStyle(color: primaryText, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari mata uang (misal: USD, Yen, Euro)...',
                        hintStyle: TextStyle(color: secondaryText, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: secondaryText, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: secondaryText, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() {
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.surfaceDarkHigh
                            : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  // Filter Chips (Semua / Populer)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        _currencyFilterChip(
                          label: 'Semua (${CurrencyService.currencies.length})',
                          selected: filterTab == 0,
                          onTap: () => setModalState(() => filterTab = 0),
                        ),
                        const SizedBox(width: 8),
                        _currencyFilterChip(
                          label: 'Populer (${CurrencyService.currencies.where((c) => c.isPopular).length})',
                          selected: filterTab == 1,
                          onTap: () => setModalState(() => filterTab = 1),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Currency List
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Mata uang "$searchQuery" tidak ditemukan',
                                style: TextStyle(color: secondaryText, fontSize: 14),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final c = filteredList[i];
                              final isSelected = c.code == active.code;

                              String rateText;
                              if (c.code == 'IDR') {
                                rateText = 'Mata Uang Utama';
                              } else {
                                final roundedRate = c.rateToIdr >= 100
                                    ? c.rateToIdr.toStringAsFixed(0).replaceAllMapped(
                                          RegExp(r'\B(?=(\d{3})+(?!\d))'),
                                          (m) => '.',
                                        )
                                    : c.rateToIdr.toString();
                                rateText = '1 ${c.code} ≈ Rp $roundedRate';
                              }

                              return InkWell(
                                onTap: () async {
                                  await CurrencyService.setCurrency(c);
                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  setState(() {});
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Mata uang diubah ke ${c.flag} ${c.code} - ${c.name}',
                                      ),
                                      backgroundColor: AppColors.primaryBrand,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? softLime
                                        : (isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryBrand
                                          : (isDarkMode ? AppColors.borderDark : AppColors.borderLight),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(c.flag, style: const TextStyle(fontSize: 26)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  c.code,
                                                  style: TextStyle(
                                                    color: primaryText,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDarkMode
                                                        ? AppColors.surfaceDark
                                                        : Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isDarkMode
                                                          ? AppColors.borderDark
                                                          : AppColors.borderLight,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    c.symbol,
                                                    style: const TextStyle(
                                                      color: AppColors.primaryBrand,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              c.name,
                                              style: TextStyle(
                                                color: secondaryText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              rateText,
                                              style: TextStyle(
                                                color: c.code == 'IDR'
                                                    ? AppColors.accent
                                                    : secondaryText.withOpacity(0.8),
                                                fontSize: 11,
                                                fontWeight: c.code == 'IDR'
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primaryBrand,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _currencyFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryBrand
              : (isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : secondaryText,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _showNotificationSettingsSheet() async {
    bool isGranted = await PermissionService.isNotificationGranted();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: secondaryText.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: limeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.notifications_active_outlined, color: limeColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifikasi & Pengingat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isGranted ? 'Izin notifikasi aktif' : 'Izin notifikasi belum aktif',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isGranted ? const Color(0xFF10B981) : Colors.amber.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotificationBenefitRow(
                            Icons.check_circle_outline,
                            'Pengingat jatuh tempo utang & piutang',
                          ),
                          const SizedBox(height: 10),
                          _buildNotificationBenefitRow(
                            Icons.check_circle_outline,
                            'Peringatan saat pengeluaran melebihi batas anggaran',
                          ),
                          const SizedBox(height: 10),
                          _buildNotificationBenefitRow(
                            Icons.check_circle_outline,
                            'Konfirmasi persetujuan transaksi keluarga (Parent-Child)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final granted = await PermissionService.requestNotificationPermission(context);
                          final currentStatus = await PermissionService.isNotificationGranted();
                          setSheetState(() {
                            isGranted = currentStatus;
                          });
                          if (!mounted) return;
                          setState(() {});
                          if (granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Izin notifikasi berhasil diaktifkan!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                        icon: Icon(isGranted ? Icons.settings_outlined : Icons.notifications_active, size: 18),
                        label: Text(
                          isGranted ? 'Buka Pengaturan Notifikasi' : 'Aktifkan Izin Notifikasi',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGranted ? const Color(0xFF334155) : const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationBenefitRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: secondaryText,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Keluar dari akun?',
            style: TextStyle(color: primaryText, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Kamu akan keluar dari akun FinChat di perangkat ini.',
            style: TextStyle(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Batal',
                style: TextStyle(color: secondaryText, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ApiService.logout();
                } catch (_) {}
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryManagementView extends StatefulWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color primaryText;
  final Color secondaryText;
  final Color limeColor;
  final Color softLime;

  const _CategoryManagementView({
    required this.isDarkMode,
    required this.cardColor,
    required this.primaryText,
    required this.secondaryText,
    required this.limeColor,
    required this.softLime,
  });

  @override
  State<_CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<_CategoryManagementView> {
  bool _loading = true;
  List<dynamic> _expenseCategories = [];
  List<dynamic> _incomeCategories = [];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _loading = true);
    try {
      final expense = await ApiService.getCategories('expense');
      final income = await ApiService.getCategories('income');
      if (!mounted) return;
      setState(() {
        _expenseCategories = expense;
        _incomeCategories = income;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String categoryType = _selectedTab == 0 ? 'expense' : 'income';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Tambah Kategori Baru',
                style: TextStyle(color: widget.primaryText, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipe Kategori', style: TextStyle(fontSize: 12, color: widget.secondaryText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pengeluaran'),
                          selected: categoryType == 'expense',
                          selectedColor: widget.softLime,
                          onSelected: (val) {
                            if (val) setDialogState(() => categoryType = 'expense');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pemasukan'),
                          selected: categoryType == 'income',
                          selectedColor: widget.softLime,
                          onSelected: (val) {
                            if (val) setDialogState(() => categoryType = 'income');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Nama Kategori', style: TextStyle(fontSize: 12, color: widget.secondaryText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: widget.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Olahraga, Bonus...',
                      hintStyle: TextStyle(color: widget.secondaryText.withOpacity(0.6)),
                      filled: true,
                      fillColor: widget.isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F4F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Batal', style: TextStyle(color: widget.secondaryText)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          setDialogState(() => isSaving = true);
                          try {
                            await ApiService.createCategory(name: name, type: categoryType);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            _fetchCategories();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDarkMode ? widget.limeColor : const Color(0xFF172033),
                    foregroundColor: widget.isDarkMode ? const Color(0xFF172033) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(dynamic category) {
    final nameController = TextEditingController(text: category['name']?.toString() ?? '');
    String categoryType = category['type']?.toString() ?? (_selectedTab == 0 ? 'expense' : 'income');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: widget.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Edit Kategori',
                style: TextStyle(color: widget.primaryText, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipe Kategori', style: TextStyle(fontSize: 12, color: widget.secondaryText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pengeluaran'),
                          selected: categoryType == 'expense',
                          selectedColor: widget.softLime,
                          onSelected: (val) {
                            if (val) setDialogState(() => categoryType = 'expense');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pemasukan'),
                          selected: categoryType == 'income',
                          selectedColor: widget.softLime,
                          onSelected: (val) {
                            if (val) setDialogState(() => categoryType = 'income');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Nama Kategori', style: TextStyle(fontSize: 12, color: widget.secondaryText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: widget.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Nama Kategori',
                      hintStyle: TextStyle(color: widget.secondaryText.withOpacity(0.6)),
                      filled: true,
                      fillColor: widget.isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F4F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Batal', style: TextStyle(color: widget.secondaryText)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final int catId = category['id'] is int ? category['id'] : int.parse(category['id'].toString());
                            await ApiService.updateCategory(catId, name: name, type: categoryType);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            _fetchCategories();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDarkMode ? widget.limeColor : const Color(0xFF172033),
                    foregroundColor: widget.isDarkMode ? const Color(0xFF172033) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(dynamic category) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: widget.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Hapus Kategori?', style: TextStyle(color: widget.primaryText, fontWeight: FontWeight.w800)),
          content: Text('Kategori "${category['name']}" akan dihapus secara permanen.', style: TextStyle(color: widget.secondaryText)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Batal', style: TextStyle(color: widget.secondaryText)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final int catId = category['id'] is int ? category['id'] : int.parse(category['id'].toString());
                  await ApiService.deleteCategory(catId);
                  _fetchCategories();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus: $e')),
                    );
                  }
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _selectedTab == 0 ? _expenseCategories : _incomeCategories;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.secondaryText.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kategori Transaksi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddCategoryDialog,
                    icon: Icon(Icons.add_circle_rounded, color: widget.isDarkMode ? widget.limeColor : const Color(0xFF172033), size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? widget.cardColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Pengeluaran',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedTab == 0 ? widget.primaryText : widget.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? widget.cardColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Pemasukan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _selectedTab == 1 ? widget.primaryText : widget.secondaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada kategori.',
                              style: TextStyle(color: widget.secondaryText),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final item = list[i];
                              final name = item['name']?.toString() ?? '-';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? AppColors.surfaceDarkHigh : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedTab == 0 ? Icons.arrow_circle_down_rounded : Icons.arrow_circle_up_rounded,
                                      color: _selectedTab == 0 ? Colors.redAccent : Colors.green,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: widget.primaryText,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _showEditCategoryDialog(item),
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)),
                                      tooltip: 'Edit Kategori',
                                    ),
                                    IconButton(
                                      onPressed: () => _confirmDeleteCategory(item),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                      tooltip: 'Hapus Kategori',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}