import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── AJOUT : traductions ───────────────────────────────────────
import 'package:pharma_ai/core/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color primaryColor   = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFF2E7D32);
  static const Color dangerColor    = Color(0xFFC62828);
  static const Color bgColor        = Color(0xFFF5F7FA);

  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey         = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool   _isLoading  = true;
  bool   _isSaving   = false;
  bool   _isEditMode = false;
  String _userRole   = 'client';
  String _createdAt  = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text  = data['name']  ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = user.email    ?? '';
          _userRole             = data['role']  ?? 'client';

          if (data['createdAt'] != null) {
            final ts   = data['createdAt'] as Timestamp;
            final date = ts.toDate();
            _createdAt = '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year}';
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur lors du chargement du profil', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'name'     : _nameController.text.trim(),
        'phone'    : _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await user.updateDisplayName(_nameController.text.trim());

      setState(() {
        _isSaving   = false;
        _isEditMode = false;
      });
      // ✅ Traduit
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(l10n.profileUpdated);
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar('Erreur lors de la sauvegarde', isError: true);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    // ✅ On récupère l10n avant le showDialog
    final l10n = AppLocalizations.of(context)!;

    final currentPwdCtrl = TextEditingController();
    final newPwdCtrl     = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool hideCurrentPwd  = true;
    bool hideNewPwd      = true;
    bool hideConfirmPwd  = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                // ✅ Traduit
                l10n.changePassword,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller : currentPwdCtrl,
                obscureText: hideCurrentPwd,
                decoration : InputDecoration(
                  // ✅ Traduit
                  labelText : l10n.currentPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(hideCurrentPwd
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setDialogState(
                            () => hideCurrentPwd = !hideCurrentPwd),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller : newPwdCtrl,
                obscureText: hideNewPwd,
                decoration : InputDecoration(
                  // ✅ Traduit
                  labelText : l10n.newPassword,
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(hideNewPwd
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setDialogState(() => hideNewPwd = !hideNewPwd),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller : confirmPwdCtrl,
                obscureText: hideConfirmPwd,
                decoration : InputDecoration(
                  // ✅ Traduit
                  labelText : l10n.confirm,
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(hideConfirmPwd
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setDialogState(
                            () => hideConfirmPwd = !hideConfirmPwd),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              // ✅ Traduit
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (currentPwdCtrl.text.isEmpty ||
                    newPwdCtrl.text.isEmpty     ||
                    confirmPwdCtrl.text.isEmpty) {
                  _showSnackBar('Veuillez remplir tous les champs',
                      isError: true);
                  return;
                }
                if (newPwdCtrl.text.length < 6) {
                  _showSnackBar(
                      'Le nouveau mot de passe doit avoir au moins 6 caractères',
                      isError: true);
                  return;
                }
                if (newPwdCtrl.text != confirmPwdCtrl.text) {
                  _showSnackBar(
                      'Les mots de passe ne correspondent pas',
                      isError: true);
                  return;
                }
                try {
                  final user       = _auth.currentUser!;
                  final credential = EmailAuthProvider.credential(
                    email   : user.email!,
                    password: currentPwdCtrl.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  await user.updatePassword(newPwdCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackBar('Mot de passe changé avec succès ✓');
                } on FirebaseAuthException catch (e) {
                  _showSnackBar(
                    e.code == 'wrong-password'
                        ? 'Mot de passe actuel incorrect'
                        : 'Erreur lors du changement de mot de passe',
                    isError: true,
                  );
                }
              },
              // ✅ Traduit
              child: Text(l10n.confirm,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        // ✅ Traduit
        title  : Text(l10n.signOut),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            // ✅ Traduit
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            // ✅ Traduit
            child: Text(l10n.signOut,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content        : Text(message),
        backgroundColor: isError ? dangerColor : secondaryColor,
        behavior       : SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getInitials() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // ── AJOUT : récupérer les traductions ─────────────────────
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        // ✅ Traduit
        title: Text(l10n.myProfile,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme      : const IconThemeData(color: Colors.white),
        elevation      : 0,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditMode ? Icons.close : Icons.edit),
              // ✅ Traduit
              tooltip: _isEditMode ? l10n.cancel : l10n.edit,
              onPressed: () {
                if (_isEditMode) _loadUserData();
                setState(() => _isEditMode = !_isEditMode);
              },
            ),
        ],
      ),

      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key : _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              _buildAvatar(l10n),
              const SizedBox(height: 24),

              // ── Informations personnelles ──────────────
              _buildSectionCard(
                // ✅ Traduit
                title   : l10n.personalInfo,
                icon    : Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    // ✅ Traduit
                    label     : l10n.fullName,
                    icon      : Icons.badge_outlined,
                    enabled   : _isEditMode,
                    validator : (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Le nom est requis'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller  : _emailController,
                    // ✅ Traduit
                    label       : l10n.email,
                    icon        : Icons.email_outlined,
                    enabled     : false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller  : _phoneController,
                    label       : 'Téléphone (optionnel)',
                    icon        : Icons.phone_outlined,
                    enabled     : _isEditMode,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Informations du compte ─────────────────
              _buildSectionCard(
                title   : 'Informations du compte',
                icon    : Icons.info_outline,
                children: [
                  _buildInfoRow(
                    label: 'Rôle',
                    value: _userRole == 'admin'
                        ? 'Administrateur'
                        : 'Client',
                    icon : _userRole == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: _userRole == 'admin'
                        ? primaryColor
                        : secondaryColor,
                  ),
                  if (_createdAt.isNotEmpty) ...[
                    const Divider(height: 20),
                    _buildInfoRow(
                      label: 'Membre depuis',
                      value: _createdAt,
                      icon : Icons.calendar_today_outlined,
                      color: Colors.grey[600]!,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // ── Bouton Sauvegarder ─────────────────────
              if (_isEditMode) ...[
                SizedBox(
                  width : double.infinity,
                  height: 50,
                  child : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                        width : 18,
                        height: 18,
                        child : CircularProgressIndicator(
                            color      : Colors.white,
                            strokeWidth: 2))
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      // ✅ Traduit
                      _isSaving ? l10n.loading : l10n.saveChanges,
                      style: const TextStyle(
                          color     : Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Sécurité ───────────────────────────────
              _buildSectionCard(
                title   : 'Sécurité',
                icon    : Icons.security,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: primaryColor, size: 20),
                    ),
                    // ✅ Traduit
                    title   : Text(l10n.changePassword,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    subtitle: const Text(
                        'Modifier votre mot de passe de connexion'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap   : _showChangePasswordDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Déconnexion ────────────────────────────
              SizedBox(
                width : double.infinity,
                height: 50,
                child : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dangerColor,
                    side : const BorderSide(color: dangerColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _confirmSignOut,
                  icon : const Icon(Icons.logout),
                  // ✅ Traduit
                  label: Text(l10n.signOut,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),

              // ── Version ────────────────────────────────
              Text('${l10n.appName} v1.0.0',
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────
  Widget _buildAvatar(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width : 90,
          height: 90,
          decoration: BoxDecoration(
            shape   : BoxShape.circle,
            gradient: const LinearGradient(
              colors: [primaryColor, Color(0xFF1976D2)],
              begin : Alignment.topLeft,
              end   : Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color     : primaryColor.withOpacity(0.35),
                blurRadius: 12,
                offset    : const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _getInitials(),
              style: const TextStyle(
                  fontSize  : 32,
                  fontWeight: FontWeight.bold,
                  color     : Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _nameController.text.isEmpty ? 'Utilisateur' : _nameController.text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: (_userRole == 'admin' ? primaryColor : secondaryColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _userRole == 'admin' ? 'Administrateur' : l10n.clients,
            style: TextStyle(
              color     : _userRole == 'admin' ? primaryColor : secondaryColor,
              fontSize  : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String       title,
    required IconData     icon,
    required List<Widget> children,
  }) {
    return Container(
      width  : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow   : [
          BoxShadow(
            color     : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset    : const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize  : 15,
                  fontWeight: FontWeight.bold,
                  color     : Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String                label,
    required IconData              icon,
    bool                           enabled      = true,
    TextInputType?                 keyboardType,
    String? Function(String?)?     validator,
  }) {
    return TextFormField(
      controller  : controller,
      enabled     : enabled,
      keyboardType: keyboardType,
      validator   : validator,
      decoration  : InputDecoration(
        labelText : label,
        prefixIcon: Icon(icon,
            color: enabled ? primaryColor : Colors.grey),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide  : const BorderSide(color: Color(0xFFBBDEFB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide  : const BorderSide(color: primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide  : const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        filled    : !enabled,
        fillColor : enabled ? null : Colors.grey[50],
        labelStyle: TextStyle(
            color: enabled ? Colors.grey[700] : Colors.grey[400]),
      ),
    );
  }

  Widget _buildInfoRow({
    required String   label,
    required String   value,
    required IconData icon,
    required Color    color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color       : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}