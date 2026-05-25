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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Heart — centered, with side padding
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
              child: FadeSlideIn(
                child: Center(child: _PulsingHeart(color: cs.primary)),
              ),
            ),

            // ── ECG — edge to edge, no horizontal padding
            FadeSlideIn(
              delay: const Duration(milliseconds: 25),
              child: _EcgLine(color: cs.primary),
            ),

            const SizedBox(height: 18),

            // ── Rest of content with side padding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Title
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Text(
                        l.welcomeReady,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 85),
                      child: Text(
                        l.welcomeDescription,
                        style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Feature grid 2×2
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.edit_note_rounded,
                              color: cs.primary,
                              label: l.welcomeTile1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.monitor_heart_outlined,
                              color: const Color(0xFFE53935),
                              label: l.welcomeTile2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 155),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.lock_outline_rounded,
                              color: const Color(0xFF2E7D32),
                              label: l.welcomeTile3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FeatureCard(
                              icon: Icons.cloud_done_outlined,
                              color: const Color(0xFF1565C0),
                              label: l.welcomeTile4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Start button
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 210),
                      child: SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _loading ? null : _requestAndContinue,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white)),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.favorite_rounded,
                                        size: 18),
                                    const SizedBox(width: 10),
                                    Text(l.welcomeStartSurvey),
                                  ],
                                ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Feature card (one of 4 in 2×2 grid)
// ─────────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _FeatureCard(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pulsing heart with expanding glow rings
// ─────────────────────────────────────────────────────────────────
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
  late final Animation<double> _r1Size;
  late final Animation<double> _r1Alpha;
  late final Animation<double> _r2Size;
  late final Animation<double> _r2Alpha;
  late final Animation<double> _glowAlpha;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.22)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.22, end: 0.93)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 58,
      ),
    ]).animate(_ctrl);

    _r1Size = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.72, curve: Curves.easeOut)),
    );
    _r1Alpha = Tween(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.0, 0.72)),
    );
    _r2Size = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.22, 1.0, curve: Curves.easeOut)),
    );
    _r2Alpha = Tween(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.22, 1.0)),
    );
    _glowAlpha = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.14, end: 0.28)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 22),
      TweenSequenceItem(
          tween: Tween(begin: 0.28, end: 0.10)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.10, end: 0.14)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 58),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const heartSize = 58.0;
    const maxRing1Extra = 32.0;
    const maxRing2Extra = 48.0;
    const boxSize = heartSize + maxRing2Extra * 2 + 4;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final r1 = heartSize + maxRing1Extra * _r1Size.value;
        final r2 = heartSize + maxRing2Extra * _r2Size.value;
        return SizedBox(
          width: boxSize,
          height: boxSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: r2,
                height: r2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: _r2Alpha.value),
                    width: 1.2,
                  ),
                ),
              ),
              // Inner ring
              Container(
                width: r1,
                height: r1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: _r1Alpha.value),
                    width: 1.8,
                  ),
                ),
              ),
              // Radial glow behind heart
              Container(
                width: heartSize + 18,
                height: heartSize + 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: _glowAlpha.value),
                      widget.color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // Heart
              Transform.scale(
                scale: _scale.value,
                child: Icon(
                  Icons.favorite_rounded,
                  size: heartSize,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Animated ECG line
// ─────────────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 2000),
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
      height: 46,
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
    (0.08, 0.00),
    (0.12, 0.16),
    (0.16, 0.00),
    (0.20, 0.00),
    (0.24, -0.16),
    (0.28, 0.00),
    (0.31, 1.00),
    (0.34, -0.32),
    (0.38, 0.00),
    (0.43, 0.00),
    (0.48, 0.22),
    (0.55, 0.22),
    (0.60, 0.00),
    (1.00, 0.00),
  ];

  Path _buildFullPath(Size size) {
    final cy = size.height / 2;
    final amp = size.height * 0.46;
    final path = Path();
    path.moveTo(
        _waypoints[0].$1 * size.width, cy - _waypoints[0].$2 * amp);
    for (int i = 1; i < _waypoints.length; i++) {
      path.lineTo(
          _waypoints[i].$1 * size.width, cy - _waypoints[i].$2 * amp);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildFullPath(size);
    final metrics = path.computeMetrics().first;
    final total = metrics.length;

    // Ghost trail
    final ghostPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, ghostPaint);

    final headDist = total * progress;
    final tailDist = (headDist - total * 0.30).clamp(0.0, total);

    if (headDist > 0) {
      final activePath = metrics.extractPath(tailDist, headDist);

      // Soft shadow under the active line
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.22)
        ..strokeWidth = 5.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(activePath, shadowPaint);

      // Active line
      final activePaint = Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(activePath, activePaint);
    }

    // Leading dot
    if (headDist > 0 && headDist < total) {
      final t = metrics.getTangentForOffset(
          math.min(headDist, total - 0.1));
      if (t != null) {
        // Outer glow
        canvas.drawCircle(
          t.position,
          8,
          Paint()
            ..color = color.withValues(alpha: 0.20)
            ..maskFilter =
                const MaskFilter.blur(BlurStyle.normal, 6),
        );
        // Mid glow
        canvas.drawCircle(
          t.position,
          4.5,
          Paint()..color = color.withValues(alpha: 0.45),
        );
        // Solid dot
        canvas.drawCircle(
          t.position,
          2.8,
          Paint()..color = color,
        );
        // White highlight
        canvas.drawCircle(
          t.position - const Offset(0.7, 0.7),
          1.0,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────
// HeaLife logo in AppBar
// ─────────────────────────────────────────────────────────────────
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
