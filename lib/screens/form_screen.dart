import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/health_service.dart';
import '../services/supabase_service.dart';
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

  String? _ageRange;
  bool _ageFromProfile = false;
  String? _gender;
  bool? _hasPeriod;
  DateTime? _lastPeriodStart;
  bool _lastPeriodStartUpdated = false;
  int _rating = 3;
  int _sleepQuality = 3;
  int _neuropathicPain = 0;
  int _musculoskeletalPain = 0;
  String _participantId = '';
  bool _profileLoading = true;

  static const _ageRanges = ['18–24', '25–34', '35–44', '45–54', '55–64', '65+'];

  @override
  void initState() {
    super.initState();
    SupabaseService().getProfile().then((profile) {
      if (!mounted) return;
      setState(() {
        if (profile != null) {
          _participantId = (profile['participant_id'] as String?) ?? '';
          _gender = profile['gender'] as String?;
          final saved = profile['age_range'] as String?;
          if (saved != null) {
            _ageRange = saved;
            _ageFromProfile = true;
          }
          final lps = profile['last_period_start'] as String?;
          if (lps != null) _lastPeriodStart = DateTime.tryParse(lps);
        }
        _profileLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  int get _cycleDay => _lastPeriodStart != null
      ? DateTime.now().difference(_lastPeriodStart!).inDays + 1
      : 0;

  String _cyclePhase(int day) => switch (day) {
        <= 5 => 'menstrual',
        <= 13 => 'follicular',
        <= 16 => 'ovulatory',
        <= 28 => 'luteal',
        _ => 'late_luteal',
      };

  void _setPeriodStartFromBucket(String bucket) {
    final now = DateTime.now();
    _lastPeriodStart = switch (bucket) {
      '<7' => now.subtract(const Duration(days: 4)),
      '8-14' => now.subtract(const Duration(days: 11)),
      '15-21' => now.subtract(const Duration(days: 18)),
      _ => now.subtract(const Duration(days: 25)),
    };
    _lastPeriodStartUpdated = true;
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    if (!_ageFromProfile && _ageRange != null) {
      SupabaseService().updateProfile(ageRange: _ageRange);
    }
    if (_lastPeriodStartUpdated && _lastPeriodStart != null) {
      SupabaseService().updateProfile(lastPeriodStart: _lastPeriodStart);
    }
    final day = _cycleDay;
    Navigator.push(
      context,
      AppPageRoute(
        page: ReviewScreen(
          healthService: widget.healthService,
          healthGranted: widget.healthGranted,
          participantId: _participantId,
          ageRange: _ageRange!,
          gender: _gender,
          hasPeriod: _gender == 'female' ? _hasPeriod : null,
          cycleDay: _gender == 'female' && day > 0 ? day : null,
          cyclePhase: _gender == 'female' && day > 0 ? _cyclePhase(day) : null,
          lastPeriodStart: _gender == 'female' ? _lastPeriodStart : null,
          wellbeingRating: _rating,
          sleepQuality: _sleepQuality,
          neuropathicPain: _neuropathicPain,
          musculoskeletalPain: _musculoskeletalPain,
          comment: _commentController.text.trim(),
        ),
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

    return Scaffold(
      appBar: AppBar(title: Text(l.formTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FadeSlideIn(
              child: Text(l.yourInformation,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (!_ageFromProfile) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: DropdownButtonFormField<String>(
                  initialValue: _ageRange,
                  decoration: InputDecoration(
                    labelText: l.ageRange,
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                  items: _ageRanges
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _ageRange = v),
                  validator: (v) => v == null ? l.ageRangeError : null,
                ),
              ),
            ],
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Text(l.sleepQuality,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: Text(
                l.sleepQuestion,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: _RatingSelector(
                value: _sleepQuality,
                onChanged: (v) => setState(() => _sleepQuality = v),
                l: l,
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Text(l.wellbeingRating,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(
                l.wellbeingQuestion,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _RatingSelector(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
                l: l,
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 210),
              child: Text(l.painSection,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PainCard(
                        title: l.neuropathicPain,
                        desc: l.neuropathicPainDesc,
                        value: _neuropathicPain,
                        onChanged: (v) => setState(() => _neuropathicPain = v),
                        l: l,
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      _PainCard(
                        title: l.musculoskeletalPain,
                        desc: l.musculoskeletalPainDesc,
                        value: _musculoskeletalPain,
                        onChanged: (v) => setState(() => _musculoskeletalPain = v),
                        l: l,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_gender == 'female') ...[
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: Text(l.menstrualHealth,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 230),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _lastPeriodStart != null
                                    ? l.newPeriodQuestion
                                    : l.onPeriodQuestion,
                                style: tt.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(value: true, label: Text(l.yes)),
                                ButtonSegment(value: false, label: Text(l.no)),
                              ],
                              selected: _hasPeriod != null ? {_hasPeriod!} : {},
                              emptySelectionAllowed: true,
                              multiSelectionEnabled: false,
                              onSelectionChanged: (s) {
                                setState(() {
                                  _hasPeriod = s.isEmpty ? null : s.first;
                                  if (_hasPeriod == true) {
                                    _lastPeriodStart = DateTime.now();
                                    _lastPeriodStartUpdated = true;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (_hasPeriod == false && _lastPeriodStart == null) ...[
                          const SizedBox(height: 16),
                          Text(l.lastPeriodQuestion,
                              style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
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
                                  onSelected: (_) => setState(
                                      () => _setPeriodStartFromBucket(bucket)),
                                ),
                            ],
                          ),
                        ],
                        if (_lastPeriodStart != null) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
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
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: Text(l.comments,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: l.commentLabel,
                  hintText: l.commentHint,
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 200,
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: FilledButton(
                onPressed: _onContinue,
                child: Text(l.reviewAndSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final AppLocalizations l;

  const _RatingSelector({required this.value, required this.onChanged, required this.l});

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
                  color: selected ? color : color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? color : color.withValues(alpha: 0.4),
                    width: selected ? 2.5 : 1.5,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
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
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _label(value),
            key: ValueKey(value),
            style: TextStyle(fontWeight: FontWeight.w600, color: _colors[value]),
          ),
        ),
      ],
    );
  }
}

class _PhaseInfoCard extends StatelessWidget {
  final int cycleDay;
  final String phaseKey;
  final AppLocalizations l;

  const _PhaseInfoCard({
    required this.cycleDay,
    required this.phaseKey,
    required this.l,
  });

  static const _phaseData = {
    'menstrual':  (Color(0xFFB71C1C), Icons.water_drop,        'Progesteron & östrojen en düşük seviyede.'),
    'follicular': (Color(0xFF2E7D32), Icons.eco_rounded,        'Östrojen yükseliyor, enerji artabilir.'),
    'ovulatory':  (Color(0xFFF57C00), Icons.wb_sunny_rounded,   'Östrojen zirve noktasında, doğurgan dönem.'),
    'luteal':     (Color(0xFF4527A0), Icons.nights_stay_rounded, 'Progesteron yükseliyor, spastisite artabilir.'),
    'late_luteal':(Color(0xFF546E7A), Icons.hourglass_bottom_rounded, 'Hormonlar düşüyor, regl yaklaşıyor.'),
  };

  String _phaseName() => switch (phaseKey) {
        'menstrual'   => l.phaseMenstrual,
        'follicular'  => l.phaseFollicular,
        'ovulatory'   => l.phaseOvulatory,
        _             => l.phaseLuteal,
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (color, icon, desc) = _phaseData[phaseKey] ?? _phaseData['late_luteal']!;

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
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pain card (title + description + 0–10 NRS) ───────────────────────────────

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
        Text(title, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(desc, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        _NRSSelector(value: value, onChanged: onChanged),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.painNone,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            Text(l.painWorst,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

// ── 0–10 Numeric Rating Scale selector ───────────────────────────────────────

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
                color: selected ? color : color.withValues(alpha: 0.35),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6)]
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
