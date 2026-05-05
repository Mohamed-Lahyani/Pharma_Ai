import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// ThemeProvider — Gestion du thème clair/sombre
// Utilise Riverpod pour l'état global + SharedPreferences
// pour mémoriser le choix de l'utilisateur entre les sessions
// ═══════════════════════════════════════════════════════════════

// ── Clé de stockage dans SharedPreferences ──────────────────────
const String _kThemeKey = 'pharma_ai_theme_mode';

// ── Provider principal du thème ─────────────────────────────────
// Accessible depuis n'importe quel widget via ref.watch(themeProvider)
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
      (ref) => ThemeNotifier(),
);

// ═══════════════════════════════════════════════════════════════
// ThemeNotifier — Logique de gestion du thème
// ═══════════════════════════════════════════════════════════════
class ThemeNotifier extends StateNotifier<ThemeMode> {

  // Démarrer en mode système par défaut
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme(); // charger le thème sauvegardé au démarrage
  }

  // ── Charger le thème depuis SharedPreferences ────────────────
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);

    // Convertir la chaîne sauvegardée en ThemeMode
    switch (saved) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system; // par défaut : suivre le système
    }
  }

  // ── Changer le thème et le sauvegarder ──────────────────────
  Future<void> setTheme(ThemeMode mode) async {
    state = mode; // mettre à jour l'état immédiatement

    // Sauvegarder dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_kThemeKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_kThemeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_kThemeKey, 'system');
        break;
    }
  }

  // ── Basculer rapidement entre clair et sombre ────────────────
  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setTheme(ThemeMode.light);
    } else {
      await setTheme(ThemeMode.dark);
    }
  }

  // ── Getters utiles ───────────────────────────────────────────
  bool get isDark   => state == ThemeMode.dark;
  bool get isLight  => state == ThemeMode.light;
  bool get isSystem => state == ThemeMode.system;
}