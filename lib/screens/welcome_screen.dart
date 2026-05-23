import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/health_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'form_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final SettingsService settings;
  const WelcomeScreen({super.key, required this.settings});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _healthService = HealthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    ApiService().flushQueue();
  }

  Future<void> _requestAndContinue() async {
    setState(() => _loading = true);
    await _healthService.configure();
    final granted = await _healthService.requestPermissions();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      AppPageRoute(
        page: FormScreen(
          healthService: _healthService,
          healthGranted: granted,
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      AppPageRoute(
        page: HistoryScreen(
          healthService: _healthService,
          healthGranted: true,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      AppPageRoute(page: SettingsScreen(settings: widget.settings)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: l.pastSubmissions,
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: l.settings,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              FadeSlideIn(
                child: Icon(Icons.favorite_rounded, size: 72, color: cs.primary),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  l.welcomeReady,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  l.welcomeDescription,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _InfoTile(icon: Icons.edit_note_rounded, label: l.welcomeTile1),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: _InfoTile(icon: Icons.monitor_heart_outlined, label: l.welcomeTile2),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _InfoTile(icon: Icons.lock_outline_rounded, label: l.welcomeTile3),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: _InfoTile(icon: Icons.cloud_done_outlined, label: l.welcomeTile4),
              ),
              const Spacer(flex: 2),
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: FilledButton(
                  onPressed: _loading ? null : _requestAndContinue,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.welcomeStartSurvey),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: Text(
                  l.welcomeHealthNote,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
