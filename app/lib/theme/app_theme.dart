import 'package:flutter/material.dart';

class AppColors {
  // Surfaces & Backgrounds (Modo Claro Prioritario)
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfacePorcelain = Color(0xFFF8FAFC);
  static const Color surfaceSlateLight = Color(0xFFF1F5F9);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Accents & States (Sobrios, armónicos)
  static const Color steelBlue = Color(0xFF4A6FA5);
  static const Color steelBlueLight = Color(0xFFE8EEF5);
  
  static const Color sageGreen = Color(0xFF68A678);
  static const Color sageGreenLight = Color(0xFFEBF5EE);

  static const Color amberWarning = Color(0xFFE09F67);
  static const Color amberWarningLight = Color(0xFFFDF5ED);

  static const Color alertCoral = Color(0xFFD97D7D);
  static const Color alertCrimson = Color(0xFFDC2626);
  static const Color alertCoralLight = Color(0xFFFEECEC);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfacePorcelain,
      colorScheme: const ColorScheme.light(
        primary: AppColors.steelBlue,
        onPrimary: Colors.white,
        secondary: AppColors.sageGreen,
        onSecondary: Colors.white,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textPrimary,
        error: AppColors.alertCrimson,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.steelBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
