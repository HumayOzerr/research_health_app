import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/language_sheet.dart';
import 'consent_screen.dart';
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
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService().signIn(
        participantId: _idCtrl.text.trim().toUpperCase(),
        password: _passwordCtrl.text,
      );
      final profile = await SupabaseService().getProfile();
      final consentGiven = (profile?['consent_given'] as bool?) ?? false;
      final userId = SupabaseService().currentUser?.id;
      if (consentGiven && userId != null) {
        await SettingsService.saveConsent(userId);
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
      setState(() => _error = msg.contains('invalid') || msg.contains('credentials')
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            onPressed: () => LanguageSheet.show(context, widget.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    child: Icon(Icons.favorite_rounded, size: 56, color: cs.primary),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      l.appTitle,
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      'Spinal Cord Injury & Artificial Intelligence Lab — ETH Zurich',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: TextFormField(
                      controller: _idCtrl,
                      decoration: InputDecoration(
                        labelText: l.participantId,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l.participantIdError : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l.password,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l.passwordError : null,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: tt.bodySmall?.copyWith(color: cs.onErrorContainer)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l.signIn),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        AppPageRoute(page: const RegisterScreen()),
                      ),
                      child: Text(l.noAccount),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
