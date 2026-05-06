import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/shared/widgets/custom_button.dart';
import 'package:pharma_ai/shared/widgets/custom_card.dart';
import 'package:pharma_ai/shared/widgets/status_badge.dart';
import 'package:pharma_ai/shared/widgets/loading_overlay.dart';

// ═══════════════════════════════════════════════════════════════
// StockAlertsScreen — Alertes stock critique (Admin)
//
// L'admin peut :
//   - Voir tous les médicaments avec stock < 5
//   - Voir les médicaments en rupture (stock = 0)
//   - Réapprovisionner directement depuis cet écran
//   - Filtrer : tous / rupture / stock bas
//   - Voir le niveau de stock avec barre de progression
// ═══════════════════════════════════════════════════════════════

class StockAlertsScreen extends StatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  State<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends State<StockAlertsScreen> {
  // ── Couleurs sémantiques fixes ─────────────────────────────
  static const Color _vert  = Color(0xFF2E7D32);
  static const Color _ambre = Color(0xFFF9A825);
  static const Color _rouge = Color(0xFFC62828);

  // Seuil stock critique
  static const int _seuilCritique = 5;

  // Filtre actuel
  String _filtre = 'tous';

  // Contrôleur quantité réapprovisionnement
  final TextEditingController _qteController = TextEditingController();

