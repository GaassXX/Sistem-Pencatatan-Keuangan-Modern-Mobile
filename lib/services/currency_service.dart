import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double rateToIdr; // 1 unit currency = X IDR
  final bool isPopular;

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.rateToIdr,
    this.isPopular = false,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
      };
}

class CurrencyService {
  static const CurrencyModel defaultCurrency = CurrencyModel(
    code: 'IDR',
    name: 'Rupiah Indonesia',
    symbol: 'Rp',
    flag: '🇮🇩',
    rateToIdr: 1.0,
    isPopular: true,
  );

  static final List<CurrencyModel> currencies = [
    // --- INDONESIA (Base) ---
    defaultCurrency,

    // --- POPULER DUNIA ---
    const CurrencyModel(
      code: 'USD',
      name: 'Dolar Amerika Serikat',
      symbol: '\$',
      flag: '🇺🇸',
      rateToIdr: 16000.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'EUR',
      name: 'Euro Uni Eropa',
      symbol: '€',
      flag: '🇪🇺',
      rateToIdr: 17500.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'SGD',
      name: 'Dolar Singapura',
      symbol: 'S\$',
      flag: '🇸🇬',
      rateToIdr: 12000.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'MYR',
      name: 'Ringgit Malaysia',
      symbol: 'RM',
      flag: '🇲🇾',
      rateToIdr: 3600.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'JPY',
      name: 'Yen Jepang',
      symbol: '¥',
      flag: '🇯🇵',
      rateToIdr: 105.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'GBP',
      name: 'Pound Sterling Inggris',
      symbol: '£',
      flag: '🇬🇧',
      rateToIdr: 20500.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'SAR',
      name: 'Riyal Arab Saudi',
      symbol: 'SAR',
      flag: '🇸🇦',
      rateToIdr: 4260.0,
      isPopular: true,
    ),

    // --- ASIA & PASIFIK ---
    const CurrencyModel(
      code: 'CNY',
      name: 'Yuan Tiongkok',
      symbol: '¥',
      flag: '🇨🇳',
      rateToIdr: 2220.0,
    ),
    const CurrencyModel(
      code: 'KRW',
      name: 'Won Korea Selatan',
      symbol: '₩',
      flag: '🇰🇷',
      rateToIdr: 11.5,
    ),
    const CurrencyModel(
      code: 'HKD',
      name: 'Dolar Hong Kong',
      symbol: 'HK\$',
      flag: '🇭🇰',
      rateToIdr: 2060.0,
    ),
    const CurrencyModel(
      code: 'TWD',
      name: 'Dolar Baru Taiwan',
      symbol: 'NT\$',
      flag: '🇹🇼',
      rateToIdr: 500.0,
    ),
    const CurrencyModel(
      code: 'THB',
      name: 'Baht Thailand',
      symbol: '฿',
      flag: '🇹🇭',
      rateToIdr: 470.0,
    ),
    const CurrencyModel(
      code: 'PHP',
      name: 'Peso Filipina',
      symbol: '₱',
      flag: '🇵🇭',
      rateToIdr: 280.0,
    ),
    const CurrencyModel(
      code: 'VND',
      name: 'Dong Vietnam',
      symbol: '₫',
      flag: '🇻🇳',
      rateToIdr: 0.63,
    ),
    const CurrencyModel(
      code: 'INR',
      name: 'Rupee India',
      symbol: '₹',
      flag: '🇮🇳',
      rateToIdr: 190.0,
    ),
    const CurrencyModel(
      code: 'AUD',
      name: 'Dolar Australia',
      symbol: 'A\$',
      flag: '🇦🇺',
      rateToIdr: 10500.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'NZD',
      name: 'Dolar Selandia Baru',
      symbol: 'NZ\$',
      flag: '🇳🇿',
      rateToIdr: 9600.0,
    ),

    // --- TIMUR TENGAH ---
    const CurrencyModel(
      code: 'AED',
      name: 'Dirham Uni Emirat Arab',
      symbol: 'AED',
      flag: '🇦🇪',
      rateToIdr: 4350.0,
      isPopular: true,
    ),
    const CurrencyModel(
      code: 'QAR',
      name: 'Riyal Qatar',
      symbol: 'QAR',
      flag: '🇶🇦',
      rateToIdr: 4390.0,
    ),
    const CurrencyModel(
      code: 'KWD',
      name: 'Dinar Kuwait',
      symbol: 'KWD',
      flag: '🇰🇼',
      rateToIdr: 52000.0,
    ),

    // --- EROPA ---
    const CurrencyModel(
      code: 'CHF',
      name: 'Franc Swiss',
      symbol: 'CHF',
      flag: '🇨🇭',
      rateToIdr: 18200.0,
    ),
    const CurrencyModel(
      code: 'TRY',
      name: 'Lira Turki',
      symbol: '₺',
      flag: '🇹🇷',
      rateToIdr: 460.0,
    ),
    const CurrencyModel(
      code: 'RUB',
      name: 'Rubel Rusia',
      symbol: '₽',
      flag: '🇷🇺',
      rateToIdr: 165.0,
    ),

    // --- AMERIKA ---
    const CurrencyModel(
      code: 'CAD',
      name: 'Dolar Kanada',
      symbol: 'CA\$',
      flag: '🇨🇦',
      rateToIdr: 11600.0,
    ),
    const CurrencyModel(
      code: 'BRL',
      name: 'Real Brasil',
      symbol: 'R\$',
      flag: '🇧🇷',
      rateToIdr: 2800.0,
    ),
    const CurrencyModel(
      code: 'MXN',
      name: 'Peso Meksiko',
      symbol: 'MX\$',
      flag: '🇲🇽',
      rateToIdr: 800.0,
    ),

    // --- AFRIKA ---
    const CurrencyModel(
      code: 'ZAR',
      name: 'Rand Afrika Selatan',
      symbol: 'R',
      flag: '🇿🇦',
      rateToIdr: 890.0,
    ),
    const CurrencyModel(
      code: 'EGP',
      name: 'Pound Mesir',
      symbol: 'EGP',
      flag: '🇪🇬',
      rateToIdr: 325.0,
    ),
  ];

