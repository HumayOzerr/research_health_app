import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'consent_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  String? _ageRange;
  String? _gender;
  bool _genderError = false;

  static const _ageRanges = ['18–24', '25–34', '35–44', '45–54', '55–64', '65+'];
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;
  String _password = '';

  bool get _hasLength => _password.length >= 8;
  bool get _hasUpper => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _password.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  bool get _passwordValid =>
      _hasLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      setState(() => _genderError = true);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await SupabaseService().signUp(
        participantId: _idCtrl.text.trim().toUpperCase(),
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _gender!,
        ageRange: _ageRange,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppPageRoute(
          page: ConsentScreen(settings: SettingsService()),
        ),
      );
    } on AuthException catch (e) {
      final l = AppLocalizations.of(context);
      final msg = e.message.toLowerCase();
      setState(() => _error = msg.contains('already') || msg.contains('exists')
          ? l.errorUserExists
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
      appBar: AppBar(title: Text(l.signUp)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
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
                  delay: const Duration(milliseconds: 60),
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    decoration: InputDecoration(
                      labelText: l.firstName,
                      prefixIcon: const Icon(Icons.person_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.firstNameError : null,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    decoration: InputDecoration(
                      labelText: l.lastName,
                      prefixIcon: const Icon(Icons.person_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.lastNameError : null,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: _GenderSelector(
                    selected: _gender,
                    hasError: _genderError,
                    onSelected: (v) =>
                        setState(() { _gender = v; _genderError = false; }),
                    l: l,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 95),
                  child: DropdownButtonFormField<String>(
                    initialValue: _ageRange,
                    decoration: InputDecoration(
                      labelText: l.ageRange,
                      prefixIcon: const Icon(Icons.cake_outlined),
                    ),
                    items: _ageRanges
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _ageRange = v),
                    validator: (v) => v == null ? l.ageRangeError : null,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    onChanged: (v) => setState(() => _password = v),
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
                        !_passwordValid ? l.passwordError : null,
                  ),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _PasswordChecklist(
                    hasLength: _hasLength,
                    hasUpper: _hasUpper,
                    hasLower: _hasLower,
                    hasDigit: _hasDigit,
                    hasSpecial: _hasSpecial,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: l.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) =>
                        v != _passwordCtrl.text ? l.confirmPasswordError : null,
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
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onErrorContainer)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: FilledButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l.signUp),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.haveAccount),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String? selected;
  final bool hasError;
  final ValueChanged<String> onSelected;
  final AppLocalizations l;
  final ColorScheme cs;

  const _GenderSelector({
    required this.selected,
    required this.hasError,
    required this.onSelected,
    required this.l,
    required this.cs,
  });

  static const _options = [
    ('male', Icons.male_rounded),
    ('female', Icons.female_rounded),
    ('other', Icons.people_outline_rounded),
    ('prefer_not_to_say', Icons.do_not_disturb_alt_outlined),
  ];

  String _label(String code, AppLocalizations l) => switch (code) {
        'male' => l.genderMale,
        'female' => l.genderFemale,
        'other' => l.genderOther,
        _ => l.genderPreferNotToSay,
      };

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? cs.error : cs.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.gender,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: hasError ? cs.error : cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((opt) {
              final (code, icon) = opt;
              final isSelected = selected == code;
              return ChoiceChip(
                avatar: Icon(icon,
                    size: 16,
                    color: isSelected ? cs.onSecondaryContainer : cs.onSurfaceVariant),
                label: Text(_label(code, l)),
                selected: isSelected,
                onSelected: (_) => onSelected(code),
              );
            }).toList(),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(l.genderError,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.error)),
          ),
        ],
      ],
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  final bool hasLength;
  final bool hasUpper;
  final bool hasLower;
  final bool hasDigit;
  final bool hasSpecial;

  const _PasswordChecklist({
    required this.hasLength,
    required this.hasUpper,
    required this.hasLower,
    required this.hasDigit,
    required this.hasSpecial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Item(met: hasLength, label: 'At least 8 characters'),
        _Item(met: hasUpper, label: 'At least one uppercase letter (A–Z)'),
        _Item(met: hasLower, label: 'At least one lowercase letter (a–z)'),
        _Item(met: hasDigit, label: 'At least one number (0–9)'),
        _Item(met: hasSpecial, label: 'At least one special character (!@#\$...)'),
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
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
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
