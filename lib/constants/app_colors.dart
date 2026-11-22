import 'package:flutter/material.dart';

/// Spesifikasi Desain UI/UX Application Mobile — FinChat (Flutter)
/// Pendekatan: Modern Fintech, Trustworthy, Clean, & High-Usability
class AppColors {
  // ── 1. Brand Colors ──────────────────────────────────────────────
  static const Color primaryBrand     = Color(0xFF4F46E5); // Deep Indigo / Modern Blue
  static const Color brandBlue        = Color(0xFF4F46E5); // Alias for compatibility
  static const Color brandBlueLight   = Color(0xFFEEF2FF); // Indigo 50 - Background chip/badge
  static const Color brandPurple      = Color(0xFF7417F6); // FinChat Official Vibrant Purple
  static const Color primaryDark      = Color(0xFF1E1B4B); // Dark Indigo

  // ── 2. Semantics & Finance Status ────────────────────────────────
  static const Color accent           = Color(0xFF10B981); // Emerald / Teal - Tombol aksi utama & Pemasukan
  static const Color income           = Color(0xFF10B981); // Emerald Green 500 - Pemasukan & Sukses
  static const Color incomeLight      = Color(0xFFD1FAE5); // Mint 100 - Latar pemasukan
  static const Color expense          = Color(0xFFEF4444); // Red 500 - Pengeluaran & Bahaya (>100% budget)
  static const Color expenseLight     = Color(0xFFFEE2E2); // Red 100 - Latar pengeluaran
  static const Color warning          = Color(0xFFF59E0B); // Amber 500 - Peringatan Anggaran (>=80%)
  static const Color warningLight     = Color(0xFFFEF3C7); // Amber 100 - Latar peringatan

  // ── 3. Light Mode ────────────────────────────────────────────────
  static const Color bgLight          = Color(0xFFF8FAFC); // Slate 50 - Latar belakang lembut
  static const Color surfaceLight     = Color(0xFFFFFFFF); // White - Card Background
  static const Color textPrimary      = Color(0xFF0F172A); // Slate 900 - Judul / Teks Utama
  static const Color textSecondary    = Color(0xFF64748B); // Slate 500 - Teks Sekunder
  static const Color borderLight      = Color(0xFFE2E8F0); // Slate 200 - Garis Batas Halus

  // Alias getter untuk backward compatibility
  static const Color subtitleLight    = textSecondary;

  // ── 4. Dark Mode ─────────────────────────────────────────────────
  static const Color bgDark           = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark      = Color(0xFF1E293B); // Slate 800
  static const Color surfaceDarkHigh  = Color(0xFF334155); // Slate 700
  static const Color textDarkPrimary  = Color(0xFFF8FAFC); // Slate 50
  static const Color textDarkSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color borderDark       = Color(0xFF334155); // Slate 700

  // Alias getter untuk backward compatibility
  static const Color subtitleDark     = textDarkSecondary;
  static const Color accentDark       = accent;
  static const Color accentLight      = primaryBrand;

  // ── 5. Gradients ─────────────────────────────────────────────────
  // Balance Card: Gradient dari Dark Indigo ke Deep Purple
  static const LinearGradient balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1B4B), // Dark Indigo
      Color(0xFF312E81), // Deep Purple
    ],
  );

  // ── 6. Helper Dynamic Theme ──────────────────────────────────────
  static Color getPrimaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textDarkPrimary : textPrimary;
  }

  static Color getSecondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? textDarkSecondary : textSecondary;
  }

  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;
  }

  static Color getAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? accentDark : accentLight;
  }
}
