/// Helper untuk kategori transaksi: nama, icon, warna.
library;

import 'package:flutter/material.dart';
import '../services/currency_service.dart';

double amountValue(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '0') ?? 0;
}

String formatRupiahTx(dynamic value) {
  return CurrencyService.format(value);
}

String formatShortRupiah(dynamic value) {
  return CurrencyService.formatShort(value);
}

String categoryName(dynamic item) {
  final category = item['category'];
  if (category is Map) return category['name']?.toString() ?? 'Lainnya';
  if (category == null) return 'Lainnya';
  final value = category.toString();
  if (value.isEmpty || value == '-') return 'Lainnya';
  return value;
}

IconData categoryIcon(String category) {
  final v = category.toLowerCase();
  if (v.contains('makan') || v.contains('food') || v.contains('kuliner')) return Icons.restaurant_outlined;
  if (v.contains('transport') || v.contains('kendaraan') || v.contains('bensin')) return Icons.local_gas_station_outlined;
  if (v.contains('gaji') || v.contains('bonus') || v.contains('pendapatan')) return Icons.payments_outlined;
  if (v.contains('belanja') || v.contains('shopping')) return Icons.shopping_bag_outlined;
  if (v.contains('invest')) return Icons.trending_up_outlined;
  if (v.contains('tagihan') || v.contains('listrik') || v.contains('internet')) return Icons.receipt_long_outlined;
  if (v.contains('hiburan')) return Icons.movie_outlined;
  if (v.contains('kesehatan')) return Icons.health_and_safety_outlined;
  if (v.contains('pendidikan') || v.contains('sekolah') || v.contains('kuliah')) return Icons.school_outlined;
  if (v.contains('jajan') || v.contains('snack') || v.contains('camilan')) return Icons.local_cafe_outlined;
  return Icons.account_balance_wallet_outlined;
}

/// Warna utama per kategori — digunakan untuk icon, progress bar, strip, dan badge %.
Color categoryColor(String category) {
  final v = category.toLowerCase();
  if (v.contains('makan') || v.contains('food') || v.contains('kuliner')) return const Color(0xFFF59E0B); // Amber
  if (v.contains('transport') || v.contains('kendaraan') || v.contains('bensin')) return const Color(0xFF3B82F6); // Blue
  if (v.contains('gaji') || v.contains('bonus') || v.contains('pendapatan')) return const Color(0xFF10B981); // Emerald
  if (v.contains('belanja') || v.contains('shopping')) return const Color(0xFF8B5CF6); // Purple
  if (v.contains('invest')) return const Color(0xFF06B6D4); // Cyan
  if (v.contains('tagihan') || v.contains('listrik') || v.contains('internet')) return const Color(0xFF0EA5E9); // Sky Blue
  if (v.contains('hiburan')) return const Color(0xFFEC4899); // Pink
  if (v.contains('kesehatan')) return const Color(0xFFEF4444); // Red
  if (v.contains('pendidikan') || v.contains('sekolah') || v.contains('kuliah')) return const Color(0xFF6366F1); // Indigo
  if (v.contains('jajan') || v.contains('snack') || v.contains('camilan')) return const Color(0xFFFF7849); // Orange
  return const Color(0xFF64748B); // Slate default
}

/// Warna background icon — pastel ringan dari warna utama kategori.
Color categoryBackground(String category) {
  return categoryColor(category).withOpacity(0.12);
}

/// Warna icon — sama dengan warna utama kategori.
Color categoryIconColor(String category) {
  return categoryColor(category);
}

String paymentMethodName(dynamic source) {
  final val = source?.toString().toLowerCase().trim();
  switch (val) {
    case 'cash':
    case 'tunai':
      return 'Tunai';
    case 'emoney':
    case 'e-wallet':
    case 'ewallet':
      return 'E-Money';
    case 'bank':
    case 'transfer bank':
      return 'Transfer Bank';
    case 'mbanking':
      return 'M-Banking';
    case 'other':
    case 'lainnya':
      return 'Lainnya';
    default:
      return source?.toString() ?? '-';
  }
}

String paymentMethodShort(dynamic source) {
  final val = source?.toString().toLowerCase().trim();
  switch (val) {
    case 'cash':
    case 'tunai':
      return 'TUNAI';
    case 'emoney':
    case 'e-wallet':
    case 'ewallet':
      return 'E-MONEY';
    case 'bank':
    case 'transfer bank':
      return 'BANK';
    case 'mbanking':
      return 'M-BANKING';
    case 'other':
    case 'lainnya':
      return 'LAINNYA';
    default:
      return '';
  }
}
