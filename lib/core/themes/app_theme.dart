import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppColors {
  static const primary = Color.fromARGB(237, 0, 0, 0); // Black
  static const secondary = Color(0xFFB5E2FA); // Light Blue
  static const background = Color(0xFFF9F7F3); // Off-white
  static const accent = Color(0xFF87CEEB); // Sky Blue
  static const highlight = Color.fromRGBO(172, 114, 247, 1); // purple
}

class AppTheme {
  static ThemeData lightTheme(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: isArabic ? 'Cairo' : 'Poppins', // you can add custom fonts
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black,
      ),
    );
  }
}
