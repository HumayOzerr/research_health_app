import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'form_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _healthService = HealthService();
  bool _loading = false;

  Future<void> _requestAndContinue() async {
    setState(() => _loading = true);

    await _healthService.configure();
    final granted = await _healthService.requestPermissions();

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormScreen(
          healthService: _healthService,
          healthGranted: granted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.favorite_rounded, size: 72, color: cs.primary),
              const SizedBox(height: 24),
              Text(
                'Health Research Study',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'This short survey collects a wellbeing self-report and today\'s step count from your device. Your data will be reviewed by the research team.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _InfoTile(
                icon: Icons.edit_note_rounded,
                label: 'A brief wellbeing questionnaire',
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.directions_walk_rounded,
                label: 'Today\'s step count from Health',
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.lock_outline_rounded,
                label: 'Data is only sent on your approval',
              ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: _loading ? null : _requestAndContinue,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Get Started'),
              ),
              const SizedBox(height: 12),
              Text(
                'Tapping "Get Started" will request access to Health data.',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
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
