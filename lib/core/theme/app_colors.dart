import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF16A34A);
  static const Color primaryDark = Color(0xFF22C55E);
  static const Color primaryDarkSoft = Color(0xFF1B8F4B);
  static const Color red = Color(0xFFEF4444);
  static const Color amber = Color(0xFFFACC15);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF1F2937);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurface2 = Color(0xFF2A3A4A);

  static const Color darkText = Color(0xFFF8FAFC);
  static const Color greenDarkMuted = Color(0xFF1A4D33);

  static Color background(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color primaryAdaptive(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF6B7280);
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface2
        : const Color(0xFFE5E7EB);
  }

  static Color inputFill(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : Colors.white;
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}