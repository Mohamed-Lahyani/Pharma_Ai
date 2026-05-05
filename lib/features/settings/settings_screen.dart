import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharma_ai/core/l10n/app_localizations.dart';

// ── AJOUT : import des traductions ────────────────────────────

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/l10n/language_provider.dart';

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode    = ref.watch(themeProvider);
    final themeNotif   = ref.read(themeProvider.notifier);
    final currentLang  = ref.watch(languageProvider);
    final langNotif    = ref.read(languageProvider.notifier);
    final notifEnabled = ref.watch(notificationsEnabledProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    // ── AJOUT : récupérer les traductions ─────────────────────
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        // ✅ Traduit
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [

          // ── SECTION 1 : Apparence ───────────────────────────
          _SectionTitle(
            icon : Icons.palette_outlined,
            // ✅ Traduit
            label: l10n.appearance,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [

                _ThemeOption(
                  icon      : Icons.light_mode_rounded,
                  // ✅ Traduit
                  label     : l10n.light,
                  subtitle  : 'Fond blanc, texte sombre',
                  value     : ThemeMode.light,
                  groupValue: themeMode,
                  onChanged : (val) => themeNotif.setTheme(val!),
                  iconColor : Colors.orange,
                ),

                const Divider(height: 1, indent: 56),

                _ThemeOption(
                  icon      : Icons.dark_mode_rounded,
                  // ✅ Traduit
                  label     : l10n.dark,
                  subtitle  : 'Fond noir, texte clair',
                  value     : ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged : (val) => themeNotif.setTheme(val!),
                  iconColor : AppTheme.primaryBlueDark,
                ),

                const Divider(height: 1, indent: 56),

                _ThemeOption(
                  icon      : Icons.brightness_auto_rounded,
                  // ✅ Traduit
                  label     : l10n.automatic,
                  subtitle  : 'Suit les réglages du téléphone',
                  value     : ThemeMode.system,
                  groupValue: themeMode,
                  onChanged : (val) => themeNotif.setTheme(val!),
                  iconColor : AppTheme.green,
                ),

              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 2 : Langue ──────────────────────────────
          _SectionTitle(
            icon : Icons.language_rounded,
            // ✅ Traduit
            label: l10n.language,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [

                _LanguageOption(
                  flag   : '🇫🇷',
                  // ✅ Traduit
                  label  : l10n.french,
                  locale : const Locale('fr'),
                  current: currentLang,
                  onTap  : () => langNotif.setLocale(const Locale('fr')),
                ),

                const Divider(height: 1, indent: 56),

                _LanguageOption(
                  flag   : '🇬🇧',
                  // ✅ Traduit
                  label  : l10n.english,
                  locale : const Locale('en'),
                  current: currentLang,
                  onTap  : () => langNotif.setLocale(const Locale('en')),
                ),

                const Divider(height: 1, indent: 56),

                _LanguageOption(
                  flag   : '🇸🇦',
                  // ✅ Traduit (le nom arabe reste en arabe dans les 3 langues)
                  label  : l10n.arabic,
                  locale : const Locale('ar'),
                  current: currentLang,
                  onTap  : () => langNotif.setLocale(const Locale('ar')),
                ),

              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 3 : Notifications ───────────────────────
          _SectionTitle(
            icon : Icons.notifications_outlined,
            // ✅ Traduit
            label: l10n.notifications,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width : 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color       : AppTheme.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppTheme.amber,
                      size : 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // ✅ Traduit
                          l10n.notifications,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rappels médicaments et alertes stock',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value    : notifEnabled,
                    onChanged: (val) => ref
                        .read(notificationsEnabledProvider.notifier)
                        .state = val,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── SECTION 4 : À propos ────────────────────────────
          _SectionTitle(
            icon : Icons.info_outline_rounded,
            // ✅ Traduit
            label: l10n.about,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width : 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color       : colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_pharmacy_rounded,
                      color: colorScheme.primary,
                      size : 20,
                    ),
                  ),
                  // ✅ Traduit
                  title   : Text(l10n.appName),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),

                const Divider(height: 1, indent: 56),

                ListTile(
                  leading: Container(
                    width : 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color       : AppTheme.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppTheme.green,
                      size : 20,
                    ),
                  ),
                  // ✅ Traduit
                  title   : Text(l10n.privacyPolicy),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bientôt disponible')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Les widgets privés (_SectionTitle, _ThemeOption, _LanguageOption)
// restent identiques — pas de texte codé en dur dedans ────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _SectionTitle({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color        : color,
            fontWeight   : FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final String    subtitle;
  final ThemeMode value;
  final ThemeMode groupValue;
  final Color     iconColor;
  final void Function(ThemeMode?) onChanged;
  const _ThemeOption({required this.icon, required this.label, required this.subtitle, required this.value, required this.groupValue, required this.iconColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected  = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;
    return RadioListTile<ThemeMode>(
      value          : value,
      groupValue     : groupValue,
      onChanged      : onChanged,
      activeColor    : colorScheme.primary,
      contentPadding : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          Container(
            width : 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final Locale locale;
  final Locale current;
  final VoidCallback onTap;
  const _LanguageOption({required this.flag, required this.label, required this.locale, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected  = locale.languageCode == current.languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap          : onTap,
      contentPadding : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(flag, style: const TextStyle(fontSize: 20))),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color     : isSelected ? colorScheme.primary : null,
      )),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : Icon(Icons.radio_button_unchecked_rounded, color: colorScheme.onSurface.withOpacity(0.3)),
    );
  }
}