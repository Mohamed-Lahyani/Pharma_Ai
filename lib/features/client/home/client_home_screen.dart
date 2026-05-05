import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/features/client/ocr/ocr_scanner_screen.dart';
import 'package:pharma_ai/features/client/historique/historique_screen.dart';
import 'package:pharma_ai/features/client/reminders/reminder_screen.dart';
import 'package:pharma_ai/features/client/profile/profile_screen.dart';

// ── AJOUT : traductions ───────────────────────────────────────
import 'package:pharma_ai/core/l10n/app_localizations.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color green       = Color(0xFF2E7D32);
  static const Color amber       = Color(0xFFF9A825);
  static const Color red         = Color(0xFFC62828);
  static const Color background  = Color(0xFFF5F7FA);

  String _userName  = 'Utilisateur';
  String _userEmail = '';
  bool   _isLoading = true;

  int _ordonnancesEnAttente = 0;
  int _ordonnancesValidees  = 0;
  int _rappelsActifs        = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();

      final enAttente = await FirebaseFirestore.instance
          .collection('ordonnances')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final validees = await FirebaseFirestore.instance
          .collection('ordonnances')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'validated')
          .get();

      final rappels = await FirebaseFirestore.instance
          .collection('reminders')
          .where('userId', isEqualTo: uid)
          .where('active', isEqualTo: true)
          .get();

      if (!mounted) return;
      setState(() {
        if (userDoc.exists) {
          final data = userDoc.data()!;
          final fullName = data['name'] ?? 'Utilisateur';
          _userName  = fullName.toString().split(' ').first;
          _userEmail = data['email'] ?? '';
        }
        _ordonnancesEnAttente = enAttente.docs.length;
        _ordonnancesValidees  = validees.docs.length;
        _rappelsActifs        = rappels.docs.length;
        _isLoading            = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    // ── On récupère l10n ici car showDialog a son propre context
    final l10n = AppLocalizations.of(context)!;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        // ✅ Traduit
        title: Text(l10n.signOut),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            // ✅ Traduit
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(ctx, true),
            // ✅ Traduit
            child: Text(l10n.signOut,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── AJOUT : récupérer les traductions ─────────────────────
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: background,
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
        onRefresh: _loadUserData,
        color: primaryBlue,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(l10n),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(l10n),
                    const SizedBox(height: 28),
                    Text(
                      // ✅ Traduit
                      l10n.myPrescriptions,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // ✅ Traduit
                      l10n.scanPrescription,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    _buildActionsGrid(l10n),
                    const SizedBox(height: 28),
                    _buildInfoBanner(l10n),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar avec dégradé ───────────────────────────────────────
  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: primaryBlue,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          // ✅ Traduit
          tooltip: l10n.settings,
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                // ✅ Traduit
                content: Text(l10n.notifications),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1565C0),
                Color(0xFF1E88E5),
                Color(0xFF0D47A1),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Avatar initiales
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty
                                ? _userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
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
                              // ✅ Traduit selon l'heure
                              _salutation(l10n),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge PharmaAI
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_pharmacy,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              l10n.appName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Ligne de 3 stats ──────────────────────────────────────────
  Widget _buildStatsRow(AppLocalizations l10n) {
    return Row(
      children: [
        _buildStatMini(
          valeur : _ordonnancesEnAttente.toString(),
          // ✅ Traduit
          label  : l10n.pending,
          icone  : Icons.hourglass_empty_rounded,
          couleur: amber,
        ),
        const SizedBox(width: 10),
        _buildStatMini(
          valeur : _ordonnancesValidees.toString(),
          // ✅ Traduit
          label  : l10n.validated,
          icone  : Icons.check_circle_outline,
          couleur: green,
        ),
        const SizedBox(width: 10),
        _buildStatMini(
          valeur : _rappelsActifs.toString(),
          // ✅ Traduit
          label  : l10n.reminders,
          icone  : Icons.alarm_on_outlined,
          couleur: primaryBlue,
        ),
      ],
    );
  }

  Widget _buildStatMini({
    required String   valeur,
    required String   label,
    required IconData icone,
    required Color    couleur,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: couleur.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: couleur, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Grille 2×3 des actions ────────────────────────────────────
  Widget _buildActionsGrid(AppLocalizations l10n) {
    final actions = [
      _ActionItem(
        // ✅ Traduit
        titre      : l10n.scanPrescription,
        icone      : Icons.document_scanner_outlined,
        couleur    : primaryBlue,
        // ✅ Traduit
        description: l10n.takePhoto,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OcrScannerScreen())),
      ),
      _ActionItem(
        // ✅ Traduit
        titre      : l10n.scanBarcode,
        icone      : Icons.qr_code_scanner,
        couleur    : const Color(0xFF6A1B9A),
        description: l10n.scanBarcode,
        onTap      : () => _showComingSoon(l10n.scanBarcode),
      ),
      _ActionItem(
        // ✅ Traduit
        titre      : l10n.myPrescriptions,
        icone      : Icons.description_outlined,
        couleur    : green,
        // ✅ Traduit
        description: l10n.all,
        badge      : _ordonnancesEnAttente > 0
            ? _ordonnancesEnAttente.toString()
            : null,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HistoriqueScreen())),
      ),
      _ActionItem(
        // ✅ Traduit
        titre      : l10n.myReminders,
        icone      : Icons.alarm_outlined,
        couleur    : amber,
        // ✅ Traduit
        description: l10n.reminders,
        badge      : _rappelsActifs > 0 ? _rappelsActifs.toString() : null,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ReminderScreen())),
      ),
      _ActionItem(
        // ✅ Traduit
        titre      : l10n.medications,
        icone      : Icons.medication_outlined,
        couleur    : const Color(0xFF00838F),
        description: l10n.searchMedication,
        onTap      : () => _showComingSoon(l10n.medications),
      ),
      _ActionItem(
        // ✅ Traduit
        titre      : l10n.myProfile,
        icone      : Icons.person_outline,
        couleur    : red,
        // ✅ Traduit
        description: l10n.personalInfo,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount   : 2,
        crossAxisSpacing : 12,
        mainAxisSpacing  : 12,
        childAspectRatio : 1.15,
      ),
      itemCount  : actions.length,
      itemBuilder: (context, index) => _buildActionCard(actions[index]),
    );
  }

  Widget _buildActionCard(_ActionItem action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color : action.couleur.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action.couleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icone, color: action.couleur, size: 24),
                ),
                const Spacer(),
                Text(
                  action.titre,
                  style: const TextStyle(
                    fontSize    : 14,
                    fontWeight  : FontWeight.bold,
                    color       : Color(0xFF1A1A2E),
                    height      : 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
            if (action.badge != null)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    action.badge!,
                    style: const TextStyle(
                      color     : Colors.white,
                      fontSize  : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Bannière "Comment ça marche" ──────────────────────────────
  Widget _buildInfoBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            green.withOpacity(0.08),
            primaryBlue.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // ✅ Traduit
                  l10n.howItWorks,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize  : 14,
                    color     : Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // ✅ Traduit
                  l10n.scanPrescription,
                  style: const TextStyle(
                    fontSize: 12,
                    color   : Colors.grey,
                    height  : 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Salutation selon l'heure ──────────────────────────────────
  String _salutation(AppLocalizations l10n) {
    final heure = DateTime.now().hour;
    if (heure < 12) return l10n.goodMorning;
    if (heure < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.construction, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$feature — bientôt disponible'),
          ],
        ),
        backgroundColor: primaryBlue,
        behavior       : SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ActionItem {
  final String       titre;
  final IconData     icone;
  final Color        couleur;
  final String       description;
  final String?      badge;
  final VoidCallback onTap;

  _ActionItem({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.description,
    this.badge,
    required this.onTap,
  });
}