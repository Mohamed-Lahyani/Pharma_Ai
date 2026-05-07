import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharma_ai/features/auth/register_screen.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import 'package:pharma_ai/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Connexion Email / Mot de passe ───────────────────────────
  Future<void> _login() async {
    setState(() {
      _isLoading    = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final role = doc.data()!['role'];
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/client');
        }
      } else {
        setState(() {
          _errorMessage = 'Utilisateur introuvable dans la base de données.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Aucun compte trouvé avec cet email.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Mot de passe incorrect.';
        } else {
          _errorMessage = 'Erreur : ${e.message}';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Connexion Google ─────────────────────────────────────────
  /* Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage    = '';
    });

    try {
      final googleProvider = GoogleAuthProvider();
      final userCredential = await FirebaseAuth.instance
          .signInWithPopup(googleProvider);

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
      final role = doc.exists ? (doc.data()!['role'] ?? 'client') : 'client';
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/client');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erreur Google : $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }*/
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage    = '';
    });

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // ── WEB : signInWithPopup (ton ancien code) ───────────
        final googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance
            .signInWithPopup(googleProvider);
      } else {
        // ── MOBILE : signInWithCredential ─────────────────────
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

      // ── Partie commune Web + Mobile ────────────────────────
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
      final role = doc.exists ? (doc.data()!['role'] ?? 'client') : 'client';
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/client');
      }

    } catch (e) {
      setState(() => _errorMessage = 'Erreur Google : $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

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
                      l10n.signIn,
                      style: TextStyle(
                        fontSize: 14,
                        // ✅ Texte secondaire adaptatif
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // ── Champ Email ─────────────────────────────────
              Text(
                l10n.email,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  // ✅ Texte principal adaptatif
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
                  // ✅ Fond input adaptatif
                  fillColor: AppColors.inputFill(context),
                ),
              ),

              const SizedBox(height: 20),

              // ── Champ Mot de passe ──────────────────────────
              Text(
                l10n.password,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  // ✅ Texte principal adaptatif
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
                  // ✅ Fond input adaptatif
                  fillColor: AppColors.inputFill(context),
                ),
              ),

              const SizedBox(height: 12),

              // ── Message d'erreur ────────────────────────────
              if (_errorMessage.isNotEmpty)
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

              const SizedBox(height: 24),

              // ── Bouton Se connecter ─────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    // ✅ Couleur primaire adaptative
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

              // ── Séparateur OU ───────────────────────────────
              Row(
                children: [
                  Expanded(
                      child: Divider(
                        // ✅ Bordure adaptative
                          color: AppColors.border(context))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        // ✅ Texte secondaire adaptatif
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

              // ── Bouton Google ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    // ✅ Bordure adaptative
                    side: BorderSide(
                        color: AppColors.border(context), width: 1.5),
                    // ✅ Fond adaptatif (surface au lieu de Colors.white fixe)
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
                      // ✅ Couleur primaire adaptative
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
                          // ✅ Texte adaptatif (était Color(0xFF3C4043) fixe)
                          color: AppColors.onSurface(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Lien S'inscrire ─────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(
                        // ✅ Texte secondaire adaptatif
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
    );
  }
}

// ── Widget icône Google ───────────────────────────────────────
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

// ── Painter icône Google — couleurs officielles, inchangées ───
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