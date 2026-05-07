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

class _P {

  static const lBg      = Color(0xFFF0FAF4);
  static const lCard    = Color(0xFFFAFEFC);
  static const lBorder  = Color(0xFFD1EEE0);
  static const lMute    = Color(0xFF9DB8AC);


  static const dBg      = Color(0xFF0D1912);
  static const dCard    = Color(0xFF162318);
  static const dBorder  = Color(0xFF1F3527);
  static const dMute    = Color(0xFF4D7060);


  static const green    = Color(0xFF16A34A);
  static const greenPastel = Color(0xFFBBF7D0);
  static const greenPastelDark = Color(0xFF14532D);
  static const amber    = Color(0xFFF59E0B);
  static const violet   = Color(0xFF8B5CF6);
  static const red      = Color(0xFFDC2626);
}

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _userName  = 'Utilisateur';
  String _userEmail = '';
  bool   _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      if (_uid.isEmpty) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      if (!mounted) return;
      setState(() {
        if (doc.exists) {
          final d    = doc.data()!;
          final full = d['name'] ?? 'Utilisateur';
          _userName  = full.toString().split(' ').first;
          _userEmail = d['email'] ?? '';
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.signOut),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _P.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.signOut, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _P.dBg : _P.lBg,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
          color: _P.green, strokeWidth: 2))
          : RefreshIndicator(
        onRefresh: _loadUserName,
        color: _P.green,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(l10n, isDark),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsRow(l10n, isDark),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: l10n.myPrescriptions,
                    subtitle: l10n.scanPrescription,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _buildActionsGrid(l10n, isDark),
                  const SizedBox(height: 24),
                  _buildInfoBanner(l10n, isDark),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAppBar(AppLocalizations l10n, bool isDark) {
    final cardBg = isDark ? _P.dCard : _P.lCard;

    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: _P.green.withOpacity(0.08),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined,
              size: 20, color: isDark ? _P.dMute : _P.lMute),
          tooltip: l10n.settings,
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: cardBg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar pastel
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: isDark
                              ? _P.greenPastelDark
                              : _P.greenPastel,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: isDark ? _P.greenPastel : _P.green,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
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
                                color: isDark ? _P.dMute : _P.lMute,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _userName,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1A2E22),
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge app
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? _P.greenPastelDark : _P.greenPastel,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_pharmacy_outlined,
                                color: isDark ? _P.greenPastel : _P.green, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              l10n.appName,
                              style: TextStyle(
                                color: isDark ? _P.greenPastel : _P.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildStatsRow(AppLocalizations l10n, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ordonnances')
                .where('userId', isEqualTo: _uid)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (ctx, snap) => _StatCard(
              value: (snap.data?.docs.length ?? 0).toString(),
              label: l10n.pending,
              icon: Icons.hourglass_empty_rounded,
              accent: _P.amber,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ordonnances')
                .where('userId', isEqualTo: _uid)
                .where('status', isEqualTo: 'validated')
                .snapshots(),
            builder: (ctx, snap) => _StatCard(
              value: (snap.data?.docs.length ?? 0).toString(),
              label: l10n.validated,
              icon: Icons.check_circle_outline_rounded,
              accent: _P.green,
              isDark: isDark,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reminders')
                .where('userId', isEqualTo: _uid)
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (ctx, snap) => _StatCard(
              value: (snap.data?.docs.length ?? 0).toString(),
              label: l10n.reminders,
              icon: Icons.alarm_on_outlined,
              accent: _P.violet,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsGrid(AppLocalizations l10n, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ordonnances')
          .where('userId', isEqualTo: _uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (ctx, snapOrd) {
        final ordEnAttente = snapOrd.data?.docs.length ?? 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reminders')
              .where('userId', isEqualTo: _uid)
              .where('active', isEqualTo: true)
              .snapshots(),
          builder: (ctx, snapRap) {
            final rappelsActifs = snapRap.data?.docs.length ?? 0;
            final mute = isDark ? _P.dMute : _P.lMute;

            final actions = [
              _ActionItem(
                titre: l10n.scanPrescription,
                icone: Icons.document_scanner_outlined,
                couleur: _P.green,          // seul item avec accent vert franc
                description: l10n.takePhoto,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OcrScannerScreen())),
              ),
              _ActionItem(
                titre: l10n.scanBarcode,
                icone: Icons.qr_code_scanner_outlined,
                couleur: mute,
                description: l10n.scanBarcode,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BarcodeScannerScreen())),
              ),
              _ActionItem(
                titre: l10n.myPrescriptions,
                icone: Icons.description_outlined,
                couleur: mute,
                description: l10n.all,
                badge: ordEnAttente > 0 ? ordEnAttente.toString() : null,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoriqueScreen())),
              ),
              _ActionItem(
                titre: l10n.myReminders,
                icone: Icons.alarm_outlined,
                couleur: mute,
                description: l10n.reminders,
                badge: rappelsActifs > 0 ? rappelsActifs.toString() : null,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReminderScreen())),
              ),
              _ActionItem(
                titre: l10n.medications,
                icone: Icons.medication_outlined,
                couleur: mute,
                description: l10n.searchMedication,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MedicationsClientScreen())),
              ),
              _ActionItem(
                titre: l10n.myProfile,
                icone: Icons.person_outline_rounded,
                couleur: mute,
                description: l10n.personalInfo,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.18,
              ),
              itemCount: actions.length,
              itemBuilder: (ctx, i) => _ActionCard(
                  item: actions[i], isDark: isDark),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoBanner(AppLocalizations l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _P.dCard : _P.lCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? _P.dBorder : _P.lBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 19, color: isDark ? _P.dMute : _P.lMute),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.howItWorks,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A2E22),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.scanPrescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? _P.dMute : _P.lMute,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _salutation(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.goodMorning;
    if (h < 18) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }
}


class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color accent;
  final bool isDark;

  const _StatCard({
    required this.value, required this.label,
    required this.icon, required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? _P.dCard : _P.lCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? _P.dBorder : _P.lBorder, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: isDark ? _P.dMute : _P.lMute),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? _P.dMute : _P.lMute,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


class _ActionCard extends StatelessWidget {
  final _ActionItem item;
  final bool isDark;

  const _ActionCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPrimary = item.couleur == _P.green;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2E22);
    final subColor  = isDark ? _P.dMute : _P.lMute;

    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isDark ? _P.greenPastelDark : _P.greenPastel)
              : (isDark ? _P.dCard : _P.lCard),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? _P.dBorder : _P.lBorder,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.icone,
                  size: 22,
                  color: isPrimary
                      ? (isDark ? _P.greenPastel : _P.green)
                      : item.couleur,
                ),
                const Spacer(),
                Text(
                  item.titre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 11, color: subColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (item.badge != null)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _P.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final bool isDark;
  const _SectionHeader({
    required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A2E22),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: isDark ? _P.dMute : _P.lMute),
        ),
      ],
    );
  }
}


class _ActionItem {
  final String titre, description;
  final IconData icone;
  final Color couleur;
  final String? badge;
  final VoidCallback onTap;

  _ActionItem({
    required this.titre, required this.icone,
    required this.couleur, required this.description,
    this.badge, required this.onTap,
  });
}