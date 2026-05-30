import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_photo_service.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'account_settings_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
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
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;
  File? _photo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = SupabaseService().currentUser?.id ?? '';
    final results = await Future.wait([
      SupabaseService().getProfile(),
      ProfilePhotoService.load(userId),
    ]);
    if (mounted) {
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _photo = results[1] as File?;
      });
    }
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: cs.error, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(l.signOut)),
          ],
        ),
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.goBack),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: Text(l.signOut, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          AppPageRoute(page: LoginScreen(settings: widget.settings)),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(l.settingsTitle)),
      body: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
                            FadeSlideIn(
                child: _ProfileCard(
                  profile: _profile,
                  photo: _photo,
                  l: l,
                  cs: cs,
                  tt: tt,
                  onReturn: _loadProfile,
                ),
              ),
              const SizedBox(height: 28),

                            FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: _SectionLabel(
                    label: l.appearance,
                    icon: Icons.palette_outlined,
                    cs: cs,
                    tt: tt),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: _ThemeSelector(
                  settings: widget.settings,
                  l: l,
                  cs: cs,
                ),
              ),
              const SizedBox(height: 28),

              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: _SectionLabel(
                    label: l.textSize,
                    icon: Icons.text_fields_rounded,
                    cs: cs,
                    tt: tt),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: _TextSizeCard(settings: widget.settings, cs: cs, tt: tt),
              ),
              const SizedBox(height: 28),

                            FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _SectionLabel(
                    label: l.language,
                    icon: Icons.language_rounded,
                    cs: cs,
                    tt: tt),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _LanguageCard(
                  settings: widget.settings,
                  tt: tt,
                  cs: cs,
                ),
              ),
              const SizedBox(height: 36),

                            FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: Icon(Icons.logout_rounded, color: cs.error, size: 20),
                    label: Text(
                      l.signOut,
                      style: TextStyle(
                          color: cs.error, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: cs.error.withValues(alpha: 0.5), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
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

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final File? photo;
  final AppLocalizations l;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onReturn;

  const _ProfileCard(
      {required this.profile,
      required this.photo,
      required this.l,
      required this.cs,
      required this.tt,
      required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final firstName = profile?['first_name'] as String? ?? '';
    final lastName = profile?['last_name'] as String? ?? '';
    final participantId = profile?['participant_id'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        AppPageRoute(page: const AccountSettingsScreen()),
      ).then((_) => onReturn()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: cs.primary.withValues(alpha: 0.18), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: photo == null ? cs.primary : null,
                shape: BoxShape.circle,
              ),
              child: photo != null
                  ? ClipOval(
                      child: Image.file(photo!, key: ValueKey(photo!.lastModifiedSync().millisecondsSinceEpoch), width: 52, height: 52, fit: BoxFit.cover),
                    )
                  : Center(
                      child: initials.isNotEmpty
                          ? Text(initials,
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ))
                          : Icon(Icons.person_rounded, color: cs.onPrimary, size: 24),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isNotEmpty ? fullName : l.account,
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (participantId.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      participantId,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${l.firstName}, ${l.lastName}...',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.primary.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;
  final TextTheme tt;

  const _SectionLabel(
      {required this.label,
      required this.icon,
      required this.cs,
      required this.tt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final SettingsService settings;
  final AppLocalizations l;
  final ColorScheme cs;

  const _ThemeSelector(
      {required this.settings, required this.l, required this.cs});

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemeMode.system, Icons.brightness_auto_rounded, l.themeSystem),
      (ThemeMode.light, Icons.light_mode_rounded, l.themeLight),
      (ThemeMode.dark, Icons.dark_mode_rounded, l.themeDark),
    ];

    return Row(
      children: List.generate(options.length, (i) {
        final (mode, icon, label) = options[i];
        final selected = settings.themeMode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => settings.setThemeMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primaryContainer
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? Border.all(
                          color: cs.primary.withValues(alpha: 0.45),
                          width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color:
                          selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final SettingsService settings;
  final TextTheme tt;
  final ColorScheme cs;

  const _LanguageCard(
      {required this.settings, required this.tt, required this.cs});

  static const _languages = SettingsScreen._languages;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: cs.surfaceContainerLow,
        child: Column(
          children: List.generate(_languages.length, (i) {
            final lang = _languages[i];
            final isSelected = lang.code.isEmpty
                ? settings.locale == null
                : settings.locale?.languageCode == lang.code;
            final displayName =
                lang.code.isEmpty ? l.languageSystem : lang.name;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  leading:
                      Text(lang.flag, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    displayName,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: cs.primary, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded,
                              size: 14, color: cs.onPrimary),
                        )
                      : null,
                  onTap: () => settings.setLocale(
                      lang.code.isEmpty ? null : Locale(lang.code)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _TextSizeCard extends StatelessWidget {
  final SettingsService settings;
  final ColorScheme cs;
  final TextTheme tt;

  const _TextSizeCard({required this.settings, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    final scale = settings.textScale;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text('A', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: scale,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                onChanged: (v) => settings.setTextScale(v),
              ),
            ),
            const SizedBox(width: 8),
            Text('A', style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              iconSize: 20,
              tooltip: 'Reset',
              color: cs.onSurfaceVariant,
              onPressed: scale == 1.0 ? null : () => settings.setTextScale(1.0),
            ),
          ],
        ),
      ),
    );
  }
}
