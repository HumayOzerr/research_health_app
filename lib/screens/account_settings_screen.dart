import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/supabase_service.dart';
import '../widgets/fade_slide_in.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();

  String? _ageRange;
  String? _gender;
  bool _loading = true;
  bool _saving = false;

  static const _ageRanges = [
    '18–24',
    '25–34',
    '35–44',
    '45–54',
    '55–64',
    '65+'
  ];

  static const _genderOptions = [
    ('male', Icons.male_rounded),
    ('female', Icons.female_rounded),
    ('other', Icons.people_outline_rounded),
    ('prefer_not_to_say', Icons.do_not_disturb_alt_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService().getProfile();
      if (mounted && profile != null) {
        setState(() {
          _firstNameCtrl.text = profile['first_name'] ?? '';
          _lastNameCtrl.text = profile['last_name'] ?? '';
          _idCtrl.text = profile['participant_id'] ?? '';
          _ageRange = profile['age_range'] as String?;
          _gender = profile['gender'] as String?;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await SupabaseService().updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        ageRange: _ageRange,
        gender: _gender,
        participantId: _idCtrl.text.trim().toUpperCase(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).profileUpdated),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).errorUnexpected),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  String _genderLabel(String code, AppLocalizations l) => switch (code) {
        'male' => l.genderMale,
        'female' => l.genderFemale,
        'other' => l.genderOther,
        _ => l.genderPreferNotToSay,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.account)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  FadeSlideIn(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: InputDecoration(
                        labelText: l.firstName,
                        prefixIcon: const Icon(Icons.person_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.firstNameError
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: InputDecoration(
                        labelText: l.lastName,
                        prefixIcon: const Icon(Icons.person_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.lastNameError
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: TextFormField(
                      controller: _idCtrl,
                      decoration: InputDecoration(
                        labelText: l.participantId,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.participantIdError
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: DropdownButtonFormField<String>(
                      initialValue: _ageRange,
                      decoration: InputDecoration(
                        labelText: l.ageRange,
                        prefixIcon: const Icon(Icons.cake_outlined),
                      ),
                      items: _ageRanges
                          .map((r) =>
                              DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (v) => setState(() => _ageRange = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.gender,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _genderOptions.map((opt) {
                            final (code, icon) = opt;
                            final isSelected = _gender == code;
                            return ChoiceChip(
                              avatar: Icon(icon,
                                  size: 16,
                                  color: isSelected
                                      ? cs.onSecondaryContainer
                                      : cs.onSurfaceVariant),
                              label: Text(_genderLabel(code, l)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _gender = code),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(l.saveChanges),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: OutlinedButton.icon(
                      onPressed: _openChangePassword,
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: Text(l.changePassword),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Change Password Sheet ─────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService().changePassword(_newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).passwordChanged),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context).errorUnexpected);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    l.changePassword,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: l.newPassword,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 8) ? l.passwordError : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
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
                  v != _newCtrl.text ? l.confirmPasswordError : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: TextStyle(color: cs.onErrorContainer)),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(l.changePassword),
            ),
          ],
        ),
      ),
    );
  }
}
