import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';

class MedicationsClientScreen extends StatefulWidget {
  const MedicationsClientScreen({super.key});

  @override
  State<MedicationsClientScreen> createState() =>
      _MedicationsClientScreenState();
}

class _MedicationsClientScreenState extends State<MedicationsClientScreen> {
  static const Color _couleurPrimaire = Color(0xFF1565C0);
  static const Color _couleurWarning  = Color(0xFFF9A825);
  static const Color _couleurDanger   = Color(0xFFC62828);
  static const Color _couleurSuccess  = Color(0xFF2E7D32);

  final TextEditingController _searchController = TextEditingController();
  String  _searchQuery    = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetail(Map<String, dynamic> data) {
    final int    stock      = data['stock'] ?? 0;
    final bool   isCritical = stock <= 5;
    final bool   isOutOf    = stock == 0;
    String expiryText = 'N/A';
    if (data['expiryDate'] != null) {
      try {
        final ts = data['expiryDate'] as Timestamp;
        expiryText = DateFormat('dd/MM/yyyy').format(ts.toDate());
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _couleurPrimaire.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medication,
                      color: _couleurPrimaire, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Inconnu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface(context),
                        ),
                      ),
                      Text(
                        data['category'] ?? 'Non défini',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOutOf
                        ? _couleurDanger.withValues(alpha: 0.12)
                        : isCritical
                        ? _couleurWarning.withValues(alpha: 0.12)
                        : _couleurSuccess.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOutOf
                        ? 'Rupture'
                        : isCritical
                        ? 'Stock bas'
                        : 'Disponible',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOutOf
                          ? _couleurDanger
                          : isCritical
                          ? _couleurWarning
                          : _couleurSuccess,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Divider(color: AppColors.border(context)),
            const SizedBox(height: 16),

            _detailRow(Icons.monetization_on_outlined,
                'Prix', '${data['price'] ?? 0} DZD'),
            _detailRow(Icons.inventory_2_outlined,
                'Stock', '$stock unité(s)'),
            _detailRow(Icons.event_outlined,
                'Expiration', expiryText),
            if ((data['description'] ?? '').toString().isNotEmpty)
              _detailRow(Icons.info_outline,
                  'Description', data['description']),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _couleurPrimaire,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary(context)),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          l10n.medications,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchMedication,
                prefixIcon: Icon(Icons.search, color: primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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
                  borderSide:
                  BorderSide(color: AppColors.border(context)),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medications')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: primary));
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erreur : ${snapshot.error}'));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final cat  = (data['category'] ?? '').toString();
                  final matchSearch = name.contains(_searchQuery);
                  final matchCat = _selectedCategory == null ||
                      cat == _selectedCategory;
                  return matchSearch && matchCat;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64,
                            color: AppColors.textSecondary(context)),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun médicament trouvé',
                          style: TextStyle(
                              color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc  = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final int  stock      = data['stock'] ?? 0;
                    final bool isCritical = stock > 0 && stock <= 5;
                    final bool isOutOf    = stock == 0;

                    String expiryText = 'N/A';
                    if (data['expiryDate'] != null) {
                      try {
                        final ts = data['expiryDate'] as Timestamp;
                        expiryText =
                            DateFormat('dd/MM/yyyy').format(ts.toDate());
                      } catch (_) {}
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: AppColors.surface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isOutOf
                            ? const BorderSide(
                            color: _couleurDanger, width: 1.2)
                            : isCritical
                            ? const BorderSide(
                            color: _couleurWarning, width: 1.2)
                            : BorderSide.none,
                      ),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showDetail(data),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  color: isOutOf
                                      ? _couleurDanger
                                      .withValues(alpha: 0.1)
                                      : isCritical
                                      ? _couleurWarning
                                      .withValues(alpha: 0.1)
                                      : _couleurPrimaire
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.medication,
                                  color: isOutOf
                                      ? _couleurDanger
                                      : isCritical
                                      ? _couleurWarning
                                      : _couleurPrimaire,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? 'Inconnu',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.onSurface(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      data['category'] ?? 'Non défini',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                        AppColors.textSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Exp : $expiryText',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                        AppColors.textSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${data['price'] ?? 0} DZD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isOutOf
                                          ? _couleurDanger
                                          .withValues(alpha: 0.12)
                                          : isCritical
                                          ? _couleurWarning
                                          .withValues(alpha: 0.12)
                                          : _couleurSuccess
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isOutOf
                                          ? 'Rupture'
                                          : '$stock unités',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isOutOf
                                            ? _couleurDanger
                                            : isCritical
                                            ? _couleurWarning
                                            : _couleurSuccess,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right,
                                  color: AppColors.textSecondary(context),
                                  size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
