import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Localisation Flutter (généré par flutter gen-l10n) ────────
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';

import 'firebase_options.dart';

// ── Écrans ────────────────────────────────────────────────────
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/client/home/client_home_screen.dart';
import 'features/client/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';

// ── Thème ─────────────────────────────────────────────────────
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

// ── Langue ────────────────────────────────────────────────────
import 'core/l10n/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ProviderScope est obligatoire pour que Riverpod fonctionne
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// ConsumerWidget → accès aux providers Riverpod (thème + langue)
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Écouter le thème choisi par l'utilisateur ──────────────
    final themeMode = ref.watch(themeProvider);

    // ── Écouter la langue choisie par l'utilisateur ────────────
    // Quand l'utilisateur change la langue dans SettingsScreen,
    // ce widget se reconstruit automatiquement → toute l'appli
    // affiche la nouvelle langue instantanément
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title                     : 'PharmaAI',
      debugShowCheckedModeBanner: false,

      // ── Thèmes ───────────────────────────────────────────────
      theme     : AppTheme.lightTheme,
      darkTheme : AppTheme.darkTheme,
      themeMode : themeMode,

      // ── Langue active ────────────────────────────────────────
      // locale vient du languageProvider (fr / en / ar)
      locale: locale,

      // ── Langues supportées ───────────────────────────────────
      // Doit correspondre aux fichiers arb générés
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // English
        Locale('ar'), // العربية
      ],

      // ── Délégués de localisation ─────────────────────────────
      // AppLocalizations.delegate → nos traductions (app_fr/en/ar.arb)
      // GlobalMaterialLocalizations → boutons, dates, etc. traduits
      // GlobalWidgetsLocalizations  → direction du texte (RTL pour arabe)
      // GlobalCupertinoLocalizations → composants iOS traduits
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Routes ───────────────────────────────────────────────
      initialRoute: '/',
      routes: {
        '/'         : (context) => const LoginScreen(),
        '/admin'    : (context) => const AdminHomeScreen(),
        '/client'   : (context) => const ClientHomeScreen(),
        '/register' : (context) => const RegisterScreen(),
        '/profile'  : (context) => const ProfileScreen(),
        '/settings' : (context) => const SettingsScreen(),
      },
    );
  }
}