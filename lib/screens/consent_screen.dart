import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'welcome_screen.dart';

class ConsentScreen extends StatefulWidget {
  final SettingsService settings;
  const ConsentScreen({super.key, required this.settings});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(l.consentTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FadeSlideIn(
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_outlined, size: 40, color: cs.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 30),
                  child: Text(l.appTitle,
                      textAlign: TextAlign.center,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 50),
                  child: Text(l.consentSubtitle,
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _Section(icon: Icons.info_outline_rounded, title: l.consentPurposeTitle, body: l.consentPurposeBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 110),
                  child: _Section(icon: Icons.lock_outline_rounded, title: l.consentDataTitle, body: l.consentDataBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: _Section(icon: Icons.bar_chart_rounded, title: l.consentUsageTitle, body: l.consentUsageBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 170),
                  child: _Section(icon: Icons.phone_iphone_rounded, title: l.consentPermissionsTitle, body: l.consentPermissionsBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _Section(icon: Icons.gavel_rounded, title: l.consentRightsTitle, body: l.consentRightsBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 230),
                  child: _Section(icon: Icons.mail_outline_rounded, title: l.consentContactTitle, body: l.consentContactBody),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: Card(
                    child: CheckboxListTile(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      title: Text(l.consentCheckbox),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _agreed
                      ? () async {
                          final userId = SupabaseService().currentUser?.id;
                          if (userId != null) {
                            await Future.wait([
                              SettingsService.saveConsent(userId),
                              SupabaseService().markConsentGiven(),
                            ]);
                          }
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            AppPageRoute(
                              page: WelcomeScreen(settings: widget.settings),
                            ),
                          );
                        }
                      : null,
                  child: Text(l.consentAgree),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(l.consentDeclineTitle),
                      content: Text(l.consentDeclineMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l.goBack),
                        ),
                      ],
                    ),
                  ),
                  child: Text(l.consentDecline,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 12, top: 1),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: cs.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    )),
                const SizedBox(height: 4),
                Text(body, style: tt.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
