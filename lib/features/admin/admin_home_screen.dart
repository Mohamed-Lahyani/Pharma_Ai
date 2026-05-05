import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medications_screen.dart';

// ── AJOUT : traductions ───────────────────────────────────────
import 'package:pharma_ai/core/l10n/app_localizations.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int totalMedications    = 0;
  int pendingOrdonnances  = 0;
  int lowStockMedications = 0;
  int totalClients        = 0;
  bool _isLoading         = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final meds = await FirebaseFirestore.instance
          .collection('medications').get();

      final pending = await FirebaseFirestore.instance
          .collection('ordonnances')
          .where('status', isEqualTo: 'pending').get();

      final lowStock = await FirebaseFirestore.instance
          .collection('medications')
          .where('stock', isLessThan: 5).get();

      final clients = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'client').get();

      setState(() {
        totalMedications    = meds.docs.length;
        pendingOrdonnances  = pending.docs.length;
        lowStockMedications = lowStock.docs.length;
        totalClients        = clients.docs.length;
        _isLoading          = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── AJOUT : récupérer les traductions ─────────────────────
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // ✅ Traduit
        title: Text(
          l10n.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            // ✅ Traduit
            tooltip: l10n.settings,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            // ✅ Traduit
            tooltip: l10n.signOut,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Bannière de bienvenue ───────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // ✅ Traduit
                      l10n.helloPharmacie,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // ✅ Traduit
                      l10n.statistics,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                // ✅ Traduit
                l10n.statistics,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    // ✅ Traduit
                    titre : l10n.medications,
                    valeur: totalMedications.toString(),
                    icone : Icons.medication,
                    couleur: const Color(0xFF1565C0),
                  ),
                  _buildStatCard(
                    // ✅ Traduit
                    titre : l10n.pending,
                    valeur: pendingOrdonnances.toString(),
                    icone : Icons.pending_actions,
                    couleur: const Color(0xFFF9A825),
                  ),
                  _buildStatCard(
                    // ✅ Traduit
                    titre : l10n.criticalStock,
                    valeur: lowStockMedications.toString(),
                    icone : Icons.warning_amber,
                    couleur: const Color(0xFFC62828),
                  ),
                  _buildStatCard(
                    // ✅ Traduit
                    titre : l10n.clients,
                    valeur: totalClients.toString(),
                    icone : Icons.people,
                    couleur: const Color(0xFF2E7D32),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                // ✅ Traduit
                l10n.quickActions,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _buildActionButton(
                // ✅ Traduit
                titre    : l10n.manageMedications,
                sousTitre: l10n.addMedication,
                icone    : Icons.medication_liquid,
                couleur  : const Color(0xFF1565C0),
                onTap    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MedicationsScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                // ✅ Traduit
                titre    : l10n.viewPrescriptions,
                sousTitre: l10n.pending,
                icone    : Icons.description,
                couleur  : const Color(0xFFF9A825),
                onTap    : () {},
              ),
              const SizedBox(height: 10),
              _buildActionButton(
                // ✅ Traduit
                titre    : l10n.stockAlerts,
                sousTitre: l10n.criticalStock,
                icone    : Icons.inventory,
                couleur  : const Color(0xFFC62828),
                onTap    : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carte statistique ─────────────────────────────────────────
  Widget _buildStatCard({
    required String   titre,
    required String   valeur,
    required IconData icone,
    required Color    couleur,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: couleur, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valeur,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: couleur,
                ),
              ),
              Text(
                titre,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bouton action rapide ──────────────────────────────────────
  Widget _buildActionButton({
    required String       titre,
    required String       sousTitre,
    required IconData     icone,
    required Color        couleur,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: couleur, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sousTitre,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}