  @override
  void dispose() {
    _qteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'Alertes Stock',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _rouge,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          _buildCompteurAlertes(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Bandeau résumé ────────────────────────────────
          _buildBandeauResume(),
          // ── Filtres ───────────────────────────────────────
          _buildFiltreBar(),
          // ── Liste ─────────────────────────────────────────
          Expanded(child: _buildListe()),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Compteur badge dans l'AppBar
  // ════════════════════════════════════════════════════════════
  Widget _buildCompteurAlertes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('stock', isLessThan: _seuilCritique)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          margin: const EdgeInsets.only(top: 8, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count alertes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Bandeau résumé — rupture vs stock bas
  // ════════════════════════════════════════════════════════════
  Widget _buildBandeauResume() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('stock', isLessThan: _seuilCritique)
          .snapshots(),
      builder: (context, snapshot) {
        final docs     = snapshot.data?.docs ?? [];
        final rupture  = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['stock'] ?? 0) == 0;
        }).length;
        final stockBas = docs.length - rupture;

        return Container(
          color: AppColors.surface(context),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Rupture totale
              Expanded(
                child: _buildStatMini(
                  valeur : rupture.toString(),
                  label  : 'Rupture',
                  couleur: _rouge,
                  icone  : Icons.remove_circle,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border(context),
              ),
              // Stock bas
              Expanded(
                child: _buildStatMini(
                  valeur : stockBas.toString(),
                  label  : 'Stock bas',
                  couleur: _ambre,
                  icone  : Icons.warning_amber,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border(context),
              ),
              // Total alertes
              Expanded(
                child: _buildStatMini(
                  valeur : docs.length.toString(),
                  label  : 'Total alertes',
                  couleur: Theme.of(context).colorScheme.primary,
                  icone  : Icons.notifications_active,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatMini({
    required String   valeur,
    required String   label,
    required Color    couleur,
    required IconData icone,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: couleur, size: 16),
            const SizedBox(width: 4),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // Barre de filtres
  // ════════════════════════════════════════════════════════════
  Widget _buildFiltreBar() {
    final filtres = [
      {'label': 'Tous',      'valeur': 'tous',    'couleur': Theme.of(context).colorScheme.primary},
      {'label': 'Rupture',   'valeur': 'rupture', 'couleur': _rouge},
      {'label': 'Stock bas', 'valeur': 'bas',     'couleur': _ambre},
    ];

    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: filtres.map((f) {
          final estActif = _filtre == f['valeur'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label'] as String),
              selected: estActif,
              selectedColor: f['couleur'] as Color,
              labelStyle: TextStyle(
                color: estActif
                    ? Colors.white
                    : AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              onSelected: (_) =>
                  setState(() => _filtre = f['valeur'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Liste des médicaments en alerte
  // ════════════════════════════════════════════════════════════
  Widget _buildListe() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .where('stock', isLessThan: _seuilCritique)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: _rouge),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur : ${snapshot.error}',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          );
        }

        // Filtrage local selon le filtre sélectionné
        var docs = snapshot.data?.docs ?? [];
        if (_filtre == 'rupture') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['stock'] ?? 0) == 0;
          }).toList();
        } else if (_filtre == 'bas') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final stock = data['stock'] ?? 0;
            return stock > 0 && stock < _seuilCritique;
          }).toList();
        }

        // Tri : ruptures en premier
        docs.sort((a, b) {
          final stockA = (a.data() as Map<String, dynamic>)['stock'] ?? 0;
          final stockB = (b.data() as Map<String, dynamic>)['stock'] ?? 0;
          return (stockA as int).compareTo(stockB as int);
        });

        if (docs.isEmpty) {
          return _buildEtatVide();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc  = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildCarteMedicament(doc.id, data);
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Carte médicament en alerte
  // ════════════════════════════════════════════════════════════
  Widget _buildCarteMedicament(String docId, Map<String, dynamic> data) {
    final nom      = data['name'] ?? 'Médicament';
    final stock    = (data['stock'] ?? 0) as int;
    final prix     = data['price'] ?? data['prix'] ?? 0;
    final categorie = data['category'] ?? data['categorie'] ?? '';

    final enRupture  = stock == 0;
    final couleur    = enRupture ? _rouge : _ambre;

    // Pourcentage de la barre (max affiché = seuil critique)
    final double pourcentage =
    stock == 0 ? 0.0 : (stock / _seuilCritique).clamp(0.0, 1.0);

    return CustomCard(
      variant    : CardVariant.outlined,
      accentColor: couleur,
      padding    : const EdgeInsets.all(16),
      child      : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne principale ──────────────────────────────
          Row(
            children: [
              // Icône
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  enRupture
                      ? Icons.remove_circle_outline
                      : Icons.warning_amber_outlined,
                  color: couleur,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Nom + catégorie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.onSurface(context),
                      ),
                    ),
                    if (categorie.isNotEmpty)
                      Text(
                        categorie,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                  ],
                ),
              ),

              // Badge stock
              StatusBadge.stock(stock),
            ],
          ),

          const SizedBox(height: 14),

          // ── Barre de stock ────────────────────────────────
          Row(
            children: [
              Text(
                'Stock : ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
              Text(
                '$stock / $_seuilCritique min.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: couleur,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value          : pourcentage,
              minHeight      : 8,
              backgroundColor: couleur.withValues(alpha: 0.15),
              valueColor     : AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),

          // ── Prix ──────────────────────────────────────────
          if (prix != 0) ...[
            const SizedBox(height: 10),
            Text(
              'Prix unitaire : ${prix.toString()} DT',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Bouton réapprovisionner ───────────────────────
          CustomButton(
            label      : enRupture
                ? 'Réapprovisionner (urgence)'
                : 'Réapprovisionner',
            onPressed  : () => _afficherDialogReapprovisionnement(
                docId, nom, stock),
            icon       : Icons.add_shopping_cart,
            variant    : enRupture
                ? ButtonVariant.danger
                : ButtonVariant.secondary,
            height     : 42,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Dialog réapprovisionnement
  // ════════════════════════════════════════════════════════════
  Future<void> _afficherDialogReapprovisionnement(
      String docId, String nom, int stockActuel) async {
    _qteController.clear();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          '📦 Réapprovisionner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface(context),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info médicament
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _ambre.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _ambre.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: _ambre, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$nom — Stock actuel : $stockActuel',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _ambre,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Champ quantité
            Text(
              'Quantité à ajouter :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface(context),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qteController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ex : 50',
                prefixIcon: Icon(
                  Icons.add_box_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                filled: true,
                fillColor: AppColors.inputFill(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _vert,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    // Validation de la quantité
    final qte = int.tryParse(_qteController.text.trim());
    if (qte == null || qte <= 0) {
      if (mounted) {
        _showSnack('Quantité invalide', _rouge);
      }
      return;
    }

    LoadingOverlay.show(context, message: 'Mise à jour du stock...');

    try {
      // Incrémenter le stock
      await FirebaseFirestore.instance
          .collection('medications')
          .doc(docId)
          .update({
        'stock': stockActuel + qte,
      });

      if (mounted) {
        LoadingOverlay.hide(context);
        _showSnack(
          '✅ Stock mis à jour : ${stockActuel + qte} unités',
          _vert,
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        _showSnack('Erreur : $e', _rouge);
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // État vide — aucune alerte
  // ════════════════════════════════════════════════════════════
  Widget _buildEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _vert.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: _vert,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _filtre == 'rupture'
                ? 'Aucune rupture de stock ✅'
                : _filtre == 'bas'
                ? 'Aucun stock bas ✅'
                : 'Tous les stocks sont OK ✅',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun médicament sous le seuil de $_seuilCritique unités.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper snackbar ────────────────────────────────────────
  void _showSnack(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: couleur,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}