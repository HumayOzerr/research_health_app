import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/supabase_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/soft_field.dart';
import 'login_screen.dart';
import '../services/settings_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;
  String _password = '';

  bool get _hasLength => _password.length >= 8;
  bool get _hasUpper => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _password.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  bool get _passwordValid =>
      _hasLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService().verifyPasswordResetOtp(widget.email, _codeCtrl.text);
      await SupabaseService().updatePassword(_passwordCtrl.text);
      await SupabaseService().signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).passwordResetSuccess),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pushAndRemoveUntil(
        context,
        AppPageRoute(page: LoginScreen(settings: SettingsService())),
        (_) => false,
      );
    } on AuthException catch (e) {
      final l = AppLocalizations.of(context);
      final msg = e.message.toLowerCase();
      setState(() => _error = msg.contains('same') || msg.contains('different') || msg.contains('should be different')
          ? l.errorSamePassword
          : msg.contains('security purposes') || msg.contains('rate limit') || msg.contains('after')
              ? l.errorRateLimit
              : msg.contains('invalid') || msg.contains('expired') || msg.contains('token') || msg.contains('otp')
                  ? l.verificationCode
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
                              Icon(Icons.verified_user_rounded,
                                  size: 56, color: onPrimary),
                              const SizedBox(height: 10),
                              Text(
                                l.resetPassword,
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
                              l.resetPassword,
                              textAlign: TextAlign.center,
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant),
                                children: [
                                  TextSpan(text: '${l.codeSentTo} '),
                                  TextSpan(
                                    text: widget.email,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: cs.primary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            SoftField(
                              controller: _codeCtrl,
                              label: l.verificationCode,
                              icon: Icons.pin_outlined,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? l.verificationCode
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            SoftField(
                              controller: _passwordCtrl,
                              label: l.newPassword,
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.next,
                              onChanged: (v) => setState(() => _password = v),
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
                                  !_passwordValid ? l.passwordError : null,
                            ),
                            const SizedBox(height: 8),
                            _PasswordChecklist(
                              hasLength: _hasLength,
                              hasUpper: _hasUpper,
                              hasLower: _hasLower,
                              hasDigit: _hasDigit,
                              hasSpecial: _hasSpecial,
                              l: l,
                            ),
                            const SizedBox(height: 14),
                            SoftField(
                              controller: _confirmCtrl,
                              label: l.confirmPassword,
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: cs.onSurfaceVariant,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (v) => v != _passwordCtrl.text
                                  ? l.confirmPasswordError
                                  : null,
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
                              onPressed: _loading ? null : _reset,
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
                                  : Text(l.resetPassword,
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

class _PasswordChecklist extends StatelessWidget {
  final bool hasLength;
  final bool hasUpper;
  final bool hasLower;
  final bool hasDigit;
  final bool hasSpecial;
  final AppLocalizations l;

  const _PasswordChecklist({
    required this.hasLength,
    required this.hasUpper,
    required this.hasLower,
    required this.hasDigit,
    required this.hasSpecial,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Item(met: hasLength, label: l.passwordRuleLength),
        _Item(met: hasUpper, label: l.passwordRuleUppercase),
        _Item(met: hasLower, label: l.passwordRuleLowercase),
        _Item(met: hasDigit, label: l.passwordRuleDigit),
        _Item(met: hasSpecial, label: l.passwordRuleSpecial),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final bool met;
  final String label;

  const _Item({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = met ? Colors.green : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(met),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}
