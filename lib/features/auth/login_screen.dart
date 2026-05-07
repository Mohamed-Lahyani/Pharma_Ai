import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/features/auth/register_screen.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pharma_ai/core/services/vibration_service.dart';
import 'package:pharma_ai/core/services/sound_service.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading       = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String _errorMessage  = '';
  final _vibration = VibrationService();
  final _sound     = SoundService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      await _vibration.error();
      await _sound.playError();
      setState(() => _errorMessage = 'Veuillez entrer votre adresse email.');
      return;
    }

    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      await _vibration.error();
      await _sound.playError();
      setState(() => _errorMessage = 'Adresse email invalide (ex: nom@domaine.com).');
      return;
    }

    if (password.isEmpty) {
      await _vibration.error();
      await _sound.playError();
      setState(() => _errorMessage = 'Veuillez entrer votre mot de passe.');
      return;
    }

    if (password.length < 6) {
      await _vibration.error();
      await _sound.playError();
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() {
      _isLoading    = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        await _vibration.success();
        await _sound.playSuccess();

        final role = doc.data()!['role'];
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/client');
        }
      } else {
        await _vibration.error();
        await _sound.playError();
        setState(() => _errorMessage = 'Compte introuvable. Veuillez vous inscrire.');
      }

    } on FirebaseAuthException catch (e) {
      await _vibration.error();
      await _sound.playError();

      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'Aucun compte associé à cet email.';
            break;
          case 'wrong-password':
            _errorMessage = 'Mot de passe incorrect. Réessayez.';
            break;
          case 'invalid-email':
            _errorMessage = 'Format d\'email invalide.';
            break;
          case 'user-disabled':
            _errorMessage = 'Ce compte a été désactivé. Contactez le support.';
            break;
          case 'too-many-requests':
            _errorMessage = 'Trop de tentatives. Réessayez dans quelques minutes.';
            break;
          case 'network-request-failed':
            _errorMessage = 'Pas de connexion internet. Vérifiez votre réseau.';
            break;
          case 'invalid-credential':
            _errorMessage = 'Email ou mot de passe incorrect.';
            break;
          default:
            _errorMessage = 'Erreur de connexion. Réessayez.';
        }
      });

    } catch (e) {
      await _vibration.error();
      await _sound.playError();
      setState(() => _errorMessage = 'Erreur inattendue. Réessayez.');

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage    = '';
    });

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(googleProvider);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _isGoogleLoading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken:     googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);
      }
      final user = userCredential.user!;
      final doc  = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid'      : user.uid,
          'name'     : user.displayName ?? 'Utilisateur',
          'email'    : user.email ?? '',
          'phone'    : '',
          'role'     : 'client',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      await _vibration.success();
      await _sound.playSuccess();

      final role = doc.exists ? (doc.data()!['role'] ?? 'client') : 'client';
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/client');
      }

    } catch (e) {
      await _vibration.error();
      await _sound.playError();

      setState(() => _errorMessage = 'Erreur Google : $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.signIn,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              Text(
                l10n.email,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.onSurface(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'exemple@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.inputFill(context),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                l10n.password,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.onSurface(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.inputFill(context),
                ),
              ),

              const SizedBox(height: 12),

              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    l10n.signIn,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: AppColors.border(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: AppColors.border(context))),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.border(context), width: 1.5),
                    backgroundColor: AppColors.surface(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isGoogleLoading
                      ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleIcon(),
                      const SizedBox(width: 12),
                      Text(
                        'Continuer avec Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(
                          color: AppColors.textSecondary(context)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.signUp,
                        style: TextStyle(
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
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          CustomPaint(
            size: const Size(24, 24),
            painter: _GoogleIconPainter(),
          ),
        ],
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r  = size.width / 2 - 1;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        -2.4, 1.55, false, paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        -0.85, 1.55, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        0.70, 1.55, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        2.25, 1.0, false, paint);

    paint
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(cx, cy - 0.5),
      Offset(cx + r * 0.72, cy - 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}