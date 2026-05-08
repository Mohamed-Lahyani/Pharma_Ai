import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';

import 'firebase_options.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/client/home/client_home_screen.dart';
import 'features/client/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'core/l10n/language_provider.dart';

import 'core/services/notification_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/vibration_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().init();
  await SoundService().init();
  await VibrationService().init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale    = ref.watch(languageProvider);

    return MaterialApp(
      title                     : 'PharmaAI',
      debugShowCheckedModeBanner: false,


      theme     : AppTheme.lightTheme,
      darkTheme : AppTheme.darkTheme,
      themeMode : themeMode,

      locale          : locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

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