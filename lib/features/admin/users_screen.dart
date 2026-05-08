import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/shared/widgets/custom_card.dart';
import 'package:pharma_ai/shared/widgets/status_badge.dart';


class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const Color _vert  = Color(0xFF2E7D32);
  static const Color _ambre = Color(0xFFF9A825);
  static const Color _rouge = Color(0xFFC62828);

  final TextEditingController _searchController = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'Clients',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          _buildCompteurClients(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildBarreRecherche(),
          Expanded(child: _buildListeClients()),
        ],
      ),
    );
  }

  Widget _buildCompteurClients() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'client')
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
            '$count clients',
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

  Widget _buildBarreRecherche() {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _recherche = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Rechercher un client...',
          hintStyle: TextStyle(color: AppColors.textSecondary(context)),
          prefixIcon: Icon(Icons.search, color: primary),
          suffixIcon: _recherche.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear,
                color: AppColors.textSecondary(context)),
            onPressed: () {
              _searchController.clear();
              setState(() => _recherche = '');
            },
          )
              : null,
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
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
  Widget _buildListeClients() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'client')
          .snapshots(),
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
            child: Text(
              'Erreur : ${snapshot.error}',
              style: TextStyle(color: AppColors.textSecondary(context)),
            ),
          );
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          if (_recherche.isEmpty) return true;
          final data = doc.data() as Map<String, dynamic>;
          final nom   = (data['name'] ?? data['displayName'] ?? '').toLowerCase();
          final email = (data['email'] ?? '').toLowerCase();
          return nom.contains(_recherche) || email.contains(_recherche);
        }).toList();

        if (docs.isEmpty) {
          return _buildEtatVide();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc  = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildCarteClient(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildCarteClient(String userId, Map<String, dynamic> data) {
    final nom    = data['name'] ?? data['displayName'] ?? 'Client';
    final email  = data['email'] ?? '';
    final initiale = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final primary  = Theme.of(context).colorScheme.primary;

    return CustomCard(
      onTap: () => _ouvrirDetailClient(userId, nom, email),
      variant: CardVariant.standard,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initiale,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

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
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge.role('client', small: true),
                    const SizedBox(width: 8),
                    _buildCompteurOrdonnances(userId),
                  ],
                ),
              ],
            ),
          ),

          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textSecondary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCompteurOrdonnances(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('ordonnances')
          .where('userId', isEqualTo: userId)
          .get(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Text(
          '$count ordonnance${count > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary(context),
          ),
        );
      },
    );
  }

  void _ouvrirDetailClient(String userId, String nom, String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailClientSheet(
        userId : userId,
        nom    : nom,
        email  : email,
      ),
    );
  }

  Widget _buildEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _recherche.isNotEmpty ? Icons.search_off : Icons.people_outline,
            size: 72,
            color: AppColors.textSecondary(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _recherche.isNotEmpty
                ? 'Aucun client trouvé pour "$_recherche"'
                : 'Aucun client inscrit',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailClientSheet extends StatelessWidget {
  final String userId;
  final String nom;
  final String email;

  static const Color _vert  = Color(0xFF2E7D32);
  static const Color _ambre = Color(0xFFF9A825);
  static const Color _rouge = Color(0xFFC62828);

  const _DetailClientSheet({
    required this.userId,
    required this.nom,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final primary   = Theme.of(context).colorScheme.primary;
    final initiale  = nom.isNotEmpty ? nom[0].toUpperCase() : '?';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize    : 0.95,
      minChildSize    : 0.4,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initiale,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nom,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface(context),
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge.role('client'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.border(context), height: 1),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.history, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Historique des ordonnances',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.onSurface(context),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ordonnances')
                    .where('userId', isEqualTo: userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 52,
                            color: AppColors.textSecondary(context)
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune ordonnance soumise',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                      docs[index].data() as Map<String, dynamic>;
                      return _buildLigneOrdonnance(context, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLigneOrdonnance(
      BuildContext context, Map<String, dynamic> data) {
    final statut    = data['status'] ?? 'pending';
    final medicines = data['medicines'] as List<dynamic>? ?? [];
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

    final dateStr = createdAt != null
        ? '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year}'
        : '—';

    final couleur = statut == 'validated'
        ? _vert
        : statut == 'rejected'
        ? _rouge
        : _ambre;

    return CustomCard(
      variant    : CardVariant.outlined,
      accentColor: couleur,
      padding    : const EdgeInsets.all(14),
      child      : Row(
        children: [
          // Icône statut
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statut == 'validated'
                  ? Icons.check_circle
                  : statut == 'rejected'
                  ? Icons.cancel
                  : Icons.hourglass_empty,
              color: couleur,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.onSurface(context),
                  ),
                ),
                if (medicines.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    medicines.take(2).join(', ') +
                        (medicines.length > 2
                            ? ' +${medicines.length - 2}'
                            : ''),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          StatusBadge.ordonnance(statut, small: true),
        ],
      ),
    );
  }
}