import 'package:flutter/material.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════
// LoadingOverlay — Overlay de chargement réutilisable PharmaAI
//
// 2 modes d'utilisation :
//
// 1️⃣ Wrapping widget (recommandé) :
//    LoadingOverlay(
//      isLoading: _isLoading,
//      message: 'Chargement...',
//      child: MonWidget(),
//    )
//
// 2️⃣ Overlay global (toute la page) :
//    if (_isLoading) LoadingOverlay.fullScreen(context, 'Envoi...')
//
// Paramètres :
//   - isLoading : affiche ou masque l'overlay
//   - message   : texte sous le spinner (optionnel)
//   - child     : widget enfant à obscurcir
//   - opaque    : fond complètement opaque (défaut : false)
// ═══════════════════════════════════════════════════════════════

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final bool opaque;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.opaque = false,
  });

  // ── Mode plein écran (affichage via showDialog) ────────────
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => _SpinnerDialog(message: message),
    );
  }

  // ── Masquer le plein écran ─────────────────────────────────
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Contenu de base ───────────────────────────────
        child,

        // ── Overlay de chargement ─────────────────────────
        if (isLoading)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: opaque
                    ? AppColors.background(context)
                    : Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: _SpinnerCard(message: message),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Widget interne — Carte spinner
// ═══════════════════════════════════════════════════════════════
class _SpinnerCard extends StatelessWidget {
  final String? message;

  const _SpinnerCard({this.message});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Spinner animé ──────────────────────────────
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: primary,
              strokeWidth: 3.5,
              strokeCap: StrokeCap.round,
            ),
          ),

          // ── Message optionnel ──────────────────────────
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Widget interne — Dialog plein écran
// ═══════════════════════════════════════════════════════════════
class _SpinnerDialog extends StatelessWidget {
  final String? message;

  const _SpinnerDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: _SpinnerCard(message: message));
  }
}