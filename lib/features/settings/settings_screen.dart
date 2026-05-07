import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/vibration_service.dart';
import 'package:pharma_ai/core/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

final soundEnabledProvider = StateNotifierProvider<_BoolNotifier, bool>(
      (ref) => _BoolNotifier(
    initialValue: SoundService().isSoundEnabled,
    onChanged: (v) => SoundService().setSoundEnabled(v),
  ),
);

final vibrationEnabledProvider = StateNotifierProvider<_BoolNotifier, bool>(
      (ref) => _BoolNotifier(
    initialValue: VibrationService().isVibrationEnabled,
    onChanged: (v) => VibrationService().setVibrationEnabled(v),
  ),
);

class _BoolNotifier extends StateNotifier<bool> {
  final Future<void> Function(bool) onChanged;
  _BoolNotifier({required bool initialValue, required this.onChanged})
      : super(initialValue);
  Future<void> set(bool value) async {
    state = value;
    await onChanged(value);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode        = ref.watch(themeProvider);
    final themeNotif       = ref.read(themeProvider.notifier);
    final currentLang      = ref.watch(languageProvider);
    final langNotif        = ref.read(languageProvider.notifier);
    final notifEnabled     = ref.watch(notificationsEnabledProvider);
    final soundEnabled     = ref.watch(soundEnabledProvider);
    final vibrationEnabled = ref.watch(vibrationEnabledProvider);

    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n   = AppLocalizations.of(context)!;

    final bgColor   = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final divColor  = isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);
    final muteColor = isDark ? const Color(0xFF64748B) : const Color(0xFFADB5BD);
    final labelColor= isDark ? const Color(0xFF475569) : const Color(0xFFADB5BD);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.settings,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [

          _Label(text: l10n.appearance, color: labelColor),
          _Card(color: cardColor, children: [
            _ThemeRow(icon: Icons.light_mode_rounded,     label: l10n.light,     value: ThemeMode.light,  groupValue: themeMode, onChanged: (v) => themeNotif.setTheme(v!), muteColor: muteColor, primary: cs.primary),
            _Div(color: divColor),
            _ThemeRow(icon: Icons.dark_mode_rounded,      label: l10n.dark,      value: ThemeMode.dark,   groupValue: themeMode, onChanged: (v) => themeNotif.setTheme(v!), muteColor: muteColor, primary: cs.primary),
            _Div(color: divColor),
            _ThemeRow(icon: Icons.brightness_auto_rounded, label: l10n.automatic, value: ThemeMode.system, groupValue: themeMode, onChanged: (v) => themeNotif.setTheme(v!), muteColor: muteColor, primary: cs.primary),
          ]),

          const SizedBox(height: 28),

          _Label(text: l10n.language, color: labelColor),
          _Card(color: cardColor, children: [
            _LangRow(flag: '🇫🇷', label: l10n.french,  locale: const Locale('fr'), current: currentLang, onTap: () => langNotif.setLocale(const Locale('fr')), primary: cs.primary),
            _Div(color: divColor),
            _LangRow(flag: '🇬🇧', label: l10n.english, locale: const Locale('en'), current: currentLang, onTap: () => langNotif.setLocale(const Locale('en')), primary: cs.primary),
            _Div(color: divColor),
            _LangRow(flag: '🇸🇦', label: l10n.arabic,  locale: const Locale('ar'), current: currentLang, onTap: () => langNotif.setLocale(const Locale('ar')), primary: cs.primary),
          ]),

          const SizedBox(height: 28),

          _Label(text: l10n.notifications, color: labelColor),
          _Card(color: cardColor, children: [
            _SwitchRow(
              icon: Icons.notifications_outlined,
              label: l10n.notifications,
              subtitle: 'Rappels & alertes stock',
              value: notifEnabled,
              onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).state = v,
              muteColor: muteColor,
              primary: cs.primary,
            ),
            _Div(color: divColor),
            _TestTile(primary: cs.primary, cardColor: cardColor),
          ]),

          const SizedBox(height: 28),

          _Label(text: 'Son & Vibration', color: labelColor),
          _Card(color: cardColor, children: [
            _SwitchRow(
              icon: soundEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
              label: 'Sons',
              subtitle: 'Bips scan, succès, erreurs',
              value: soundEnabled,
              onChanged: (v) => ref.read(soundEnabledProvider.notifier).set(v),
              muteColor: muteColor,
              primary: cs.primary,
            ),
            _Div(color: divColor),
            _SwitchRow(
              icon: vibrationEnabled ? Icons.vibration_rounded : Icons.phonelink_erase_outlined,
              label: 'Vibrations',
              subtitle: 'Retour haptique',
              value: vibrationEnabled,
              onChanged: (v) => ref.read(vibrationEnabledProvider.notifier).set(v),
              muteColor: muteColor,
              primary: cs.primary,
            ),
          ]),

