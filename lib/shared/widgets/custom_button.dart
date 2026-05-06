import 'package:flutter/material.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════
// CustomButton — Bouton réutilisable PharmaAI
//
// Variantes disponibles :
//   - primary   : fond coloré (action principale)
//   - secondary : contour sans fond (action secondaire)
//   - danger    : rouge (suppression / action destructive)
//   - ghost     : texte seul sans bordure
//
// Paramètres :
//   - label      : texte affiché
//   - onPressed  : callback (null = désactivé)
//   - icon       : icône optionnelle à gauche
//   - isLoading  : affiche un spinner à la place du label
//   - fullWidth   : prend toute la largeur disponible
//   - variant    : primary | secondary | danger | ghost
// ═══════════════════════════════════════════════════════════════

enum ButtonVariant { primary, secondary, danger, ghost }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final ButtonVariant variant;
  final double? height;
  final double borderRadius;

  // ── Couleurs sémantiques fixes ─────────────────────────────
  static const Color _rouge = Color(0xFFC62828);

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.variant = ButtonVariant.primary,
    this.height,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // ── Résolution des couleurs selon la variante ──────────
    final Color bgColor;
    final Color fgColor;
    final Color borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor     = primary;
        fgColor     = Colors.white;
        borderColor = primary;
        break;
      case ButtonVariant.secondary:
        bgColor     = Colors.transparent;
        fgColor     = primary;
        borderColor = primary;
        break;
      case ButtonVariant.danger:
        bgColor     = Colors.transparent;
        fgColor     = _rouge;
        borderColor = _rouge;
        break;
      case ButtonVariant.ghost:
        bgColor     = Colors.transparent;
        fgColor     = AppColors.textSecondary(context);
        borderColor = Colors.transparent;
        break;
    }

    // ── Construction du contenu du bouton ──────────────────
    Widget contenu;

    if (isLoading) {
      // Spinner pendant le chargement
      contenu = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          color: fgColor,
          strokeWidth: 2.5,
        ),
      );
    } else if (icon != null) {
      // Icône + label
      contenu = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fgColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      // Label seul
      contenu = Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // ── Style du bouton ────────────────────────────────────
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: borderColor, width: 1.5),
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: variant == ButtonVariant.primary ? 2 : 0,
      shadowColor: variant == ButtonVariant.primary
          ? primary.withValues(alpha: 0.3)
          : Colors.transparent,
      shape: shape,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      minimumSize: fullWidth
          ? Size(double.infinity, height ?? 52)
          : Size(0, height ?? 48),
      disabledBackgroundColor: AppColors.border(context),
      disabledForegroundColor: AppColors.textSecondary(context),
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: contenu,
    );
  }
}