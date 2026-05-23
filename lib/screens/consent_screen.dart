import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
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
      appBar: AppBar(title: Text(l.consentTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FadeSlideIn(
                  child: Text(l.appTitle,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
                  child: Text(l.consentSubtitle,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _Section(title: l.consentPurposeTitle, body: l.consentPurposeBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _Section(title: l.consentDataTitle, body: l.consentDataBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _Section(title: l.consentUsageTitle, body: l.consentUsageBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _Section(title: l.consentPermissionsTitle, body: l.consentPermissionsBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: _Section(title: l.consentRightsTitle, body: l.consentRightsBody),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 280),
                  child: _Section(title: l.consentContactTitle, body: l.consentContactBody),
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
                      ? () => Navigator.pushReplacement(
                            context,
                            AppPageRoute(
                              page: WelcomeScreen(settings: widget.settings),
                            ),
                          )
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
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              )),
          const SizedBox(height: 6),
          Text(body, style: tt.bodyMedium),
        ],
      ),
    );
  }
}
