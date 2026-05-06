import 'package:flutter/material.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════
// CustomCard — Carte réutilisable PharmaAI
//
// Variantes :
//   - standard  : carte simple avec ombre légère
//   - outlined  : carte avec bordure colorée (accentColor)
//   - flat      : carte sans ombre ni bordure (fond plat)
//   - colored   : fond teinté selon accentColor
//
// Paramètres :
//   - child        : contenu de la carte
//   - padding      : padding interne (défaut : 16)
//   - margin       : margin externe (défaut : bottom 12)
//   - accentColor  : couleur d'accent pour outlined/colored
//   - onTap        : rend la carte cliquable (InkWell)
//   - borderRadius : arrondi des coins (défaut : 16)
//   - variant      : standard | outlined | flat | colored
// ═══════════════════════════════════════════════════════════════

enum CardVariant { standard, outlined, flat, colored }

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final CardVariant variant;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.accentColor,
    this.onTap,
    this.borderRadius = 16,
    this.variant = CardVariant.standard,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent  = accentColor ?? primary;

    // ── Résolution du style selon la variante ──────────────
    final Color cardColor;
    final Color borderColor;
    final double cardElevation;

    switch (variant) {
      case CardVariant.standard:
        cardColor     = AppColors.surface(context);
        borderColor   = AppColors.border(context);
        cardElevation = elevation ?? 2;
        break;
      case CardVariant.outlined:
        cardColor     = AppColors.surface(context);
        borderColor   = accent.withValues(alpha: 0.4);
        cardElevation = elevation ?? 0;
        break;
      case CardVariant.flat:
        cardColor     = AppColors.surface(context);
        borderColor   = Colors.transparent;
        cardElevation = elevation ?? 0;
        break;
      case CardVariant.colored:
        cardColor     = accent.withValues(alpha: 0.07);
        borderColor   = accent.withValues(alpha: 0.2);
        cardElevation = elevation ?? 0;
        break;
    }

    // ── Construction de la carte ───────────────────────────
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: borderColor, width: 1.2),
    );

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    // ── Cliquable si onTap défini ──────────────────────────
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return Card(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      color: cardColor,
      elevation: cardElevation,
      shadowColor: AppColors.isDark(context)
          ? Colors.black45
          : Colors.black12,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}