  static final ValueNotifier<CurrencyModel> currencyNotifier =
      ValueNotifier<CurrencyModel>(defaultCurrency);

  static CurrencyModel get current => currencyNotifier.value;

  static Future<void> init() async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        final code = json['code'];
        final found = currencies.firstWhere(
          (c) => c.code == code,
          orElse: () => defaultCurrency,
        );
        currencyNotifier.value = found;
      }
    } catch (_) {
      currencyNotifier.value = defaultCurrency;
    }
  }

  static Future<void> setCurrency(CurrencyModel currency) async {
    currencyNotifier.value = currency;
    try {
      final file = await _getStorageFile();
      await file.writeAsString(jsonEncode({'code': currency.code}));
    } catch (_) {}
  }

  static Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/currency_preference.json');
  }

  /// Format angka nominal IDR asli ke tampilan mata uang aktif
  static String format(dynamic value) {
    final double rawIdr = _parseAmount(value);
    final currency = current;

    if (currency.code == 'IDR') {
      final number = rawIdr.round();
      final text = number.toString();
      final formatted = text.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );
      return 'Rp $formatted';
    }

    final converted = rawIdr / currency.rateToIdr;

    // Untuk mata uang tanpa pecahan desimal umum (JPY, KRW, VND)
    if (currency.code == 'JPY' || currency.code == 'KRW' || currency.code == 'VND') {
      final rounded = converted.round();
      final text = rounded.toString();
      final formatted = text.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
      return '${currency.symbol} $formatted';
    }

    // Untuk mata uang internasional standar dengan 2 desimal
    final parts = converted.toStringAsFixed(2).split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    final decimalPart = parts[1];

    return '${currency.symbol} $integerPart.$decimalPart';
  }

  /// Format ringkas (jt/rb untuk IDR, K/M/B untuk mata uang global)
  static String formatShort(dynamic value) {
    final double rawIdr = _parseAmount(value);
    final currency = current;

    if (currency.code == 'IDR') {
      if (rawIdr >= 1000000000) return 'Rp ${(rawIdr / 1000000000).toStringAsFixed(1)} M';
      if (rawIdr >= 1000000) return 'Rp ${(rawIdr / 1000000).toStringAsFixed(1)} jt';
      if (rawIdr >= 1000) return 'Rp ${(rawIdr / 1000).toStringAsFixed(0)} rb';
      return format(rawIdr);
    }

    final converted = rawIdr / currency.rateToIdr;

    if (converted >= 1000000000) {
      return '${currency.symbol} ${(converted / 1000000000).toStringAsFixed(1)}B';
    }
    if (converted >= 1000000) {
      return '${currency.symbol} ${(converted / 1000000).toStringAsFixed(1)}M';
    }
    if (converted >= 1000) {
      return '${currency.symbol} ${(converted / 1000).toStringAsFixed(1)}K';
    }

    return format(rawIdr);
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }
}
