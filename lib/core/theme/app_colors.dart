// lib/core/theme/app_colors.dart
//
// Centralize color access via Theme.of(context)
// Utiliser AppColors.of(context).primary au lieu de Color(0xFF1565C0)
// → le thème s'applique instantanément sur tous les écrans
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class AppColors {
  // ── Couleurs fixes (identiques clair/sombre) ────────────────
  static const Color primary    = Color(0xFF1565C0); // bleu médical
  static const Color primaryDark= Color(0xFF1E88E5); // bleu clair (dark mode)
  static const Color green      = Color(0xFF2E7D32); // vert santé
  static const Color amber      = Color(0xFFF9A825); // alertes
  static const Color red        = Color(0xFFC62828); // danger

  // ── Couleurs qui changent selon le thème ────────────────────
  // Utiliser AppColors.background(context) au lieu d'une couleur fixe

  /// Couleur de fond principale (s'adapte au thème)
  static Color background(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  /// Couleur de surface (cartes, conteneurs)
  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Couleur du texte principal
  static Color onSurface(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  /// Couleur primaire selon le thème (bleu foncé en clair, bleu clair en sombre)
  static Color primaryAdaptive(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  /// Couleur de fond des cartes
  static Color cardColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  /// Texte secondaire (gris)
  static Color textSecondary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFFADBBC8)
        : const Color(0xFF6B7280);
  }

  /// Bordure légère
  static Color border(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF21262D)
        : const Color(0xFFE5E7EB);
  }

  /// Fond des inputs
  static Color inputFill(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF21262D)
        : Colors.white;
  }

  /// Vérifier si on est en mode sombre
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}