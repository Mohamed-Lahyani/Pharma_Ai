import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// AppTheme — Définition des thèmes clair et sombre de PharmaAI
// Toutes les couleurs et styles centralisés ici
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  // ── Couleurs principales (identiques dans les deux thèmes) ──
  static const Color primaryBlue    = Color(0xFF1565C0);
  static const Color primaryBlueDark= Color(0xFF1E88E5);
  static const Color green          = Color(0xFF2E7D32);
  static const Color amber          = Color(0xFFF9A825);
  static const Color red            = Color(0xFFC62828);

  // ── Couleurs thème CLAIR ────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface    = Colors.white;
  static const Color lightOnSurface  = Color(0xFF1A1A2E);

  // ── Couleurs thème SOMBRE ───────────────────────────────────
  static const Color darkBackground  = Color(0xFF0D1117);
  static const Color darkSurface     = Color(0xFF161B22);
  static const Color darkSurface2    = Color(0xFF21262D);
  static const Color darkOnSurface   = Color(0xFFE6EDF3);

  // ════════════════════════════════════════════════════════════
  // THÈME CLAIR
  // ════════════════════════════════════════════════════════════
  static ThemeData get lightTheme => ThemeData(
    useMaterial3      : true,
    brightness        : Brightness.light,
    colorScheme       : ColorScheme.fromSeed(
      seedColor  : primaryBlue,
      brightness : Brightness.light,
      primary    : primaryBlue,
      secondary  : green,
      error      : red,
      surface    : lightSurface,
      onPrimary  : Colors.white,
      onSecondary: Colors.white,
      onSurface  : lightOnSurface,
    ),

    scaffoldBackgroundColor: lightBackground,

    // ── AppBar ────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor   : primaryBlue,
      foregroundColor   : Colors.white,
      elevation         : 0,
      centerTitle       : false,
      titleTextStyle    : TextStyle(
        color     : Colors.white,
        fontSize  : 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme         : IconThemeData(color: Colors.white),
    ),

    // ── Cartes ────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color        : lightSurface,
      elevation    : 2,
      shadowColor  : Colors.black12,
      shape        : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
    ),

    // ── Boutons élevés ────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),

    // ── Boutons outlined ──────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 14),
      ),
    ),

    // ── Champs de texte ───────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled          : true,
      fillColor       : Colors.white,
      contentPadding  : const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      border          : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: Color(0xFFBBDEFB)),
      ),
      enabledBorder   : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: Color(0xFFBBDEFB)),
      ),
      focusedBorder   : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder     : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: red),
      ),
      labelStyle      : const TextStyle(color: Colors.grey),
      prefixIconColor : primaryBlue,
    ),

    // ── SnackBar ──────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior         : SnackBarBehavior.floating,
      shape            : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      contentTextStyle : const TextStyle(color: Colors.white),
    ),

    // ── Divider ───────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color    : Color(0xFFE0E0E0),
      thickness: 1,
    ),

    // ── Switch ────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primaryBlue : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
            ? primaryBlue.withOpacity(0.4)
            : Colors.grey.withOpacity(0.3),
      ),
    ),
  );

  // ════════════════════════════════════════════════════════════
  // THÈME SOMBRE
  // ════════════════════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
    useMaterial3      : true,
    brightness        : Brightness.dark,
    colorScheme       : ColorScheme.fromSeed(
      seedColor  : primaryBlueDark,
      brightness : Brightness.dark,
      primary    : primaryBlueDark,
      secondary  : green,
      error      : red,
      surface    : darkSurface,
      onPrimary  : Colors.white,
      onSecondary: Colors.white,
      onSurface  : darkOnSurface,
    ),

    scaffoldBackgroundColor: darkBackground,

    // ── AppBar ────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor   : darkSurface,
      foregroundColor   : darkOnSurface,
      elevation         : 0,
      centerTitle       : false,
      titleTextStyle    : TextStyle(
        color     : darkOnSurface,
        fontSize  : 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme         : IconThemeData(color: darkOnSurface),
    ),

    // ── Cartes ────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color      : darkSurface,
      elevation  : 0,
      shape      : RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side        : const BorderSide(color: darkSurface2),
      ),
    ),

    // ── Boutons élevés ────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlueDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),

    // ── Boutons outlined ──────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlueDark,
        side: const BorderSide(color: primaryBlueDark),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 14),
      ),
    ),

    // ── Champs de texte ───────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled          : true,
      fillColor       : darkSurface2,
      contentPadding  : const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      border          : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: darkSurface2),
      ),
      enabledBorder   : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: darkSurface2),
      ),
      focusedBorder   : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: primaryBlueDark, width: 2),
      ),
      errorBorder     : OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide  : const BorderSide(color: red),
      ),
      labelStyle      : TextStyle(color: Colors.grey[400]),
      prefixIconColor : primaryBlueDark,
    ),

    // ── SnackBar ──────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior         : SnackBarBehavior.floating,
      backgroundColor  : darkSurface2,
      shape            : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      contentTextStyle : const TextStyle(color: darkOnSurface),
    ),

    // ── Divider ───────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color    : darkSurface2,
      thickness: 1,
    ),

    // ── Switch ────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
            ? primaryBlueDark
            : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
            ? primaryBlueDark.withOpacity(0.4)
            : Colors.grey.withOpacity(0.3),
      ),
    ),
  );
}