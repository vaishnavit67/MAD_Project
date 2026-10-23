import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5B3FD3);
  static const Color primaryDark = Color(0xFF4225A8);
  static const Color background = Color(0xFFF8F8FC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF73798A);
  static const Color border = Color(0xFFE5E5EE);
  static const Color success = Color(0xFF36B37E);
  static const Color error = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF59E0B);

  // Feature icon background colors
  static const Color featureIconBg1 = Color(0xFFE8E5F9); // Light Purple
  static const Color featureIconBg2 = Color(0xFFE5F4EB); // Light Green
  static const Color featureIconBg3 = Color(0xFFFDE9ED); // Light Red
  static const Color featureIconBg4 = Color(0xFFFFF4E5); // Light Orange
  static const Color featureIconBg5 = Color(0xFFE5F2FC); // Light Blue
  static const Color featureIconBg6 = Color(0xFFF5E5FC); // Light Pink

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) => isDark(context) ? const Color(0xFF121212) : background;
  static Color card(BuildContext context) => isDark(context) ? const Color(0xFF1E1E1E) : white;
  static Color text(BuildContext context) => isDark(context) ? Colors.white : textPrimary;
  static Color subtext(BuildContext context) => isDark(context) ? const Color(0xFF94A3B8) : textSecondary;
  static Color borderCol(BuildContext context) => isDark(context) ? const Color(0xFF2D3748) : border;
  static Color brd(BuildContext context) => borderCol(context);
}
