import 'package:flutter/material.dart';

class LFColors {
  static const Color primary = Color(0xFF6366F1); // Modern Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFF8B5CF6); // Deep Purple
  static const Color background = Color(0xFFF8FAFC); // Slate background
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status colors
  static const Color lostBg = Color(0xFFFFF1F2);
  static const Color lostText = Color(0xFFE11D48);
  static const Color lostBorder = Color(0xFFFECDD3);

  static const Color foundBg = Color(0xFFECFDF5);
  static const Color foundText = Color(0xFF059669);
  static const Color foundBorder = Color(0xFFA7F3D0);

  static const Color resolvedBg = Color(0xFFF1F5F9);
  static const Color resolvedText = Color(0xFF475569);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) => isDark(context) ? const Color(0xFF121212) : background;
  static Color card(BuildContext context) => isDark(context) ? const Color(0xFF1E1E1E) : cardBg;
  static Color text(BuildContext context) => isDark(context) ? const Color(0xFFF1F5F9) : textPrimary;
  static Color subtext(BuildContext context) => isDark(context) ? const Color(0xFF94A3B8) : textSecondary;
  static Color muted(BuildContext context) => isDark(context) ? const Color(0xFF64748B) : textMuted;
}
