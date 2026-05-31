import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/language_sheet.dart';
import 'consent_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  final SettingsService settings;
  const LoginScreen({super.key, required this.settings});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService().signIn(
        participantId: _idCtrl.text.trim().toUpperCase(),
        password: _passwordCtrl.text,
      );
      final userId = SupabaseService().currentUser?.id;
      bool consentGiven =
          userId != null && await SettingsService.checkConsent(userId);
      if (!consentGiven) {
        try {
          final profile = await SupabaseService().getProfile();
          consentGiven = (profile?['consent_given'] as bool?) ?? false;
          if (consentGiven && userId != null) {
            await SettingsService.saveConsent(userId);
          }
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppPageRoute(
          page: consentGiven
              ? WelcomeScreen(settings: widget.settings)
              : ConsentScreen(settings: widget.settings),
        ),
      );
    } on AuthException catch (e) {
      final l = AppLocalizations.of(context);
      final msg = e.message.toLowerCase();
      setState(() => _error =
          msg.contains('invalid') || msg.contains('credentials')
              ? l.errorInvalidCredentials
              : l.errorUnexpected);
    } catch (_) {
      final l = AppLocalizations.of(context);
      setState(() => _error = l.errorUnexpected);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final onPrimary = cs.onPrimary;
    final heroDark = Color.lerp(cs.primary, Colors.black, 0.28)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [heroDark, cs.primary],
              ),
            ),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 272,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Icon(Icons.language_rounded, color: onPrimary.withValues(alpha: 0.8)),
                          onPressed: () => LanguageSheet.show(context, widget.settings),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PulsingHeart(color: onPrimary),
                            const SizedBox(height: 4),
                            _EcgLine(color: onPrimary.withValues(alpha: 0.75)),
                            const SizedBox(height: 10),
                            Text(
                              l.appTitle,
                              style: tt.headlineMedium?.copyWith(
                                color: onPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SCI & AI Lab · ETH Zurich',
                              style: tt.labelMedium?.copyWith(
                                color: onPrimary.withValues(alpha: 0.65),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      28, 32, 28,
                      MediaQuery.of(context).viewInsets.bottom + 32,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.signIn,
                            textAlign: TextAlign.center,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _SoftField(
                            controller: _idCtrl,
                            label: l.participantIdOrEmail,
                            icon: Icons.badge_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l.participantIdError
                                : null,
                            cs: cs,
                            tt: tt,
                          ),
                          const SizedBox(height: 14),
                          _SoftField(
                            controller: _passwordCtrl,
                            label: l.password,
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? l.passwordError : null,
                            cs: cs,
                            tt: tt,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      size: 18, color: cs.onErrorContainer),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: tt.bodySmall?.copyWith(
                                            color: cs.onErrorContainer)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: _loading ? null : _login,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l.signIn,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              AppPageRoute(page: const RegisterScreen()),
                            ),
                            child: Text(l.noAccount),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              AppPageRoute(
                                  page: const ForgotPasswordScreen()),
                            ),
                            child: Text(l.forgotPassword,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
        child: Icon(Icons.favorite_rounded, size: 64, color: widget.color),
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
      height: 48,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => CustomPaint(
            painter: _EcgPainter(progress: _ctrl.value, color: widget.color),
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
    (0.33, 1.00),
    (0.36, -0.28),
    (0.40, 0.00),
    (0.45, 0.00),
    (0.50, 0.18),
    (0.56, 0.18),
    (0.61, 0.00),
    (1.00, 0.00),
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

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final headDist = total * progress;
    final tailDist = (headDist - total * 0.32).clamp(0.0, total);

    if (headDist > 0) {
      canvas.drawPath(
        metrics.extractPath(tailDist, headDist),
        Paint()
          ..color = color
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    if (headDist > 0 && headDist < total) {
      final t = metrics.getTangentForOffset(math.min(headDist, total - 0.1));
      if (t != null) {
        canvas.drawCircle(
          t.position,
          3.5,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(t.position, 2.2, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.progress != progress;
}

class _SoftField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ColorScheme cs;
  final TextTheme tt;

  const _SoftField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.cs,
    required this.tt,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final radius = BorderRadius.circular(18);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: tt.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
    );
  }
}
