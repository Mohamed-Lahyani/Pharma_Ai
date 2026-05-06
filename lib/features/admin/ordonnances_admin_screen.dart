import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/shared/widgets/custom_button.dart';
import 'package:pharma_ai/shared/widgets/custom_card.dart';
import 'package:pharma_ai/shared/widgets/status_badge.dart';
import 'package:pharma_ai/shared/widgets/loading_overlay.dart';

// ═══════════════════════════════════════════════════════════════
// OrdonnancesAdminScreen — Gestion des ordonnances (Admin)
//
// L'admin peut :
//   - Voir toutes les ordonnances soumises par les clients
//   - Filtrer par statut : toutes / en attente / validées / rejetées
//   - Valider une ordonnance → statut "validated" + notification client
//   - Rejeter une ordonnance → statut "rejected" + motif + notification
//   - Voir le texte OCR extrait + médicaments détectés
// ═══════════════════════════════════════════════════════════════

class OrdonnancesAdminScreen extends StatefulWidget {
  const OrdonnancesAdminScreen({super.key});

  @override
  State<OrdonnancesAdminScreen> createState() =>
      _OrdonnancesAdminScreenState();
}

class _OrdonnancesAdminScreenState extends State<OrdonnancesAdminScreen> {
  // ── Couleurs sémantiques fixes (métier) ────────────────────
  static const Color _vert  = Color(0xFF2E7D32);
  static const Color _ambre = Color(0xFFF9A825);
  static const Color _rouge = Color(0xFFC62828);

  // Filtre actuel
  String _filtre = 'tous';

