import 'dart:io';

import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'pages/login_page.dart';
import 'services/currency_service.dart';

final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await CurrencyService.init();

  runApp(const FinChatApp());
}

class FinChatApp extends StatelessWidget {
  const FinChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeNotifier, CurrencyService.currencyNotifier]),
      builder: (context, _) {
        final themeMode = themeNotifier.value;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FinChat',

          themeMode: themeMode,

          // =====================================================
          // LIGHT THEME (Slate 50 + Deep Indigo & Emerald)
          // =====================================================
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,

            scaffoldBackgroundColor: AppColors.bgLight,

            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBrand,
              secondary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surfaceLight,
              onSurface: AppColors.textPrimary,
              error: AppColors.expense,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.bgLight,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
            ),

            cardTheme: const CardTheme(
              color: AppColors.surfaceLight,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              margin: EdgeInsets.zero,
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,

              labelStyle: const TextStyle(
                color: AppColors.textSecondary,
              ),

              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
              ),

              prefixIconColor: AppColors.textSecondary,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primaryBrand,
                  width: 1.5,
                ),
              ),
            ),

            dividerTheme: const DividerThemeData(
              color: AppColors.borderLight,
              thickness: 1,
            ),

            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.brandBlueLight,
              elevation: 0,
              height: 72,
              labelTextStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              iconTheme: WidgetStatePropertyAll(
                IconThemeData(size: 24),
              ),
            ),
            bottomNavigationBarTheme:
                const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primaryBrand,
              unselectedItemColor: AppColors.textSecondary,
              type: BottomNavigationBarType.fixed,
              elevation: 8,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 11,
              ),
            ),

            elevatedButtonTheme:
                ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          // =====================================================
          // DARK THEME (Slate 900 + Deep Indigo & Emerald)
          // =====================================================
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,

            scaffoldBackgroundColor: AppColors.bgDark,

            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBrand,
              secondary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.textDarkPrimary,
              error: AppColors.expense,
            ),

            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.bgDark,
              foregroundColor: AppColors.textDarkPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
            ),

            cardTheme: const CardTheme(
              color: AppColors.surfaceDark,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              margin: EdgeInsets.zero,
            ),

            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surfaceDark,

              labelStyle: const TextStyle(
                color: AppColors.textDarkSecondary,
              ),

              hintStyle: const TextStyle(
                color: Color(0xFF64748B),
              ),

              prefixIconColor: AppColors.textDarkSecondary,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primaryBrand,
                  width: 1.5,
                ),
              ),
            ),

            dividerTheme: const DividerThemeData(
              color: AppColors.borderDark,
              thickness: 1,
            ),

            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: AppColors.surfaceDark,
              indicatorColor: Color(0xFF312E81), // Deep purple indicator in dark mode
              elevation: 0,
              height: 72,
              labelTextStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDarkPrimary,
                ),
              ),
              iconTheme: WidgetStatePropertyAll(
                IconThemeData(size: 24),
              ),
            ),
            bottomNavigationBarTheme:
                const BottomNavigationBarThemeData(
              backgroundColor: AppColors.surfaceDark,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.textDarkSecondary,
              type: BottomNavigationBarType.fixed,
              elevation: 8,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 11,
              ),
            ),

            elevatedButtonTheme:
                ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          home: const LoginPage(),
        );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
