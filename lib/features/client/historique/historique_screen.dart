import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════
// HistoriqueScreen — Historique des ordonnances du client
// Affiche toutes les ordonnances soumises par le client connecté
// avec leur statut (en attente / validée / rejetée)
// ═══════════════════════════════════════════════════════════════

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  // ── Couleurs ───────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color green       = Color(0xFF2E7D32);
  static const Color amber       = Color(0xFFF9A825);
  static const Color red         = Color(0xFFC62828);
  static const Color background  = Color(0xFFF5F7FA);

  // Filtre actuel
  String _filtre = 'tous';

  // UID du client connecté
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Mes Ordonnances',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Barre de filtres ─────────────────────────────
          _buildFiltreBar(),
          // ── Liste des ordonnances ────────────────────────
          Expanded(child: _buildListe()),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Barre de filtres
  // ════════════════════════════════════════════════════════════
  Widget _buildFiltreBar() {
    final filtres = [
      {'label': 'Toutes',     'valeur': 'tous',      'couleur': primaryBlue},
      {'label': 'En attente', 'valeur': 'pending',   'couleur': amber},
      {'label': 'Validées',   'valeur': 'validated', 'couleur': green},
      {'label': 'Rejetées',   'valeur': 'rejected',  'couleur': red},
    ];

    return Container(
      color: Colors.white,
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
                  color: estActif ? Colors.white : Colors.grey[700],
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
  // Liste temps réel depuis Firestore
  // ════════════════════════════════════════════════════════════
  Widget _buildListe() {
    // Construire la requête selon le filtre
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('ordonnances')
        .where('userId', isEqualTo: _uid) // seulement CE client
        .orderBy('createdAt', descending: true);

    if (_filtre != 'tous') {
      query = query.where('status', isEqualTo: _filtre);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // Chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: primaryBlue));
        }

        // Erreur
        if (snapshot.hasError) {
          return _buildEtatVide(
            icone: Icons.error_outline,
            message: 'Une erreur est survenue.',
            couleur: red,
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // Liste vide
        if (docs.isEmpty) {
          return _buildEtatVide(
            icone: Icons.description_outlined,
            message: _filtre == 'tous'
                ? 'Vous n\'avez pas encore soumis d\'ordonnance.'
                : 'Aucune ordonnance "${_labelFiltre()}".',
            couleur: Colors.grey,
          );
        }

        // Liste des cartes
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc  = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildCarte(doc.id, data);
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Carte d'une ordonnance
  // ════════════════════════════════════════════════════════════
  Widget _buildCarte(String docId, Map<String, dynamic> data) {
    final statut    = data['status'] ?? 'pending';
    final texte     = data['extractedText'] ?? 'Aucun texte';
    final medicines = data['medicines'] as List<dynamic>? ?? [];

    // Dates
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final validatedAt = data['validatedAt'] != null
        ? (data['validatedAt'] as Timestamp).toDate()
        : null;

    final dateCreation = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}  '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}'
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Bordure colorée selon le statut
        side: BorderSide(
          color: _couleurStatut(statut).withOpacity(0.3),
          width: 1.2,
        ),
      ),
      elevation: 2,
      child: Theme(
        // ExpansionTile sans ligne de séparation
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          // ── En-tête toujours visible ──────────────────
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _couleurStatut(statut).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconeStatut(statut),
              color: _couleurStatut(statut),
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Ordonnance du $dateCreation',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _badgeStatut(statut),
          ),
          // ── Contenu déplié ────────────────────────────
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),

                  // Médicaments détectés
                  if (medicines.isNotEmpty) ...[
                    _sousTitre('💊 Médicaments détectés'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: medicines
                          .map((m) => Chip(
                        label: Text(
                          m.toString().length > 25
                              ? '${m.toString().substring(0, 25)}...'
                              : m.toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                        primaryBlue.withOpacity(0.07),
                        side: BorderSide(
                            color: primaryBlue.withOpacity(0.2)),
                        visualDensity: VisualDensity.compact,
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Texte extrait
                  _sousTitre('📄 Texte extrait'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(10),
                      border:
                      Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      texte,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, height: 1.6),
                    ),
                  ),

                  // Date de validation si disponible
                  if (validatedAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 14,
                            color: _couleurStatut(statut)),
                        const SizedBox(width: 6),
                        Text(
                          'Traitée le : '
                              '${validatedAt.day.toString().padLeft(2, '0')}/'
                              '${validatedAt.month.toString().padLeft(2, '0')}/'
                              '${validatedAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _couleurStatut(statut),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Message selon statut
                  const SizedBox(height: 12),
                  _buildMessageStatut(statut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Message d'information selon le statut
  // ════════════════════════════════════════════════════════════
  Widget _buildMessageStatut(String statut) {
    String message;
    Color couleur;
    IconData icone;

    switch (statut) {
      case 'validated':
        message = 'Votre ordonnance a été validée. '
            'Vous pouvez récupérer vos médicaments.';
        couleur = green;
        icone   = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = 'Votre ordonnance a été rejetée. '
            'Contactez votre pharmacien pour plus d\'informations.';
        couleur = red;
        icone   = Icons.cancel_outlined;
        break;
      default:
        message = 'En attente de validation par le pharmacien.';
        couleur = amber;
        icone   = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: couleur,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // État vide (aucune ordonnance)
  // ════════════════════════════════════════════════════════════
  Widget _buildEtatVide({
    required IconData icone,
    required String message,
    required Color couleur,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 72, color: couleur.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _badgeStatut(String statut) {
    final couleur = _couleurStatut(statut);
    final label   = _labelStatut(statut);
    final icone   = _iconeStatut(statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: couleur),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: couleur,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'validated': return green;
      case 'rejected':  return red;
      default:          return amber;
    }
  }

  IconData _iconeStatut(String statut) {
    switch (statut) {
      case 'validated': return Icons.check_circle;
      case 'rejected':  return Icons.cancel;
      default:          return Icons.hourglass_empty;
    }
  }

  String _labelStatut(String statut) {
    switch (statut) {
      case 'validated': return 'Validée';
      case 'rejected':  return 'Rejetée';
      default:          return 'En attente';
    }
  }

  String _labelFiltre() {
    switch (_filtre) {
      case 'validated': return 'Validée';
      case 'rejected':  return 'Rejetée';
      default:          return 'En attente';
    }
  }

  Widget _sousTitre(String texte) {
    return Text(
      texte,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Color(0xFF37474F),
      ),
    );
  }
}