  // Contrôleur motif de rejet
  final TextEditingController _motifController = TextEditingController();

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'Ordonnances',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        // ── Compteur ordonnances en attente ──────────────
        actions: [
          _buildCompteurEnAttente(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFiltreBar(),
          Expanded(child: _buildListe()),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Compteur badge — ordonnances en attente
  // ════════════════════════════════════════════════════════════
  Widget _buildCompteurEnAttente() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ordonnances')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 8, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _ambre,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count en attente',
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
  // Barre de filtres
  // ════════════════════════════════════════════════════════════
  Widget _buildFiltreBar() {
    final filtres = [
      {'label': 'Toutes',     'valeur': 'tous',      'couleur': Theme.of(context).colorScheme.primary},
      {'label': 'En attente', 'valeur': 'pending',   'couleur': _ambre},
      {'label': 'Validées',   'valeur': 'validated', 'couleur': _vert},
      {'label': 'Rejetées',   'valeur': 'rejected',  'couleur': _rouge},
    ];

    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Liste des ordonnances en temps réel
  // ════════════════════════════════════════════════════════════
  Widget _buildListe() {
    // Construction de la requête selon le filtre
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('ordonnances')
        .orderBy('createdAt', descending: true);

    if (_filtre != 'tous') {
      query = FirebaseFirestore.instance
          .collection('ordonnances')
          .where('status', isEqualTo: _filtre)
          .orderBy('createdAt', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56,
                    color: _rouge.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'Erreur : ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEtatVide();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc  = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildCarteOrdonnance(doc.id, data);
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Carte d'une ordonnance
  // ════════════════════════════════════════════════════════════
  Widget _buildCarteOrdonnance(String docId, Map<String, dynamic> data) {
    final statut    = data['status'] ?? 'pending';
    final texte     = data['extractedText'] ?? 'Aucun texte extrait';
    final medicines = data['medicines'] as List<dynamic>? ?? [];
    final userId    = data['userId'] ?? '';
    final motifRejet = data['motifRejet'] ?? '';

    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}  '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}'
        : '—';

    // Couleur de la carte selon le statut
    final couleurStatut = statut == 'validated'
        ? _vert
        : statut == 'rejected'
        ? _rouge
        : _ambre;

    return CustomCard(
      variant: CardVariant.outlined,
      accentColor: couleurStatut,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // ── En-tête ──────────────────────────────────────
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: couleurStatut.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statut == 'validated'
                  ? Icons.check_circle
                  : statut == 'rejected'
                  ? Icons.cancel
                  : Icons.hourglass_empty,
              color: couleurStatut,
              size: 22,
            ),
          ),
          title: Text(
            'Ordonnance — $dateStr',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.onSurface(context),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                StatusBadge.ordonnance(statut, small: true),
                const SizedBox(width: 8),
                // Récupérer le nom du client
                _buildNomClient(userId),
              ],
            ),
          ),

          // ── Contenu déplié ────────────────────────────────
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppColors.border(context)),

                  // ── Médicaments détectés ─────────────────
                  if (medicines.isNotEmpty) ...[
                    _sousTitre('💊 Médicaments détectés (${medicines.length})'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: medicines.map((m) => Chip(
                        label: Text(
                          m.toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Theme.of(context)
                            .colorScheme.primary
                            .withValues(alpha: 0.08),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme.primary
                              .withValues(alpha: 0.2),
                        ),
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Texte OCR extrait ─────────────────────
                  _sousTitre('📄 Texte OCR extrait'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      texte,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.onSurface(context),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                  // ── Motif de rejet (si rejeté) ────────────
                  if (statut == 'rejected' && motifRejet.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _rouge.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _rouge.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: _rouge),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Motif : $motifRejet',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _rouge,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Boutons d'action (seulement si pending) ─
                  if (statut == 'pending') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Valider
                        Expanded(
                          child: CustomButton(
                            label: 'Valider',
                            onPressed: () =>
                                _validerOrdonnance(docId, userId),
                            icon: Icons.check_circle_outline,
                            variant: ButtonVariant.primary,
                            height: 44,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Rejeter
                        Expanded(
                          child: CustomButton(
                            label: 'Rejeter',
                            onPressed: () =>
                                _afficherDialogRejet(docId, userId),
                            icon: Icons.cancel_outlined,
                            variant: ButtonVariant.danger,
                            height: 44,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Bouton repasser en attente (si déjà traité) ─
                  if (statut != 'pending') ...[
                    const SizedBox(height: 12),
                    CustomButton(
                      label: 'Remettre en attente',
                      onPressed: () => _remettreEnAttente(docId),
                      icon: Icons.refresh,
                      variant: ButtonVariant.secondary,
                      height: 40,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Nom du client depuis Firestore (users collection)
  // ════════════════════════════════════════════════════════════
  Widget _buildNomClient(String userId) {
    if (userId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final nom = userData?['name'] ??
            userData?['displayName'] ??
            userData?['email'] ??
            'Client inconnu';

        return Text(
          '👤 $nom',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Action : Valider une ordonnance
  // ════════════════════════════════════════════════════════════
  Future<void> _validerOrdonnance(String docId, String userId) async {
    final confirme = await _afficherDialogConfirmation(
      titre: '✅ Valider l\'ordonnance',
      message: 'Confirmer la validation de cette ordonnance ?',
      couleurBtn: _vert,
      labelBtn: 'Valider',
    );

    if (!confirme) return;

    LoadingOverlay.show(context, message: 'Validation en cours...');

    try {
      // Mettre à jour le statut
      await FirebaseFirestore.instance
          .collection('ordonnances')
          .doc(docId)
          .update({
        'status'     : 'validated',
        'validatedAt': FieldValue.serverTimestamp(),
        'motifRejet' : '',
      });

      // Envoyer une notification au client
      await _envoyerNotification(
        userId   : userId,
        titre    : '✅ Ordonnance validée',
        message  : 'Votre ordonnance a été validée. '
            'Vous pouvez récupérer vos médicaments.',
        type     : 'validated',
        docId    : docId,
      );

      if (mounted) {
        LoadingOverlay.hide(context);
        _showSnack('✅ Ordonnance validée avec succès', _vert);
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        _showSnack('Erreur : $e', _rouge);
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // Action : Rejeter une ordonnance (avec motif)
  // ════════════════════════════════════════════════════════════
  Future<void> _afficherDialogRejet(String docId, String userId) async {
    _motifController.clear();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '❌ Rejeter l\'ordonnance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indiquez le motif du rejet (optionnel) :',
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motifController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex : Ordonnance illisible, signature manquante...',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary(context), fontSize: 12),
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
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _rouge,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    LoadingOverlay.show(context, message: 'Rejet en cours...');

    try {
      await FirebaseFirestore.instance
          .collection('ordonnances')
          .doc(docId)
          .update({
        'status'     : 'rejected',
        'validatedAt': FieldValue.serverTimestamp(),
        'motifRejet' : _motifController.text.trim(),
      });

      await _envoyerNotification(
        userId : userId,
        titre  : '❌ Ordonnance rejetée',
        message: _motifController.text.trim().isNotEmpty
            ? 'Motif : ${_motifController.text.trim()}'
            : 'Votre ordonnance a été rejetée. '
            'Contactez votre pharmacien.',
        type   : 'rejected',
        docId  : docId,
      );

      if (mounted) {
        LoadingOverlay.hide(context);
        _showSnack('❌ Ordonnance rejetée', _rouge);
      }
    } catch (e) {
      if (mounted) {
        LoadingOverlay.hide(context);
        _showSnack('Erreur : $e', _rouge);
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // Action : Remettre en attente
  // ════════════════════════════════════════════════════════════
  Future<void> _remettreEnAttente(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ordonnances')
          .doc(docId)
          .update({
        'status'     : 'pending',
        'validatedAt': null,
        'motifRejet' : '',
      });
      if (mounted) {
        _showSnack('🔄 Remis en attente', _ambre);
      }
    } catch (e) {
      if (mounted) _showSnack('Erreur : $e', _rouge);
    }
  }

  // ════════════════════════════════════════════════════════════
  // Envoyer une notification dans Firestore (collection notifications)
  // ════════════════════════════════════════════════════════════
  Future<void> _envoyerNotification({
    required String userId,
    required String titre,
    required String message,
    required String type,
    required String docId,
  }) async {
    // Écriture dans la collection "notifications" du client
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId'       : userId,
      'titre'        : titre,
      'message'      : message,
      'type'         : type,
      'ordonnanceId' : docId,
      'lu'           : false,
      'createdAt'    : FieldValue.serverTimestamp(),
    });
  }

  // ════════════════════════════════════════════════════════════
  // Dialog de confirmation générique
  // ════════════════════════════════════════════════════════════
  Future<bool> _afficherDialogConfirmation({
    required String titre,
    required String message,
    required Color  couleurBtn,
    required String labelBtn,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(titre,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message,
            style: TextStyle(color: AppColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style:
                TextStyle(color: AppColors.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: couleurBtn,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(labelBtn,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ════════════════════════════════════════════════════════════
  // État vide
  // ════════════════════════════════════════════════════════════
  Widget _buildEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 72,
            color: AppColors.textSecondary(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _filtre == 'tous'
                ? 'Aucune ordonnance soumise'
                : 'Aucune ordonnance "${_labelFiltre()}"',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _sousTitre(String texte) {
    return Text(
      texte,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: AppColors.onSurface(context),
      ),
    );
  }

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

  String _labelFiltre() {
    switch (_filtre) {
      case 'validated': return 'Validée';
      case 'rejected':  return 'Rejetée';
      default:          return 'En attente';
    }
  }
}