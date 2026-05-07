import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Utilise Riverpod pour l'état global + SharedPreferences

const String _kLanguageKey = 'pharma_ai_language';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>(
      (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<Locale> {

  LanguageNotifier() : super(const Locale('fr')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguageKey);

    switch (saved) {
      case 'en':
        state = const Locale('en');
        break;
      case 'ar':
        state = const Locale('ar');
        break;
      default:
        state = const Locale('fr');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, locale.languageCode);
  }
  bool get isFrench  => state.languageCode == 'fr';
  bool get isEnglish => state.languageCode == 'en';
  bool get isArabic  => state.languageCode == 'ar';
}