import 'package:flutter/material.dart';
import 'colors.dart';

// Use the font family name directly - Inter is loaded via web/index.html
const String _fontFamily = 'Inter';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: _fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: AppColors.primaryDark,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: _fontFamily, fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryDark),
        titleTextStyle: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primaryDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.textHint),
      ),
      tabBarTheme: const TabBarThemeData(
        labelStyle: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 14),
        dividerColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEEEEEE), thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
