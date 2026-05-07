import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';


class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  static const Color _couleurVert  = Color(0xFF2E7D32);
  static const Color _couleurAmbre = Color(0xFFF9A825);
  static const Color _couleurRouge = Color(0xFFC62828);

  String _filtre = 'tous';

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'Mes Ordonnances',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFiltreBar(),
          Expanded(child: _buildListe()),
        ],
      ),
    );
  }

  Widget _buildFiltreBar() {
    final filtres = [
      {
        'label'  : 'Toutes',
        'valeur' : 'tous',
        'couleur': Theme.of(context).colorScheme.primary,
      },
      {'label': 'En attente', 'valeur': 'pending',   'couleur': _couleurAmbre},
      {'label': 'Validées',   'valeur': 'validated', 'couleur': _couleurVert},
      {'label': 'Rejetées',   'valeur': 'rejected',  'couleur': _couleurRouge},
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

  Widget _buildListe() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('ordonnances')
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true);

    if (_filtre != 'tous') {
      query = query.where('status', isEqualTo: _filtre);
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
          return _buildEtatVide(
            icone   : Icons.error_outline,
            message : 'Une erreur est survenue.',
            couleur : _couleurRouge,
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEtatVide(
            icone  : Icons.description_outlined,
            message: _filtre == 'tous'
                ? 'Vous n\'avez pas encore soumis d\'ordonnance.'
                : 'Aucune ordonnance "${_labelFiltre()}".',
            couleur: AppColors.textSecondary(context),
          );
        }

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

  Widget _buildCarte(String docId, Map<String, dynamic> data) {
    final statut    = data['status'] ?? 'pending';
    final texte     = data['extractedText'] ?? 'Aucun texte';
    final medicines = data['medicines'] as List<dynamic>? ?? [];

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

    final couleurStatut = _couleurStatut(statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: couleurStatut.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: couleurStatut.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconeStatut(statut),
              color: couleurStatut,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Ordonnance du $dateCreation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.onSurface(context),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _badgeStatut(statut),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: AppColors.border(context),
                  ),

                  if (medicines.isNotEmpty) ...[
                    _sousTitre(context, ' Médicaments détectés'),
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
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.07),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                        ),
                        visualDensity: VisualDensity.compact,
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _sousTitre(context, ' Texte extrait'),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.border(context)),
                    ),
                    child: Text(
                      texte,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.onSurface(context),
                      ),
                    ),
                  ),

                  if (validatedAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: couleurStatut),
                        const SizedBox(width: 6),
                        Text(
                          'Traitée le : '
                              '${validatedAt.day.toString().padLeft(2, '0')}/'
                              '${validatedAt.month.toString().padLeft(2, '0')}/'
                              '${validatedAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: couleurStatut,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],

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

  Widget _buildMessageStatut(String statut) {
    String   message;
    Color    couleur;
    IconData icone;

    switch (statut) {
      case 'validated':
        message = 'Votre ordonnance a été validée. '
            'Vous pouvez récupérer vos médicaments.';
        couleur = _couleurVert;
        icone   = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = 'Votre ordonnance a été rejetée. '
            'Contactez votre pharmacien pour plus d\'informations.';
        couleur = _couleurRouge;
        icone   = Icons.cancel_outlined;
        break;
      default:
        message = 'En attente de validation par le pharmacien.';
        couleur = _couleurAmbre;
        icone   = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
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

  Widget _buildEtatVide({
    required IconData icone,
    required String   message,
    required Color    couleur,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 72,
              color: couleur.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 15),
          ),
        ],
      ),
    );
  }


  Widget _badgeStatut(String statut) {
    final couleur = _couleurStatut(statut);
    final label   = _labelStatut(statut);
    final icone   = _iconeStatut(statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
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
      case 'validated': return _couleurVert;
      case 'rejected':  return _couleurRouge;
      default:          return _couleurAmbre;
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

  Widget _sousTitre(BuildContext context, String texte) {
    return Text(
      texte,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: AppColors.onSurface(context),
      ),
    );
  }
}