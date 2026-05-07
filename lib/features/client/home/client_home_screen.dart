import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/features/client/ocr/ocr_scanner_screen.dart';
import 'package:pharma_ai/features/client/historique/historique_screen.dart';
import 'package:pharma_ai/features/client/reminders/reminder_screen.dart';
import 'package:pharma_ai/features/client/profile/profile_screen.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/features/client/barcode/barcode_scanner_screen.dart';
import 'package:pharma_ai/features/client/medications/medications_client_screen.dart';
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // ✅ Couleurs sémantiques conservées (statut métier — non adaptatives)
  static const Color _couleurVert    = Color(0xFF2E7D32);
  static const Color _couleurAmbre   = Color(0xFFF9A825);
  static const Color _couleurRouge   = Color(0xFFC62828);
  static const Color _couleurViolet  = Color(0xFF6A1B9A);
  static const Color _couleurSarcelle= Color(0xFF00838F);

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
    final l10n = AppLocalizations.of(context)!;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.signOut),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _couleurRouge),
            onPressed: () => Navigator.pop(ctx, true),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ Fond adaptatif
      backgroundColor: AppColors.background(context),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          // ✅ Couleur primaire adaptative
          color: Theme.of(context).colorScheme.primary,
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadUserData,
        // ✅ Couleur primaire adaptative
        color: Theme.of(context).colorScheme.primary,
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
                      l10n.myPrescriptions,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        // ✅ Texte principal adaptatif
                        color: AppColors.onSurface(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.scanPrescription,
                      style: TextStyle(
                          fontSize: 13,
                          // ✅ Texte secondaire adaptatif
                          color: AppColors.textSecondary(context)),
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
  // ✅ Le dégradé de la SliverAppBar est intentionnellement conservé
  // en couleurs fixes : c'est un élément de branding (hero visuel),
  // pas un fond de contenu. Il reste bleu en mode sombre.
  Widget _buildSliverAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      // ✅ Couleur pincée adaptative
      backgroundColor: Theme.of(context).colorScheme.primary,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          tooltip: l10n.settings,
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white),
          tooltip: l10n.myReminders,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ReminderScreen(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            // ✅ Dégradé branding conservé intentionnellement
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
                          // ✅ .withValues() remplace .withOpacity()
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
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
                              _salutation(l10n),
                              style: TextStyle(
                                // ✅ .withValues() remplace .withOpacity()
                                color: Colors.white.withValues(alpha: 0.85),
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
                          // ✅ .withValues() remplace .withOpacity()
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
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
          label  : l10n.pending,
          icone  : Icons.hourglass_empty_rounded,
          couleur: _couleurAmbre,
        ),
        const SizedBox(width: 10),
        _buildStatMini(
          valeur : _ordonnancesValidees.toString(),
          label  : l10n.validated,
          icone  : Icons.check_circle_outline,
          couleur: _couleurVert,
        ),
        const SizedBox(width: 10),
        _buildStatMini(
          valeur : _rappelsActifs.toString(),
          label  : l10n.reminders,
          icone  : Icons.alarm_on_outlined,
          // ✅ Couleur primaire adaptative passée en paramètre
          couleur: Theme.of(context).colorScheme.primary,
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
          // ✅ Fond carte adaptatif
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              // ✅ .withValues() remplace .withOpacity()
              color: couleur.withValues(alpha: 0.08),
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
                // ✅ .withValues() remplace .withOpacity()
                color: couleur.withValues(alpha: 0.1),
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
              style: TextStyle(
                  fontSize: 11,
                  // ✅ Texte secondaire adaptatif
                  color: AppColors.textSecondary(context)),
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
        titre      : l10n.scanPrescription,
        icone      : Icons.document_scanner_outlined,
        // ✅ Couleur primaire adaptative
        couleur    : Theme.of(context).colorScheme.primary,
        description: l10n.takePhoto,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OcrScannerScreen())),
      ),
      _ActionItem(
        titre      : l10n.scanBarcode,
        icone      : Icons.qr_code_scanner,
        couleur    : _couleurViolet,
        description: l10n.scanBarcode,
        onTap   : () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const BarcodeScannerScreen())),
      ),
      _ActionItem(
        titre      : l10n.myPrescriptions,
        icone      : Icons.description_outlined,
        couleur    : _couleurVert,
        description: l10n.all,
        badge      : _ordonnancesEnAttente > 0
            ? _ordonnancesEnAttente.toString()
            : null,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const HistoriqueScreen())),
      ),
      _ActionItem(
        titre      : l10n.myReminders,
        icone      : Icons.alarm_outlined,
        couleur    : _couleurAmbre,
        description: l10n.reminders,
        badge      : _rappelsActifs > 0 ? _rappelsActifs.toString() : null,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ReminderScreen())),
      ),
      _ActionItem(
        titre      : l10n.medications,
        icone      : Icons.medication_outlined,
        couleur    : _couleurSarcelle,
        description: l10n.searchMedication,
        onTap      : () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicationsClientScreen()),
        ),
      ),
      _ActionItem(
        titre      : l10n.myProfile,
        icone      : Icons.person_outline,
        couleur    : _couleurRouge,
        description: l10n.personalInfo,
        onTap      : () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount  : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing : 12,
        childAspectRatio: 1.15,
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
          // ✅ Fond carte adaptatif
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ✅ .withValues() remplace .withOpacity()
              color : action.couleur.withValues(alpha: 0.10),
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
                    // ✅ .withValues() remplace .withOpacity()
                    color: action.couleur.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icone,
                      color: action.couleur, size: 24),
                ),
                const Spacer(),
                Text(
                  action.titre,
                  style: TextStyle(
                    fontSize  : 14,
                    fontWeight: FontWeight.bold,
                    // ✅ Texte principal adaptatif
                    color     : AppColors.onSurface(context),
                    height    : 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.description,
                  style: TextStyle(
                      fontSize: 11,
                      // ✅ Texte secondaire adaptatif
                      color: AppColors.textSecondary(context)),
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
                    // ✅ Rouge sémantique conservé (badge d'alerte)
                    color: _couleurRouge,
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
            // ✅ .withValues() remplace .withOpacity()
            _couleurVert.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _couleurVert.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ✅ .withValues() remplace .withOpacity()
              color: _couleurVert.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline,
                color: _couleurVert, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.howItWorks,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize  : 14,
                    // ✅ Texte principal adaptatif
                    color     : AppColors.onSurface(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.scanPrescription,
                  style: TextStyle(
                    fontSize: 12,
                    // ✅ Texte secondaire adaptatif
                    color   : AppColors.textSecondary(context),
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
        // ✅ Couleur primaire adaptative
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior       : SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Modèle de donnée pour une action de la grille ─────────────
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