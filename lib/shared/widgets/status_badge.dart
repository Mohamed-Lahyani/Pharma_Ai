import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// StatusBadge — Badge de statut réutilisable PharmaAI
//
// Utilisé pour afficher les statuts :
//   - ordonnances : pending / validated / rejected
//   - stock       : ok / low / critical
//   - rappels     : active / inactive
//   - utilisateurs: admin / client
//
// Variantes prédéfinies via StatusBadge.fromStatus()
// ou personnalisable avec label + color + icon
// ═══════════════════════════════════════════════════════════════

// ── Couleurs sémantiques fixes (métier) ───────────────────────
const Color _vert  = Color(0xFF2E7D32);
const Color _ambre = Color(0xFFF9A825);
const Color _rouge = Color(0xFFC62828);
const Color _bleu  = Color(0xFF1565C0);
const Color _gris  = Color(0xFF607D8B);

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  // ── Constructeur : statut ordonnance ──────────────────────
  factory StatusBadge.ordonnance(String status, {bool small = false}) {
    switch (status) {
      case 'validated':
        return StatusBadge(
          label: 'Validée',
          color: _vert,
          icon: Icons.check_circle,
          small: small,
        );
      case 'rejected':
        return StatusBadge(
          label: 'Rejetée',
          color: _rouge,
          icon: Icons.cancel,
          small: small,
        );
      default:
        return StatusBadge(
          label: 'En attente',
          color: _ambre,
          icon: Icons.hourglass_empty,
          small: small,
        );
    }
  }

  // ── Constructeur : niveau de stock ────────────────────────
  factory StatusBadge.stock(int quantite, {bool small = false}) {
    if (quantite <= 0) {
      return StatusBadge(
        label: 'Rupture',
        color: _rouge,
        icon: Icons.remove_circle,
        small: small,
      );
    } else if (quantite < 5) {
      return StatusBadge(
        label: 'Stock bas ($quantite)',
        color: _ambre,
        icon: Icons.warning_amber,
        small: small,
      );
    } else {
      return StatusBadge(
        label: 'En stock ($quantite)',
        color: _vert,
        icon: Icons.inventory_2_outlined,
        small: small,
      );
    }
  }

  // ── Constructeur : rôle utilisateur ───────────────────────
  factory StatusBadge.role(String role, {bool small = false}) {
    switch (role) {
      case 'admin':
        return StatusBadge(
          label: 'Admin',
          color: _bleu,
          icon: Icons.admin_panel_settings,
          small: small,
        );
      default:
        return StatusBadge(
          label: 'Client',
          color: _gris,
          icon: Icons.person_outline,
          small: small,
        );
    }
  }

  // ── Constructeur : état rappel ────────────────────────────
  factory StatusBadge.rappel(bool actif, {bool small = false}) {
    return StatusBadge(
      label: actif ? 'Actif' : 'Inactif',
      color: actif ? _vert : _gris,
      icon: actif ? Icons.alarm_on : Icons.alarm_off,
      small: small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize    = small ? 10 : 11;
    final double iconSize    = small ? 10 : 12;
    final double paddingH    = small ? 7  : 10;
    final double paddingV    = small ? 2  : 4;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: color),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}