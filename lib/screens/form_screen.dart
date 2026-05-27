import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../services/health_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'review_screen.dart';

class FormScreen extends StatefulWidget {
  final HealthService healthService;
  final bool healthGranted;

  const FormScreen({
    super.key,
    required this.healthService,
    required this.healthGranted,
  });

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _glucoseController = TextEditingController();

  String? _ageRange;
  bool _ageFromProfile = false;
  String? _gender;
  bool _showMenstrual = false;
  bool? _hasPeriod;
  DateTime? _lastPeriodStart;
  DateTime? _savedPeriodStart;
  bool _lastPeriodStartUpdated = false;
  int _rating = 3;
  int _sleepQuality = 3;
  int _neuropathicPain = 0;
  int _musculoskeletalPain = 0;
  String _participantId = '';
  bool _profileLoading = true;
  int? _heightCm;

  double? get _bloodGlucose {
    final v = double.tryParse(_glucoseController.text.replaceAll(',', '.'));
    if (v == null || v < 40 || v > 600) return null;
    return v;
  }

  double? get _weightKg {
    final v = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (v == null || v < 30 || v > 300) return null;
    return v;
  }

  int? get _effectiveHeightCm {
    if (_heightCm != null) return _heightCm;
    final v = int.tryParse(_heightController.text.trim());
    if (v == null || v < 100 || v > 250) return null;
    return v;
  }

  double? get _bmi {
    final w = _weightKg;
    final h = _effectiveHeightCm;
    if (w == null || h == null) return null;
    final hm = h / 100.0;
    return w / (hm * hm);
  }

