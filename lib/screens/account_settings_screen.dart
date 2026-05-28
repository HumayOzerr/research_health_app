import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_photo_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/soft_field.dart';

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
  final _heightCtrl = TextEditingController();

  String? _ageRange;
  String? _gender;
  File? _photo;
  bool _loading = true;
  bool _saving = false;

  static const _ageRanges = [
    '18–24', '25–34', '35–44', '45–54', '55–64', '65+'
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
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = SupabaseService().currentUser?.id ?? '';
      final results = await Future.wait([
        SupabaseService().getProfile(),
        ProfilePhotoService.load(userId),
      ]);
      if (mounted) {
        final profile = results[0] as Map<String, dynamic>?;
        final photo = results[1] as File?;
        setState(() {
          _photo = photo;
          if (profile != null) {
            _firstNameCtrl.text = profile['first_name'] ?? '';
            _lastNameCtrl.text = profile['last_name'] ?? '';
            _idCtrl.text = profile['participant_id'] ?? '';
            _ageRange = profile['age_range'] as String?;
            _gender = profile['gender'] as String?;
            final h = (profile['height_cm'] as num?)?.toInt();
            if (h != null) _heightCtrl.text = '$h';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      if (_photo != null) FileImage(_photo!).evict();
      await ProfilePhotoService.delete(SupabaseService().currentUser?.id ?? '');
      setState(() => _photo = null);
    } else if (source != null) {
      try {
        final file = await ProfilePhotoService.pick(source: source, userId: SupabaseService().currentUser?.id ?? '');
        if (file != null && mounted) {
          if (_photo != null) FileImage(_photo!).evict();
          FileImage(file).evict();
          setState(() => _photo = file);
        }
      } on PhotoPermissionDeniedException {
        if (!mounted) return;
        _showPermissionDenied();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorUnexpected),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPermissionDenied() {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.photoPermissionDenied),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      action: Platform.isIOS
          ? SnackBarAction(
              label: l.openSettings,
              onPressed: () => launchUrl(Uri.parse('app-settings:')),
            )
          : null,
    ));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final heightCm = int.tryParse(_heightCtrl.text.trim());
      await SupabaseService().updateProfile(
        firstName: _firstNameCtrl.text.trim().isEmpty
            ? null
            : _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim().isEmpty
            ? null
            : _lastNameCtrl.text.trim(),
        ageRange: _ageRange,
        gender: _gender,
        participantId: _idCtrl.text.trim().isEmpty
            ? null
            : _idCtrl.text.trim().toUpperCase(),
        heightCm: heightCm,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).profileUpdated),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  String _genderLabel(String code, AppLocalizations l) => switch (code) {
        'male' => l.genderMale,
        'female' => l.genderFemale,
        'other' => l.genderOther,
        _ => l.genderPreferNotToSay,
      };

  String get _initials {
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final la = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$la'.isEmpty ? '?' : '$f$la';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(l.account)),
      body: _loading
          ? const _AccountSkeletonLoader()
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                                        FadeSlideIn(
                      child: _AvatarHeader(
                        initials: _initials,
                        firstName: _firstNameCtrl.text.trim(),
                        lastName: _lastNameCtrl.text.trim(),
                        participantId: _idCtrl.text.trim(),
                        photo: _photo,
                        onTap: _pickPhoto,
                        cs: cs,
                        tt: tt,
                      ),
                    ),

                    const SizedBox(height: 28),

                                        FadeSlideIn(
                      delay: const Duration(milliseconds: 50),
                      child: _SectionLabel(
                        l.personalInfo,
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 65),
                      child: _FieldCard(
                        cs: cs,
                        children: [
                          SoftField(
                            controller: _firstNameCtrl,
                            label: l.firstName,
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          SoftField(
                            controller: _lastNameCtrl,
                            label: l.lastName,
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          SoftField(
                            controller: _idCtrl,
                            label: l.participantId,
                            icon: Icons.fingerprint_rounded,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                                        FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: _SectionLabel(
                        l.physicalInfo,
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 115),
                      child: _FieldCard(
                        cs: cs,
                        children: [
                          SoftField(
                            controller: _heightCtrl,
                            label: l.heightCm,
                            icon: Icons.height_rounded,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 100 || n > 250) {
                                return l.heightError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                                                    Text(
                            l.ageRange,
                            style: tt.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _ageRanges.map((range) {
                              final selected = _ageRange == range;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _ageRange = range),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? cs.primaryContainer
                                        : cs.surfaceContainerHighest
                                            .withValues(alpha: 0.5),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: selected
                                        ? Border.all(
                                            color: cs.primary
                                                .withValues(alpha: 0.5),
                                            width: 1.5)
                                        : null,
                                  ),
                                  child: Text(
                                    range,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selected
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                                        FadeSlideIn(
                      delay: const Duration(milliseconds: 130),
                      child: _SectionLabel(
                        l.gender,
                        icon: Icons.people_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 145),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3.0,
                        children: _genderOptions.map((opt) {
                          final (code, icon) = opt;
                          final isSelected = _gender == code;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _gender = code),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected
                                    ? Border.all(
                                        color: cs.primary
                                            .withValues(alpha: 0.45),
                                        width: 1.5)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _genderLabel(code, l),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? cs.primary
                                            : cs.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 36),

                                        FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Text(l.saveChanges,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 185),
                      child: OutlinedButton.icon(
                        onPressed: _openChangePassword,
                        icon: const Icon(Icons.lock_outline_rounded,
                            size: 18),
                        label: Text(l.changePassword),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final String initials;
  final String firstName;
  final String lastName;
  final String participantId;
  final File? photo;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  const _AvatarHeader({
    required this.initials,
    required this.firstName,
    required this.lastName,
    required this.participantId,
    required this.photo,
    required this.onTap,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = '$firstName $lastName'.trim();
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: photo == null
                        ? LinearGradient(
                            colors: [cs.primary, cs.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: photo != null
                      ? ClipOval(
                          child: Image.file(
                            photo!,
                            key: ValueKey(photo!.lastModifiedSync().millisecondsSinceEpoch),
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: tt.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  child: Icon(Icons.camera_alt_rounded,
                      size: 14, color: cs.onPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (fullName.isNotEmpty)
            Text(
              fullName,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          if (participantId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                participantId.toUpperCase(),
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, {required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  final List<Widget> children;
  final ColorScheme cs;

  const _FieldCard({required this.children, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  String _password = '';
  bool _codeSent = false;

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
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService().sendChangePasswordOtp();
      setState(() => _codeSent = true);
    } on AuthException catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        final msg = e.message.toLowerCase();
        setState(() => _error = msg.contains('security purposes') || msg.contains('rate limit') || msg.contains('after')
            ? l.errorRateLimit
            : l.errorUnexpected);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).errorUnexpected);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SupabaseService().changePasswordWithOtp(
        _newCtrl.text,
        _codeCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).passwordChanged),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on AuthException catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        final msg = e.message.toLowerCase();
        setState(() => _error = msg.contains('same') || msg.contains('different') || msg.contains('should be different')
            ? l.errorSamePassword
            : msg.contains('security purposes') || msg.contains('rate limit') || msg.contains('after')
                ? l.errorRateLimit
                : msg.contains('invalid') || msg.contains('expired') || msg.contains('token') || msg.contains('otp')
                    ? l.verificationCode
                    : l.errorUnexpected);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).errorUnexpected);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final email = SupabaseService().currentUser?.email ?? '';
    final hasRealEmail = !email.endsWith('@healthresearch.app');

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      size: 20, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Text(l.changePassword,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            if (!hasRealEmail) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: cs.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.noEmailLinked,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onErrorContainer)),
                    ),
                  ],
                ),
              ),
            ] else if (!_codeSent) ...[
              Text(l.changePasswordVerify,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(email,
                          style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _ErrorBox(message: _error!, cs: cs, tt: tt),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _sendCode,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l.sendResetCode,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              RichText(
                text: TextSpan(
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  children: [
                    TextSpan(text: '${l.codeSentTo} '),
                    TextSpan(
                      text: email,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: cs.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftField(
                controller: _codeCtrl,
                label: l.verificationCode,
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.verificationCode : null,
              ),
              const SizedBox(height: 12),
              SoftField(
                controller: _newCtrl,
                label: l.newPassword,
                icon: Icons.lock_outlined,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                onChanged: (v) => setState(() => _password = v),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (v) => !_passwordValid ? l.passwordError : null,
              ),
              const SizedBox(height: 8),
              _PwChecklist(
                hasLength: _hasLength,
                hasUpper: _hasUpper,
                hasLower: _hasLower,
                hasDigit: _hasDigit,
                hasSpecial: _hasSpecial,
                l: l,
              ),
              const SizedBox(height: 12),
              SoftField(
                controller: _confirmCtrl,
                label: l.confirmPassword,
                icon: Icons.lock_outlined,
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
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) =>
                    v != _newCtrl.text ? l.confirmPasswordError : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _ErrorBox(message: _error!, cs: cs, tt: tt),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l.changePassword,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final ColorScheme cs;
  final TextTheme tt;
  const _ErrorBox({required this.message, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            child: Text(message,
                style: tt.bodySmall?.copyWith(color: cs.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

class _PwChecklist extends StatelessWidget {
  final bool hasLength, hasUpper, hasLower, hasDigit, hasSpecial;
  final AppLocalizations l;

  const _PwChecklist({
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
        _PwItem(met: hasLength, label: l.passwordRuleLength),
        _PwItem(met: hasUpper, label: l.passwordRuleUppercase),
        _PwItem(met: hasLower, label: l.passwordRuleLowercase),
        _PwItem(met: hasDigit, label: l.passwordRuleDigit),
        _PwItem(met: hasSpecial, label: l.passwordRuleSpecial),
      ],
    );
  }
}

class _AccountSkeletonLoader extends StatefulWidget {
  const _AccountSkeletonLoader();

  @override
  State<_AccountSkeletonLoader> createState() => _AccountSkeletonLoaderState();
}

class _AccountSkeletonLoaderState extends State<_AccountSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final color = Color.lerp(
          cs.surfaceContainerLow,
          cs.surfaceContainerHighest,
          _anim.value,
        )!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  _SkeletonBox(width: 90, height: 90, radius: 45, color: color),
                  const SizedBox(height: 14),
                  _SkeletonBox(width: 140, height: 18, radius: 6, color: color),
                  const SizedBox(height: 8),
                  _SkeletonBox(width: 80, height: 22, radius: 11, color: color),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SkeletonBox(width: 120, height: 28, radius: 8, color: color),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _SkeletonBox(width: double.infinity, height: 52, radius: 12, color: color),
                  const SizedBox(height: 10),
                  _SkeletonBox(width: double.infinity, height: 52, radius: 12, color: color),
                  const SizedBox(height: 10),
                  _SkeletonBox(width: double.infinity, height: 52, radius: 12, color: color),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SkeletonBox(width: 120, height: 28, radius: 8, color: color),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: double.infinity, height: 52, radius: 12, color: color),
                  const SizedBox(height: 16),
                  _SkeletonBox(width: 80, height: 14, radius: 4, color: color),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _SkeletonBox(width: 64, height: 34, radius: 17, color: color),
                      const SizedBox(width: 8),
                      _SkeletonBox(width: 64, height: 34, radius: 17, color: color),
                      const SizedBox(width: 8),
                      _SkeletonBox(width: 64, height: 34, radius: 17, color: color),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SkeletonBox(width: 100, height: 28, radius: 8, color: color),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _SkeletonBox(width: double.infinity, height: 52, radius: 14, color: color)),
                const SizedBox(width: 10),
                Expanded(child: _SkeletonBox(width: double.infinity, height: 52, radius: 14, color: color)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _SkeletonBox(width: double.infinity, height: 52, radius: 14, color: color)),
                const SizedBox(width: 10),
                Expanded(child: _SkeletonBox(width: double.infinity, height: 52, radius: 14, color: color)),
              ],
            ),
            const SizedBox(height: 36),
            _SkeletonBox(width: double.infinity, height: 52, radius: 16, color: color),
          ],
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _PwItem extends StatelessWidget {
  final bool met;
  final String label;
  const _PwItem({required this.met, required this.label});

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
