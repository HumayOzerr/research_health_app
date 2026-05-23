import 'dart:math' as math;

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
        title: _HeaLifeTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: l.pastSubmissions,
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: l.settingsTitle,
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
                child: _PulsingHeart(color: cs.primary),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 30),
                child: _EcgLine(color: cs.primary),
              ),
              const SizedBox(height: 8),
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

class _PulsingHeart extends StatefulWidget {
  final Color color;
  const _PulsingHeart({required this.color});

  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.26)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.26, end: 0.92)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 48,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, _) => Transform.scale(
        scale: _scale.value,
        child: Icon(Icons.favorite_rounded, size: 72, color: widget.color),
      ),
    );
  }
}

class _EcgLine extends StatefulWidget {
  final Color color;
  const _EcgLine({required this.color});

  @override
  State<_EcgLine> createState() => _EcgLineState();
}

class _EcgLineState extends State<_EcgLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => CustomPaint(
            painter: _EcgPainter(
              progress: _ctrl.value,
              color: widget.color,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _EcgPainter({required this.progress, required this.color});

  static const _waypoints = [
    (0.00, 0.00),
    (0.10, 0.00),
    (0.14, 0.13),
    (0.18, 0.00),
    (0.22, 0.00),
    (0.26, -0.13),
    (0.30, 0.00),
    (0.33,  1.00),
    (0.36, -0.28),
    (0.40,  0.00),
    (0.45,  0.00),
    (0.50,  0.18),
    (0.56,  0.18),
    (0.61,  0.00),
    (1.00,  0.00),
  ];

  Path _buildFullPath(Size size) {
    final cy = size.height / 2;
    final amp = size.height * 0.44;
    final path = Path();
    path.moveTo(_waypoints[0].$1 * size.width, cy - _waypoints[0].$2 * amp);
    for (int i = 1; i < _waypoints.length; i++) {
      path.lineTo(_waypoints[i].$1 * size.width, cy - _waypoints[i].$2 * amp);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildFullPath(size);
    final metrics = path.computeMetrics().first;
    final total = metrics.length;

    final ghostPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, ghostPaint);

    final headDist = total * progress;
    final tailDist = (headDist - total * 0.32).clamp(0.0, total);

    if (headDist > 0) {
      final activePath = metrics.extractPath(tailDist, headDist);
      final activePaint = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(activePath, activePaint);
    }

    if (headDist > 0 && headDist < total) {
      final t = metrics.getTangentForOffset(math.min(headDist, total - 0.1));
      if (t != null) {
        canvas.drawCircle(
          t.position,
          3.5,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(t.position, 2.2, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.progress != progress;
}

class _HeaLifeTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monitor_heart_outlined, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hea',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: cs.primary,
                  letterSpacing: 0.2,
                ),
              ),
              TextSpan(
                text: 'Life',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
