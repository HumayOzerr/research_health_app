import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'account_settings_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsService settings;
  const SettingsScreen({super.key, required this.settings});

  static const _languages = [
    (code: '', flag: '🌐', name: 'System default'),
    (code: 'en', flag: '🇬🇧', name: 'English'),
    (code: 'de', flag: '🇩🇪', name: 'Deutsch'),
    (code: 'tr', flag: '🇹🇷', name: 'Türkçe'),
    (code: 'es', flag: '🇪🇸', name: 'Español'),
    (code: 'it', flag: '🇮🇹', name: 'Italiano'),
    (code: 'fr', flag: '🇫🇷', name: 'Français'),
    (code: 'zh', flag: '🇨🇳', name: '中文'),
    (code: 'ja', flag: '🇯🇵', name: '日本語'),
    (code: 'ko', flag: '🇰🇷', name: '한국어'),
    (code: 'ar', flag: '🇸🇦', name: 'العربية'),
    (code: 'ru', flag: '🇷🇺', name: 'Русский'),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FadeSlideIn(
                child: _SectionHeader(label: l.account, tt: tt, cs: cs),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 40),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.manage_accounts_rounded,
                        color: cs.primary),
                    title: Text(l.account),
                    subtitle: Text(
                      '${l.firstName}, ${l.lastName}, ${l.participantId}...',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(
                          page: const AccountSettingsScreen()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: _SectionHeader(label: l.appearance, tt: tt, cs: cs),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Card(
                  child: Column(
                    children: [
                      _ThemeOption(
                        label: l.themeSystem,
                        icon: Icons.brightness_auto_rounded,
                        selected: settings.themeMode == ThemeMode.system,
                        onTap: () =>
                            settings.setThemeMode(ThemeMode.system),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _ThemeOption(
                        label: l.themeLight,
                        icon: Icons.light_mode_rounded,
                        selected: settings.themeMode == ThemeMode.light,
                        onTap: () =>
                            settings.setThemeMode(ThemeMode.light),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _ThemeOption(
                        label: l.themeDark,
                        icon: Icons.dark_mode_rounded,
                        selected: settings.themeMode == ThemeMode.dark,
                        onTap: () =>
                            settings.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _SectionHeader(label: l.language, tt: tt, cs: cs),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Card(
                  child: Column(
                    children: _languages.indexed.map((entry) {
                      final (i, lang) = entry;
                      final isSelected = lang.code.isEmpty
                          ? settings.locale == null
                          : settings.locale?.languageCode == lang.code;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i > 0)
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: Text(lang.flag,
                                style: const TextStyle(fontSize: 22)),
                            title: Text(lang.name),
                            trailing: isSelected
                                ? Icon(Icons.check_rounded,
                                    color: cs.primary)
                                : null,
                            onTap: () => settings.setLocale(
                                lang.code.isEmpty
                                    ? null
                                    : Locale(lang.code)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: Card(
                  child: ListTile(
                    leading: Icon(Icons.logout_rounded, color: cs.error),
                    title: Text(l.signOut,
                        style: TextStyle(
                            color: cs.error,
                            fontWeight: FontWeight.w500)),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(l.signOut),
                          content: Text(l.signOutConfirm),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: Text(l.goBack),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: Text(l.signOut,
                                  style: TextStyle(color: cs.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await SupabaseService().signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            AppPageRoute(page: LoginScreen(settings: settings)),
                            (_) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String label;
  final TextTheme tt;
  final ColorScheme cs;

  const _SectionHeader(
      {required this.label, required this.tt, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading:
          Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
      title: Text(label),
      trailing:
          selected ? Icon(Icons.check_rounded, color: cs.primary) : null,
      onTap: onTap,
    );
  }
}
