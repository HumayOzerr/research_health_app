import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_photo_service.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_page_route.dart';
import '../widgets/soft_field.dart';
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
  final _heightCtrl = TextEditingController();
  String? _ageRange;
  String? _gender;
  File? _photo;
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
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_outlined, color: cs.primary),
                ),
                title: Text(l.photoFromGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: cs.primary),
                ),
                title: Text(l.photoFromCamera),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              if (_photo != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: cs.error),
                  ),
                  title: Text(l.removePhoto, style: TextStyle(color: cs.error)),
                  onTap: () => Navigator.pop(ctx, null),
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (source == null && _photo != null) {
      await ProfilePhotoService.delete();
      setState(() => _photo = null);
    } else if (source != null) {
      try {
        final file = await ProfilePhotoService.pick(source: source);
        if (file != null && mounted) setState(() => _photo = file);
      } on PhotoPermissionDeniedException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).photoPermissionDenied),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      setState(() => _genderError = true);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService().signUp(
        participantId: _idCtrl.text.trim().toUpperCase(),
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        gender: _gender!,
        ageRange: _ageRange,
        heightCm: int.tryParse(_heightCtrl.text.trim()),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppPageRoute(page: ConsentScreen(settings: SettingsService())),
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
                      Positioned(
                        top: 4,
                        left: 4,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_rounded,
                              color: onPrimary.withValues(alpha: 0.8)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_rounded, size: 56, color: onPrimary),
                            const SizedBox(height: 10),
                            Text(
                              l.signUp,
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
                          // ── Optional profile photo ────────────
                          Center(
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _photo == null
                                          ? cs.surfaceContainerHighest
                                          : null,
                                      border: Border.all(
                                        color: cs.primary.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: _photo != null
                                        ? ClipOval(
                                            child: Image.file(
                                              _photo!,
                                              width: 88,
                                              height: 88,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person_outline_rounded,
                                            size: 40,
                                            color: cs.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: cs.surface, width: 2),
                                    ),
                                    child: Icon(Icons.camera_alt_rounded,
                                        size: 13, color: cs.onPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 18),
                            child: Center(
                              child: Text(
                                l.addPhoto,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          SoftField(
                            controller: _idCtrl,
                            label: l.participantId,
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l.participantIdError
                                : null,
                          ),
                          const SizedBox(height: 14),
                          SoftField(
                            controller: _firstNameCtrl,
                            label: l.firstName,
                            icon: Icons.person_outlined,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l.firstNameError
                                : null,
                          ),
                          const SizedBox(height: 14),
                          SoftField(
                            controller: _lastNameCtrl,
                            label: l.lastName,
                            icon: Icons.person_outlined,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l.lastNameError
                                : null,
                          ),
                          const SizedBox(height: 14),
                          SoftField(
                            controller: _heightCtrl,
                            label: l.heightCm,
                            icon: Icons.height_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final n = int.tryParse(v?.trim() ?? '');
                              return (n == null || n < 100 || n > 250)
                                  ? l.heightError
                                  : null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _GenderSelector(
                            selected: _gender,
                            hasError: _genderError,
                            onSelected: (v) =>
                                setState(() {
                                  _gender = v;
                                  _genderError = false;
                                }),
                            l: l,
                            cs: cs,
                          ),
                          const SizedBox(height: 14),
                          _SoftDropdown(
                            value: _ageRange,
                            label: l.ageRange,
                            icon: Icons.cake_outlined,
                            items: _ageRanges,
                            onChanged: (v) => setState(() => _ageRange = v),
                            validator: (v) => v == null ? l.ageRangeError : null,
                            cs: cs,
                            tt: tt,
                          ),
                          const SizedBox(height: 14),
                          SoftField(
                            controller: _passwordCtrl,
                            label: l.password,
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
                            onPressed: _loading ? null : _register,
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
                                : Text(l.signUp,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l.haveAccount),
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

class _SoftDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final ColorScheme cs;
  final TextTheme tt;

  const _SoftDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final radius = BorderRadius.circular(18);

    return DropdownButtonFormField<String>(
      initialValue: value,
      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: tt.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      items: items
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
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
    final fillColor = cs.surfaceContainerHighest.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(18),
            border: hasError
                ? Border.all(color: cs.error, width: 1.5)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wc_rounded, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(
                    l.gender,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: hasError ? cs.error : cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.map((opt) {
                  final (code, icon) = opt;
                  final isSelected = selected == code;
                  return ChoiceChip(
                    avatar: Icon(icon,
                        size: 16,
                        color: isSelected
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant),
                    label: Text(_label(code, l)),
                    selected: isSelected,
                    onSelected: (_) => onSelected(code),
                  );
                }).toList(),
              ),
            ],
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
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
