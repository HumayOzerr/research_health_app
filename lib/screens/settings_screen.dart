import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../widgets/fade_slide_in.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsService settings;

  const SettingsScreen({super.key, required this.settings});

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
                delay: const Duration(milliseconds: 0),
                child: _SectionHeader(label: l.appearance, tt: tt, cs: cs),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Card(
                  child: Column(
                    children: [
                      _ThemeOption(
                        label: l.themeSystem,
                        icon: Icons.brightness_auto_rounded,
                        selected: settings.themeMode == ThemeMode.system,
                        onTap: () => settings.setThemeMode(ThemeMode.system),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _ThemeOption(
                        label: l.themeLight,
                        icon: Icons.light_mode_rounded,
                        selected: settings.themeMode == ThemeMode.light,
                        onTap: () => settings.setThemeMode(ThemeMode.light),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _ThemeOption(
                        label: l.themeDark,
                        icon: Icons.dark_mode_rounded,
                        selected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settings.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _SectionHeader(label: l.language, tt: tt, cs: cs),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: Card(
                  child: Column(
                    children: [
                      _LangOption(
                        label: l.languageSystem,
                        flag: '🌐',
                        selected: settings.locale == null,
                        onTap: () => settings.setLocale(null),
                      ),
                      ..._languages.map((lang) {
                        final isSelected =
                            settings.locale?.languageCode == lang.code;
                        return Column(
                          children: [
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            _LangOption(
                              label: lang.nativeName,
                              flag: lang.flag,
                              selected: isSelected,
                              onTap: () =>
                                  settings.setLocale(Locale(lang.code)),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
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
      leading: Icon(icon, color: selected ? cs.primary : cs.onSurfaceVariant),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_rounded, color: cs.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_rounded, color: cs.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _LangMeta {
  final String code;
  final String nativeName;
  final String flag;
  const _LangMeta(this.code, this.nativeName, this.flag);
}

const _languages = [
  _LangMeta('en', 'English', '🇬🇧'),
  _LangMeta('de', 'Deutsch', '🇩🇪'),
  _LangMeta('tr', 'Türkçe', '🇹🇷'),
  _LangMeta('es', 'Español', '🇪🇸'),
  _LangMeta('it', 'Italiano', '🇮🇹'),
  _LangMeta('fr', 'Français', '🇫🇷'),
  _LangMeta('zh', '中文', '🇨🇳'),
  _LangMeta('ja', '日本語', '🇯🇵'),
  _LangMeta('ko', '한국어', '🇰🇷'),
  _LangMeta('ar', 'العربية', '🇸🇦'),
  _LangMeta('ru', 'Русский', '🇷🇺'),
];
