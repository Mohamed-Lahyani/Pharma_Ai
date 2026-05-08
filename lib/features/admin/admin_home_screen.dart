import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medications_screen.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/features/admin/ordonnances_admin_screen.dart';
import 'package:pharma_ai/features/admin/users_screen.dart';
import 'package:pharma_ai/features/admin/stock_alerts_screen.dart';


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
    final l10n = AppLocalizations.of(context)!;
    const Color couleurPrimaire = Color(0xFF1565C0);
    const Color couleurWarning  = Color(0xFFF9A825);
    const Color couleurDanger   = Color(0xFFC62828);
    const Color couleurSuccess  = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          l10n.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => Navigator.pushNamed(context, '/settings'),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.helloPharmacie,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
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
                l10n.statistics,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface(context),
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
                    titre  : l10n.medications,
                    valeur : totalMedications.toString(),
                    icone  : Icons.medication,
                    couleur: couleurPrimaire,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdonnancesAdminScreen(),
                      ),
                    ),
                    child: _buildStatCard(
                      titre  : l10n.pending,
                      valeur : pendingOrdonnances.toString(),
                      icone  : Icons.pending_actions,
                      couleur: couleurWarning,
                    ),
                  ),
                  _buildStatCard(
                    titre  : l10n.criticalStock,
                    valeur : lowStockMedications.toString(),
                    icone  : Icons.warning_amber,
                    couleur: couleurDanger,
                  ),
                  _buildStatCard(
                    titre  : l10n.clients,
                    valeur : totalClients.toString(),
                    icone  : Icons.people,
                    couleur: couleurSuccess,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                l10n.quickActions,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface(context),
                ),
              ),

              const SizedBox(height: 12),
              _buildActionButton(
                titre    : l10n.manageMedications,
                sousTitre: l10n.addMedication,
                icone    : Icons.medication_liquid,
                couleur  : couleurPrimaire,
                onTap    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicationsScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _buildActionButton(
                titre    : l10n.viewPrescriptions,
                sousTitre: '$pendingOrdonnances ${l10n.pending}',
                icone    : Icons.description,
                couleur  : couleurWarning,
                onTap    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrdonnancesAdminScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _buildActionButton(
                titre    : l10n.stockAlerts,
                sousTitre: '$lowStockMedications ${l10n.criticalStock}',
                icone    : Icons.inventory,
                couleur  : couleurDanger,
                // TODO : brancher StockAlertsScreen
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockAlertsScreen()),
                ),
              ),
              _buildActionButton(
                titre    : l10n.clients,
                sousTitre: '$totalClients clients inscrits',
                icone    : Icons.people,
                couleur  : couleurSuccess,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStatCard({
    required String   titre,
    required String   valeur,
    required IconData icone,
    required Color    couleur,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              color: couleur.withValues(alpha: 0.1),
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
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: couleur.withValues(alpha: 0.1),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.onSurface(context),
                    ),
                  ),
                  Text(
                    sousTitre,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }
}