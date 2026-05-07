import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:pharma_ai/core/services/vibration_service.dart';
import 'package:pharma_ai/core/services/sound_service.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _vibration = VibrationService();
  final _sound     = SoundService();
  bool _isLoading    = false;
  bool _showPassword = false;
  bool _showConfirm  = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

 /* Future<void> _register() async {
    setState(() => _errorMessage = '');
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await credential.user!.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid'      : credential.user!.uid,
        'name'     : _nameController.text.trim(),
        'email'    : _emailController.text.trim(),
        'phone'    : _phoneController.text.trim(),
        'role'     : 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountCreated),
            // ✅ Couleur succès sémantique conservée
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
        await FirebaseAuth.instance.signOut();
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'Cet email est déjà utilisé par un autre compte.';
            break;
          case 'weak-password':
            _errorMessage = 'Le mot de passe est trop faible (min. 6 caractères).';
            break;
          case 'invalid-email':
            _errorMessage = 'Adresse email invalide.';
            break;
          default:
            _errorMessage = 'Erreur : ${e.message}';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Une erreur inattendue est survenue.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }*/
  Future<void> _register() async {
    setState(() => _errorMessage = '');

    // ── Validation du formulaire ────────────────────────────────
    if (!_formKey.currentState!.validate()) {
      // ✅ Vibration + son erreur si validation échoue
      await _vibration.error();
      await _sound.playError();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await credential.user!.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid'      : credential.user!.uid,
        'name'     : _nameController.text.trim(),
        'email'    : _emailController.text.trim(),
        'phone'    : _phoneController.text.trim(),
        'role'     : 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // ✅ Succès inscription — son + vibration
        await _vibration.success();
        await _sound.playSuccess();

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountCreated),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
        await FirebaseAuth.instance.signOut();
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      // ✅ Erreur Firebase — son + vibration
      await _vibration.error();
      await _sound.playError();

      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'Cet email est déjà utilisé par un autre compte.';
            break;
          case 'weak-password':
            _errorMessage = 'Le mot de passe est trop faible (min. 6 caractères).';
            break;
          case 'invalid-email':
            _errorMessage = 'Adresse email invalide.';
            break;
          case 'network-request-failed':
            _errorMessage = 'Pas de connexion internet. Vérifiez votre réseau.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Trop de tentatives. Réessayez dans quelques minutes.';
            break;
          default:
            _errorMessage = 'Erreur : ${e.message}';
        }
      });

    } catch (e) {
      // ✅ Erreur inattendue — son + vibration
      await _vibration.error();
      await _sound.playError();

      setState(() => _errorMessage = 'Une erreur inattendue est survenue.');

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ Fond adaptatif
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Logo et titre ───────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          // ✅ Couleur primaire adaptative
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          // ✅ Couleur primaire adaptative
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.createAccount,
                        style: TextStyle(
                          fontSize: 14,
                          // ✅ Texte secondaire adaptatif
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Message d'erreur ────────────────────────────
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // ✅ .withValues() remplace .withOpacity() — rouge sémantique conservé
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Nom complet ─────────────────────────────────
                _buildLabel(context, l10n.fullName),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    context,
                    hint: 'Ex : Ahmed Benali',
                    icon: Icons.person_outline,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    if (val.trim().length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Email ───────────────────────────────────────
                _buildLabel(context, l10n.email),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    context,
                    hint: 'exemple@email.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(val.trim())) {
                      return 'Format email invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Téléphone ───────────────────────────────────
                _buildLabel(context, 'Téléphone (optionnel)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    context,
                    hint: '0X XX XX XX XX',
                    icon: Icons.phone_outlined,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Mot de passe ────────────────────────────────
                _buildLabel(context, l10n.password),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: _inputDecoration(
                    context,
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (val.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Confirmer mot de passe ──────────────────────
                _buildLabel(context, l10n.newPassword),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_showConfirm,
                  decoration: _inputDecoration(
                    context,
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (val != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // ── Bouton S'inscrire ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      // ✅ Couleur primaire adaptative
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      l10n.signUp,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Lien vers Login ─────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous avez déjà un compte ? ',
                        style: TextStyle(
                          // ✅ Texte secondaire adaptatif
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          l10n.signIn,
                          style: TextStyle(
                            // ✅ Couleur primaire adaptative
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper : label de champ ───────────────────────────────────
  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        // ✅ Texte principal adaptatif
        color: AppColors.onSurface(context),
      ),
    );
  }

  // ── Helper : décoration de champ ─────────────────────────────
  InputDecoration _inputDecoration(
      BuildContext context, {
        required String hint,
        required IconData icon,
        Widget? suffixIcon,
      }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary(context)),
      prefixIcon: Icon(icon,
          // ✅ Couleur primaire adaptative
          color: Theme.of(context).colorScheme.primary),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      // ✅ Fond input adaptatif
      fillColor: AppColors.inputFill(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // ✅ Bordure adaptative
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // ✅ Rouge sémantique conservé
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}