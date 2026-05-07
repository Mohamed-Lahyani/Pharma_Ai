import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeKey = 'pharma_ai_theme_mode';

final themeProvider =
StateNotifierProvider<ThemeNotifier, ThemeMode>(
      (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_kThemeKey);

    switch (savedTheme) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();

    if (mode == ThemeMode.light) {
      await prefs.setString(_kThemeKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString(_kThemeKey, 'dark');
    } else {
      await prefs.setString(_kThemeKey, 'system');
    }
  }

  Future<void> toggleTheme() async {
    await setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}