  DateTime _selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    SupabaseService().getProfile().then((profile) {
      if (!mounted) return;
      setState(() {
        if (profile != null) {
          _participantId = (profile['participant_id'] as String?) ?? '';
          _gender = profile['gender'] as String?;
          _showMenstrual = _gender == 'female';
          final saved = profile['age_range'] as String?;
          if (saved != null) {
            _ageRange = saved;
            _ageFromProfile = true;
          }
          final lps = profile['last_period_start'] as String?;
          if (lps != null) _lastPeriodStart = DateTime.tryParse(lps);
          _savedPeriodStart = _lastPeriodStart;
          _heightCm = (profile['height_cm'] as num?)?.toInt();
        }
        _profileLoading = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _profileLoading = false);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate == DateTime(now.year, now.month, now.day);
  }

  int get _cycleDay {
    if (_lastPeriodStart == null) return 0;
    return _selectedDate.difference(_lastPeriodStart!).inDays + 1;
  }

  // True when the selected date is within an active/recent cycle (days 1–35)
  bool get _isContinuingCycle =>
      _lastPeriodStart != null && _cycleDay >= 1 && _cycleDay <= 35;

  // True when a new period entry is expected (no history or cycle too long)
  bool get _isNewCycleExpected =>
      _lastPeriodStart == null || _cycleDay < 1 || _cycleDay > 35;

  String _cyclePhase(int day) => switch (day) {
        <= 5 => 'menstrual',
        <= 13 => 'follicular',
        <= 16 => 'ovulatory',
        <= 28 => 'luteal',
        _ => 'late_luteal',
      };

  void _setPeriodStartFromBucket(String bucket) {
    _lastPeriodStart = switch (bucket) {
      '<7' => _selectedDate.subtract(const Duration(days: 4)),
      '8-14' => _selectedDate.subtract(const Duration(days: 11)),
      '15-21' => _selectedDate.subtract(const Duration(days: 18)),
      _ => _selectedDate.subtract(const Duration(days: 25)),
    };
    _lastPeriodStartUpdated = true;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    if (!_ageFromProfile && _ageRange != null) {
      SupabaseService().updateProfile(ageRange: _ageRange);
    }
    if (_lastPeriodStartUpdated && _lastPeriodStart != null) {
      SupabaseService().updateProfile(lastPeriodStart: _lastPeriodStart);
    }
    if (_heightCm == null && _effectiveHeightCm != null) {
      setState(() => _heightCm = _effectiveHeightCm);
      SupabaseService().client
          .from('profiles')
          .update({'height_cm': _effectiveHeightCm})
          .eq('id', SupabaseService().currentUser!.id);
    }
    final day = _cycleDay;
    Navigator.push(
      context,
      AppPageRoute(
        page: ReviewScreen(
          selectedDate: _selectedDate,
          healthService: widget.healthService,
          healthGranted: widget.healthGranted,
          participantId: _participantId,
          ageRange: _ageRange ?? '',
          gender: _gender,
          hasPeriod: _showMenstrual ? _hasPeriod : null,
          cycleDay: _showMenstrual && day >= 1 ? day : null,
          cyclePhase: _showMenstrual && day >= 1 ? _cyclePhase(day) : null,
          lastPeriodStart: _showMenstrual ? _lastPeriodStart : null,
          wellbeingRating: _rating,
          sleepQuality: _sleepQuality,
          neuropathicPain: _neuropathicPain,
          musculoskeletalPain: _musculoskeletalPain,
          comment: _commentController.text.trim(),
          weightKg: _weightKg,
          bmi: _bmi,
          bloodGlucoseMgdl: _bloodGlucose,
        ),
      ),
    );
  }

  InputDecoration _field({
    required String label,
    String? suffix,
    IconData? prefix,
    String? hint,
    bool alignHint = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      alignLabelWithHint: alignHint,
      prefixIcon: prefix != null
          ? Icon(prefix, size: 20, color: cs.onSurfaceVariant)
          : null,
      filled: true,
      fillColor: cs.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profileLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(title: AppBarTitle(l.formTitle)),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              // ── Date
              FadeSlideIn(
                child: _DateCard(
                  selectedDate: _selectedDate,
                  isToday: _isToday,
                  locale: locale,
                  onTap: _pickDate,
                  l: l,
                ),
              ),

              const SizedBox(height: 28),

              // ── Sleep quality
              FadeSlideIn(
                delay: const Duration(milliseconds: 70),
                child: _SectionHeader(
                  icon: Icons.bedtime_rounded,
                  color: const Color(0xFF5C6BC0),
                  title: l.sleepQuality,
                  subtitle: l.sleepQuestion,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 90),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: cs.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: _RatingSelector(
                      value: _sleepQuality,
                      onChanged: (v) => setState(() => _sleepQuality = v),
                      l: l,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Wellbeing
              FadeSlideIn(
                delay: const Duration(milliseconds: 110),
                child: _SectionHeader(
                  icon: Icons.self_improvement_rounded,
                  color: cs.primary,
                  title: l.wellbeingRating,
                  subtitle: l.wellbeingQuestion,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 130),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: cs.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: _RatingSelector(
                      value: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                      l: l,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Pain
              FadeSlideIn(
                delay: const Duration(milliseconds: 150),
                child: _SectionHeader(
                  icon: Icons.electric_bolt_rounded,
                  color: const Color(0xFFEF6C00),
                  title: l.painSection,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 170),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: cs.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PainCard(
                          title: l.neuropathicPain,
                          desc: l.neuropathicPainDesc,
                          value: _neuropathicPain,
                          onChanged: (v) =>
                              setState(() => _neuropathicPain = v),
                          l: l,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        _PainCard(
                          title: l.musculoskeletalPain,
                          desc: l.musculoskeletalPainDesc,
                          value: _musculoskeletalPain,
                          onChanged: (v) =>
                              setState(() => _musculoskeletalPain = v),
                          l: l,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Weight
              FadeSlideIn(
                delay: const Duration(milliseconds: 190),
                child: _SectionHeader(
                  icon: Icons.monitor_weight_outlined,
                  color: const Color(0xFF6D4C41),
                  title: l.weightSection,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 205),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: cs.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_heightCm == null) ...[
                          TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: _field(
                              label: l.heightCm,
                              suffix: 'cm',
                              prefix: Icons.straighten_rounded,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 100 || n > 250) {
                                return l.heightError;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _field(
                            label: l.weightKg,
                            suffix: 'kg',
                            prefix: Icons.monitor_weight_outlined,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final n =
                                double.tryParse(v.replaceAll(',', '.'));
                            if (n == null || n < 30 || n > 300) {
                              return l.weightError;
                            }
                            return null;
                          },
                        ),
                        if (_bmi != null) ...[
                          const SizedBox(height: 14),
                          _BmiDisplay(bmi: _bmi!, l: l),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Blood Glucose
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 210),
                child: _SectionHeader(
                  icon: Icons.bloodtype_rounded,
                  color: const Color(0xFFD81B60),
                  title: l.labelBloodGlucose,
                  subtitle: l.bloodGlucoseQuestion,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: cs.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextFormField(
                      controller: _glucoseController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _field(
                        label: l.labelBloodGlucose,
                        suffix: 'mg/dL',
                        prefix: Icons.bloodtype_rounded,
                        hint: l.bloodGlucoseHint,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n < 40 || n > 600) {
                          return l.bloodGlucoseError;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),

              // ── Menstrual
              if (_gender == 'female') ...[
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 215),
                  child: _SectionHeader(
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFFB71C1C),
                    title: l.menstrualHealth,
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 225),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: cs.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isContinuingCycle
                                      ? l.periodContinuesQuestion
                                      : _cycleDay > 35
                                          ? l.newPeriodQuestion
                                          : l.onPeriodQuestion,
                                  style: tt.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(
                                      value: true, label: Text(l.yes)),
                                  ButtonSegment(
                                      value: false, label: Text(l.no)),
                                ],
                                selected: _hasPeriod != null
                                    ? {_hasPeriod!}
                                    : {},
                                emptySelectionAllowed: true,
                                multiSelectionEnabled: false,
                                onSelectionChanged: (s) {
                                  setState(() {
                                    final prev = _hasPeriod;
                                    _hasPeriod =
                                        s.isEmpty ? null : s.first;
                                    if (_hasPeriod == true) {
                                      // Only reset the period start date when
                                      // it's genuinely a new cycle (no history,
                                      // selected date is before the recorded
                                      // start, or it's been > 35 days).
                                      if (_isNewCycleExpected) {
                                        _lastPeriodStart = DateTime(
                                            _selectedDate.year,
                                            _selectedDate.month,
                                            _selectedDate.day);
                                        _lastPeriodStartUpdated = true;
                                      }
                                      // Continuing cycle: hasPeriod = true
                                      // but keep existing _lastPeriodStart.
                                    } else if (prev == true &&
                                        _isNewCycleExpected) {
                                      // Reverted from a just-entered new cycle
                                      // — restore the saved start date.
                                      _lastPeriodStart = _savedPeriodStart;
                                      _lastPeriodStartUpdated = false;
                                    }
                                    // If prev was true and cycle is continuing,
                                    // keep lastPeriodStart as-is (period ended
                                    // mid-cycle; it stays for phase tracking).
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_hasPeriod == false &&
                              _lastPeriodStart == null) ...[
                            const SizedBox(height: 16),
                            Text(l.lastPeriodQuestion,
                                style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final (bucket, label) in [
                                  ('<7', l.lessThan7Days),
                                  ('8-14', l.days8to14),
                                  ('15-21', l.days15to21),
                                  ('22+', l.days22plus),
                                ])
                                  ChoiceChip(
                                    label: Text(label),
                                    selected: false,
                                    onSelected: (_) => setState(() =>
                                        _setPeriodStartFromBucket(bucket)),
                                  ),
                              ],
                            ),
                          ],
                          if (_lastPeriodStart != null && _cycleDay >= 1) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            _PhaseInfoCard(
                              cycleDay: _cycleDay,
                              phaseKey: _cyclePhase(_cycleDay),
                              l: l,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Comment
              FadeSlideIn(
                delay: const Duration(milliseconds: 235),
                child: _SectionHeader(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF00897B),
                  title: l.comments,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 245),
                child: TextFormField(
                  controller: _commentController,
                  decoration: _field(
                    label: l.commentLabel,
                    hint: l.commentHint,
                    alignHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 200,
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit
              FadeSlideIn(
                delay: const Duration(milliseconds: 270),
                child: FilledButton(
                  onPressed: _onContinue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.reviewAndSubmit),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
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

// ─────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(subtitle!,
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Date picker card
// ─────────────────────────────────────────────────────────────────
class _DateCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final String locale;
  final VoidCallback onTap;
  final AppLocalizations l;

  const _DateCard({
    required this.selectedDate,
    required this.isToday,
    required this.locale,
    required this.onTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cs.primaryContainer.withValues(alpha: 0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    size: 22, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.recordDate,
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat.yMMMd(locale).format(selectedDate),
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(l.today,
                      style: tt.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.edit_calendar_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Rating selector (1–5 circles)
// ─────────────────────────────────────────────────────────────────
class _RatingSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final AppLocalizations l;

  const _RatingSelector(
      {required this.value, required this.onChanged, required this.l});

  static const _colors = {
    1: Color(0xFFD32F2F),
    2: Color(0xFFF57C00),
    3: Color(0xFFFBC02D),
    4: Color(0xFF388E3C),
    5: Color(0xFF1B5E20),
  };

  String _label(int n) => switch (n) {
        1 => l.ratingVeryPoor,
        2 => l.ratingPoor,
        3 => l.ratingFair,
        4 => l.ratingGood,
        _ => l.ratingExcellent,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final n = i + 1;
            final selected = n == value;
            final color = _colors[n]!;
            return GestureDetector(
              onTap: () => onChanged(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: selected ? 58 : 52,
                height: selected ? 58 : 52,
                decoration: BoxDecoration(
                  color: selected
                      ? color
                      : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? color
                        : color.withValues(alpha: 0.4),
                    width: selected ? 2.5 : 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _label(value),
            key: ValueKey(value),
            style: TextStyle(
                fontWeight: FontWeight.w600, color: _colors[value]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Phase info card (menstrual cycle phase)
// ─────────────────────────────────────────────────────────────────
class _PhaseInfoCard extends StatelessWidget {
  final int cycleDay;
  final String phaseKey;
  final AppLocalizations l;

  const _PhaseInfoCard({
    required this.cycleDay,
    required this.phaseKey,
    required this.l,
  });

  static const _phaseStyle = {
    'menstrual': (Color(0xFFB71C1C), Icons.water_drop),
    'follicular': (Color(0xFF2E7D32), Icons.eco_rounded),
    'ovulatory': (Color(0xFFF57C00), Icons.wb_sunny_rounded),
    'luteal': (Color(0xFF4527A0), Icons.nights_stay_rounded),
    'late_luteal': (Color(0xFF546E7A), Icons.hourglass_bottom_rounded),
  };

  String _phaseName() => switch (phaseKey) {
        'menstrual' => l.phaseMenstrual,
        'follicular' => l.phaseFollicular,
        'ovulatory' => l.phaseOvulatory,
        _ => l.phaseLuteal,
      };

  String _phaseDesc() => switch (phaseKey) {
        'menstrual' => l.phaseMenstrualDesc,
        'follicular' => l.phaseFollicularDesc,
        'ovulatory' => l.phaseOvulatoryDesc,
        'luteal' => l.phaseLutealDesc,
        _ => l.phaseLateLutealDesc,
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (color, icon) =
        _phaseStyle[phaseKey] ?? _phaseStyle['late_luteal']!;
    final desc = _phaseDesc();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_phaseName(),
                      style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(width: 8),
                  Text('$cycleDay. ${l.cycleDay}',
                      style: tt.bodySmall?.copyWith(color: color)),
                ],
              ),
              const SizedBox(height: 2),
              Text(desc,
                  style: tt.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pain card (NRS 0–10)
// ─────────────────────────────────────────────────────────────────
class _PainCard extends StatelessWidget {
  final String title;
  final String desc;
  final int value;
  final ValueChanged<int> onChanged;
  final AppLocalizations l;

  const _PainCard({
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(desc,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        _NRSSelector(value: value, onChanged: onChanged),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.painNone,
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            Text(l.painWorst,
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// NRS selector (0–10)
// ─────────────────────────────────────────────────────────────────
class _NRSSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _NRSSelector({required this.value, required this.onChanged});

  static Color _color(int n) {
    if (n <= 2) return const Color(0xFF2E7D32);
    if (n <= 4) return const Color(0xFF9E9D24);
    if (n <= 6) return const Color(0xFFF57C00);
    if (n <= 8) return const Color(0xFFE64A19);
    return const Color(0xFFB71C1C);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(11, (i) {
        final selected = i == value;
        final color = _color(i);
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: selected ? 33 : 28,
            height: selected ? 33 : 28,
            decoration: BoxDecoration(
              color: selected ? color : color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? color
                    : color.withValues(alpha: 0.35),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 6)
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              '$i',
              style: TextStyle(
                fontSize: selected ? 13 : 11,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BMI display (redesigned callout style)
// ─────────────────────────────────────────────────────────────────
class _BmiDisplay extends StatelessWidget {
  final double bmi;
  final AppLocalizations l;

  const _BmiDisplay({required this.bmi, required this.l});

  (Color, String) _category() {
    if (bmi < 18.5) return (const Color(0xFF1565C0), l.bmiUnderweight);
    if (bmi < 25.0) return (const Color(0xFF2E7D32), l.bmiHealthy);
    if (bmi < 30.0) return (const Color(0xFFF57C00), l.bmiOverweight);
    if (bmi < 35.0) return (const Color(0xFFE64A19), l.bmiObese);
    return (const Color(0xFFB71C1C), l.bmiMorbidlyObese);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (color, label) = _category();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calculate_outlined, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.bmiTitle,
                    style: tt.labelSmall
                        ?.copyWith(color: color.withValues(alpha: 0.8))),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(bmi.toStringAsFixed(1),
                        style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(width: 3),
                    Text('kg/m²',
                        style: tt.labelSmall?.copyWith(
                            color: color.withValues(alpha: 0.7))),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: tt.labelSmall?.copyWith(
                    color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
