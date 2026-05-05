import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// LanguageProvider — Gestion de la langue de l'application
// Utilise Riverpod pour l'état global + SharedPreferences
// pour mémoriser le choix de l'utilisateur entre les sessions
// ═══════════════════════════════════════════════════════════════

// ── Clé de stockage dans SharedPreferences ──────────────────────
const String _kLanguageKey = 'pharma_ai_language';

// ── Provider principal de la langue ─────────────────────────────
// Accessible depuis n'importe quel widget via ref.watch(languageProvider)
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>(
      (ref) => LanguageNotifier(),
);

// ═══════════════════════════════════════════════════════════════
// LanguageNotifier — Logique de gestion de la langue
// ═══════════════════════════════════════════════════════════════
class LanguageNotifier extends StateNotifier<Locale> {

  // Démarrer en français par défaut
  LanguageNotifier() : super(const Locale('fr')) {
    _loadLanguage(); // charger la langue sauvegardée au démarrage
  }

  // ── Charger la langue depuis SharedPreferences ───────────────
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguageKey);

    // Convertir le code de langue sauvegardé en Locale
    switch (saved) {
      case 'en':
        state = const Locale('en');
        break;
      case 'ar':
        state = const Locale('ar');
        break;
      default:
        state = const Locale('fr'); // par défaut : français
    }
  }

  // ── Changer la langue et la sauvegarder ─────────────────────
  Future<void> setLocale(Locale locale) async {
    state = locale; // mettre à jour l'état immédiatement

    // Sauvegarder dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, locale.languageCode);
  }

  // ── Getters utiles ──────────────────────────────────────────
  bool get isFrench  => state.languageCode == 'fr';
  bool get isEnglish => state.languageCode == 'en';
  bool get isArabic  => state.languageCode == 'ar';
}