          const SizedBox(height: 28),

          _Label(text: l10n.about, color: labelColor),
          _Card(color: cardColor, children: [
            _NavRow(icon: Icons.local_pharmacy_outlined, label: l10n.appName,       subtitle: 'Version 1.0.0', muteColor: muteColor),
            _Div(color: divColor),
            _NavRow(icon: Icons.shield_outlined,         label: l10n.privacyPolicy, muteColor: muteColor,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bientôt disponible')),
              ),
            ),
          ]),

          const SizedBox(height: 32),

          _LogoutTile(cardColor: cardColor),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}



class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
    ),
  );
}

class _Card extends StatelessWidget {
  final Color color;
  final List<Widget> children;
  const _Card({required this.color, required this.children});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Container(color: color, child: Column(children: children)),
  );
}

class _Div extends StatelessWidget {
  final Color color;
  const _Div({required this.color});

  @override
  Widget build(BuildContext context) => Container(
      height: 1, margin: const EdgeInsets.only(left: 52), color: color);
}



class _ThemeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode value, groupValue;
  final void Function(ThemeMode?) onChanged;
  final Color muteColor, primary;

  const _ThemeRow({
    required this.icon, required this.label,
    required this.value, required this.groupValue,
    required this.onChanged, required this.muteColor, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final sel = value == groupValue;
    final cs  = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 19, color: sel ? primary : muteColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? cs.onSurface : cs.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: sel ? primary : cs.onSurface.withOpacity(0.2),
                width: sel ? 5 : 1.5,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  final String flag, label;
  final Locale locale, current;
  final VoidCallback onTap;
  final Color primary;

  const _LangRow({
    required this.flag, required this.label,
    required this.locale, required this.current,
    required this.onTap, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final sel = locale.languageCode == current.languageCode;
    final cs  = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 19)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? cs.onSurface : cs.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: sel
                ? Icon(Icons.check_rounded, color: primary, size: 17, key: const ValueKey('y'))
                : const SizedBox(width: 17, key: ValueKey('n')),
          ),
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color muteColor, primary;

  const _SwitchRow({
    required this.icon, required this.label, required this.subtitle,
    required this.value, required this.onChanged,
    required this.muteColor, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Icon(icon, size: 19, color: value ? primary : muteColor),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text(subtitle, style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.4), fontSize: 12)),
          ],
        )),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color muteColor;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon, required this.label,
    required this.muteColor, this.subtitle, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 19, color: muteColor),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              if (subtitle != null) Text(subtitle!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.4), fontSize: 12)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, size: 17, color: cs.onSurface.withOpacity(0.22)),
        ]),
      ),
    );
  }
}


class _TestTile extends StatefulWidget {
  final Color primary, cardColor;
  const _TestTile({required this.primary, required this.cardColor});

  @override
  State<_TestTile> createState() => _TestTileState();
}

class _TestTileState extends State<_TestTile> {
  bool _isSending = false;

  Future<void> _send() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    try {
      await Future.wait([
        SoundService().playNotification(),
        VibrationService().doubleVibrate(),
      ]);
      await NotificationService().scheduleTestNotification(
        id: 9999,
        titre: '🔔 Test PharmaAI',
        message: 'Votre rappel de médicament fonctionne correctement !',
        delaySeconds: 3,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Notification envoyée dans 3 secondes'),
        ]),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute   = isDark ? const Color(0xFF64748B) : const Color(0xFFADB5BD);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.send_outlined, size: 19, color: mute),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Test de notification', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text('Envoyer un rappel immédiat', style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.4), fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: _isSending ? null : _send,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.primary,
              side: BorderSide(color: widget.primary.withOpacity(0.35), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isSending
                ? SizedBox(width: 13, height: 13,
                child: CircularProgressIndicator(color: widget.primary, strokeWidth: 1.8))
                : Icon(Icons.notifications_outlined, size: 15, color: widget.primary),
            label: Text(
              _isSending ? 'Envoi...' : 'Envoyer un rappel test',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: widget.primary),
            ),
          ),
        ),
      ]),
    );
  }
}



class _LogoutTile extends ConsumerStatefulWidget {
  final Color cardColor;
  const _LogoutTile({required this.cardColor});

  @override
  ConsumerState<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends ConsumerState<_LogoutTile> {
  static const Color _rouge = Color(0xFFDC2626);
  bool _isLoading = false;

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout, color: _rouge, size: 20),
          SizedBox(width: 10),
          Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _rouge,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: _rouge,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _confirm,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          _isLoading
              ? const SizedBox(width: 19, height: 19,
              child: CircularProgressIndicator(color: _rouge, strokeWidth: 2))
              : const Icon(Icons.logout_rounded, color: _rouge, size: 19),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Se déconnecter',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _rouge, fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.chevron_right_rounded, size: 17, color: _rouge.withOpacity(0.3)),
        ]),
      ),
    );
  }
}