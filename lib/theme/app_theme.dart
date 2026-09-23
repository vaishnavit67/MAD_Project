import 'package:flutter/material.dart';

class AppTheme {
  // =========================
  // CAMPUS CONNECT COLORS
  // =========================

  static const Color primaryBlue = Color(0xFF155EEF);
  static const Color darkBlue = Color(0xFF0B3FAE);
  static const Color lightBlue = Color(0xFFEAF2FF);

  static const Color background = Color(0xFFF5F7FB);
  static const Color cardColor = Colors.white;

  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);

  static const Color borderColor = Color(0xFFE4E7EC);

  // =========================
  // LIGHT THEME
  // =========================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: background,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    // =========================
    // TEXT
    // =========================

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),

      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),

      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),

      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),

      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimary,
      ),

      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),

      bodySmall: TextStyle(
        fontSize: 12,
        color: textSecondary,
      ),
    ),

    // =========================
    // ELEVATED BUTTON
    // =========================

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,

        minimumSize: const Size(double.infinity, 52),

        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // =========================
    // INPUT FIELDS
    // =========================

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 2,
        ),
      ),

      hintStyle: const TextStyle(
        color: textSecondary,
      ),
    ),

    // =========================
    // CARDS
    // =========================

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: borderColor,
        ),
      ),

      margin: EdgeInsets.zero,
    ),

    // =========================
    // ICONS
    // =========================

    iconTheme: const IconThemeData(
      color: primaryBlue,
      size: 24,
    ),

    // =========================
    // DIVIDERS
    // =========================

    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
    ),
  );
}