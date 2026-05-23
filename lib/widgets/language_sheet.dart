import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class LanguageSheet extends StatelessWidget {
  final SettingsService settings;
  const LanguageSheet({super.key, required this.settings});

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

  static void show(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LanguageSheet(settings: settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _languages.length,
                itemBuilder: (_, i) {
                  final lang = _languages[i];
                  final isSelected = lang.code.isEmpty
                      ? settings.locale == null
                      : settings.locale?.languageCode == lang.code;
                  return ListTile(
                    leading: Text(lang.flag,
                        style: const TextStyle(fontSize: 22)),
                    title: Text(lang.name),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: cs.primary)
                        : null,
                    onTap: () {
                      settings.setLocale(
                          lang.code.isEmpty ? null : Locale(lang.code));
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
