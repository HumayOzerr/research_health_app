import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/supabase_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/soft_field.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      await SupabaseService().sendPasswordResetOtp(email);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppPageRoute(page: ResetPasswordScreen(email: email)),
      );
    } on AuthException catch (e) {
      final l = AppLocalizations.of(context);
      final msg = e.message.toLowerCase();
      setState(() => _error = msg.contains('security purposes') || msg.contains('rate limit') || msg.contains('after')
          ? l.errorRateLimit
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                    height: 180,
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_reset_rounded,
                                  size: 56, color: onPrimary),
                              const SizedBox(height: 10),
                              Text(
                                l.forgotPassword,
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
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
                        28,
                        32,
                        28,
                        MediaQuery.of(context).viewInsets.bottom + 32,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l.forgotPassword,
                              textAlign: TextAlign.center,
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.forgotPasswordBody,
                              textAlign: TextAlign.center,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 28),
                            SoftField(
                              controller: _emailCtrl,
                              label: l.emailAddress,
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return l.emailInvalid;
                                }
                                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(v.trim());
                                return ok ? null : l.emailInvalid;
                              },
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
                              onPressed: _loading ? null : _send,
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
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(l.sendResetCode,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l.goBack),
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
      ),
    );
  }
}
