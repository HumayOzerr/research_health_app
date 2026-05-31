import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/submission.dart';
import '../services/api_service.dart';
import '../services/health_service.dart';
import '../services/native_health_service.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import 'result_screen.dart';

class ReviewScreen extends StatefulWidget {
  final DateTime selectedDate;
  final HealthService healthService;
  final bool healthGranted;
  final String participantId;
  final String ageRange;
  final String? gender;
  final bool? hasPeriod;
  final int? cycleDay;
  final String? cyclePhase;
  final DateTime? lastPeriodStart;
  final int wellbeingRating;
  final int sleepQuality;
  final int neuropathicPain;
  final int musculoskeletalPain;
  final String comment;
  final double? weightKg;
  final double? bmi;
  final double? bloodGlucoseMgdl;

  const ReviewScreen({
    super.key,
    required this.selectedDate,
    required this.healthService,
    required this.healthGranted,
    required this.participantId,
    required this.ageRange,
    this.gender,
    this.hasPeriod,
    this.cycleDay,
    this.cyclePhase,
    this.lastPeriodStart,
    required this.wellbeingRating,
    required this.sleepQuality,
    required this.neuropathicPain,
    required this.musculoskeletalPain,
    required this.comment,
    this.weightKg,
    this.bmi,
    this.bloodGlucoseMgdl,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int? _steps;
  double? _heartRate;
  double? _sleepHours;
  double? _activeEnergy;
  double? _walkingSpeed;
  double? _distance;
  double? _restingHeartRate;
  double? _stepLengthM;
  double? _asymmetryPct;
  double? _doubleSupportPct;
  double? _steadinessPct;
  double? _headphoneDb;
  bool _loadingHealth = true;
  bool _submitting = false;
  bool _nativeDataFound = false;

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    if (widget.healthGranted) {
      final d = widget.selectedDate;
      final native = NativeHealthService();
      final results = await Future.wait([
        widget.healthService.getStepsForDate(d),
        widget.healthService.getHeartRateForDate(d),
        widget.healthService.getSleepForDate(d),
        widget.healthService.getActiveEnergyForDate(d),
        widget.healthService.getWalkingSpeedForDate(d),
        widget.healthService.getDistanceWalkingForDate(d),
        widget.healthService.getRestingHeartRateForDate(d),
        native.getWalkingMetrics(d),
        native.getAudioMetrics(d),
      ]);
      if (mounted) {
        final walking = results[7] as WalkingMetrics;
        final audio = results[8] as AudioMetrics;
        setState(() {
          _steps = results[0] as int?;
          _heartRate = results[1] as double?;
          _sleepHours = results[2] as double?;
          _activeEnergy = results[3] as double?;
          _walkingSpeed = results[4] as double?;
          _distance = results[5] as double?;
          _restingHeartRate = results[6] as double?;
          _stepLengthM = walking.stepLengthM;
          _asymmetryPct = walking.asymmetryPct;
          _doubleSupportPct = walking.doubleSupportPct;
          _steadinessPct = walking.steadinessPct;
          _headphoneDb = audio.headphoneDb;
          _nativeDataFound = walking.stepLengthM != null ||
              walking.asymmetryPct != null ||
              audio.headphoneDb != null;
        });
      }
    }
    if (mounted) setState(() => _loadingHealth = false);
  }

  String _phaseLabel(String? phase, AppLocalizations l) => switch (phase) {
        'menstrual' => l.phaseMenstrual,
        'follicular' => l.phaseFollicular,
        'ovulatory' => l.phaseOvulatory,
        'luteal' || 'late_luteal' => l.phaseLuteal,
        _ => '—',
      };

  String _genderLabel(String code, AppLocalizations l) => switch (code) {
        'male' => l.genderMale,
        'female' => l.genderFemale,
        'other' => l.genderOther,
        _ => l.genderPreferNotToSay,
      };

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final submission = Submission(
      id: const Uuid().v4(),
      timestamp: widget.selectedDate,
      participantId: widget.participantId,
      ageRange: widget.ageRange,
      gender: widget.gender,
      hasPeriod: widget.hasPeriod,
      cycleDay: widget.cycleDay,
      cyclePhase: widget.cyclePhase,
      lastPeriodStart: widget.lastPeriodStart,
      wellbeingRating: widget.wellbeingRating,
      sleepQuality: widget.sleepQuality,
      neuropathicPain: widget.neuropathicPain,
      musculoskeletalPain: widget.musculoskeletalPain,
      comment: widget.comment,
      weightKg: widget.weightKg,
      bmi: widget.bmi,
      bloodGlucoseMgdl: widget.bloodGlucoseMgdl,
      stepCount: _steps,
      heartRateBpm: _heartRate,
      sleepHours: _sleepHours,
      activeEnergyKcal: _activeEnergy,
      walkingSpeedKmh: _walkingSpeed,
      distanceKm: _distance,
      restingHeartRateBpm: _restingHeartRate,
      walkingStepLengthM: _stepLengthM,
      walkingAsymmetryPct: _asymmetryPct,
      walkingDoubleSupportPct: _doubleSupportPct,
      walkingStabilityPct: _steadinessPct,
      headphoneAudioDb: _headphoneDb,
    );

    final payload = const JsonEncoder.withIndent('  ').convert(submission.toJson());
    final result = await ApiService().submit(submission);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppPageRoute(
        page: ResultScreen(
          success: result.success,
          queued: result.queued,
          payload: payload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(l.reviewTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
                    FadeSlideIn(
            child: _DateHeroCard(date: widget.selectedDate, locale: locale, l: l),
          ),
          const SizedBox(height: 16),

                    FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: _SectionCard(
              title: l.participant,
              icon: Icons.badge_outlined,
              color: cs.primary,
              children: [
                _MetricRow(
                  icon: Icons.fingerprint_rounded,
                  label: l.labelId,
                  value: widget.participantId,
                  iconColor: cs.primary,
                ),
                _MetricRow(
                  icon: Icons.cake_outlined,
                  label: l.ageRange,
                  value: widget.ageRange,
                  iconColor: cs.primary,
                ),
                if (widget.gender != null)
                  _MetricRow(
                    icon: Icons.person_outline_rounded,
                    label: l.gender,
                    value: _genderLabel(widget.gender!, l),
                    iconColor: cs.primary,
                  ),
                if (widget.gender == 'female') ...[
                  _MetricRow(
                    icon: Icons.water_drop_outlined,
                    label: l.onPeriodQuestion,
                    value: widget.hasPeriod == null
                        ? '—'
                        : widget.hasPeriod!
                            ? l.yes
                            : l.no,
                    iconColor: const Color(0xFFB71C1C),
                  ),
                  if (widget.cycleDay != null)
                    _MetricRow(
                      icon: Icons.loop_rounded,
                      label: l.cycleDay,
                      value: '${widget.cycleDay} · ${_phaseLabel(widget.cyclePhase, l)}',
                      iconColor: const Color(0xFFB71C1C),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

                    FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: _SectionCard(
              title: l.wellbeing,
              icon: Icons.self_improvement_rounded,
              color: const Color(0xFF5C6BC0),
              children: [
                _RatingRow(
                  icon: Icons.mood_rounded,
                  label: l.labelRating,
                  value: widget.wellbeingRating,
                  max: 5,
                  color: cs.primary,
                ),
                _RatingRow(
                  icon: Icons.bedtime_outlined,
                  label: l.sleepQuality,
                  value: widget.sleepQuality,
                  max: 5,
                  color: const Color(0xFF5C6BC0),
                ),
                _RatingRow(
                  icon: Icons.electric_bolt_rounded,
                  label: l.neuropathicPain,
                  value: widget.neuropathicPain,
                  max: 10,
                  color: const Color(0xFFEF6C00),
                ),
                _RatingRow(
                  icon: Icons.accessibility_new_rounded,
                  label: l.musculoskeletalPain,
                  value: widget.musculoskeletalPain,
                  max: 10,
                  color: const Color(0xFFE53935),
                ),
                if (widget.weightKg != null)
                  _MetricRow(
                    icon: Icons.monitor_weight_outlined,
                    label: l.weightKg,
                    value: '${widget.weightKg!.toStringAsFixed(1)} kg',
                    iconColor: const Color(0xFF6D4C41),
                  ),
                if (widget.bmi != null)
                  _MetricRow(
                    icon: Icons.calculate_outlined,
                    label: l.bmiTitle,
                    value: widget.bmi!.toStringAsFixed(1),
                    iconColor: const Color(0xFF43A047),
                  ),
                if (widget.bloodGlucoseMgdl != null)
                  _MetricRow(
                    icon: Icons.bloodtype_rounded,
                    label: l.labelBloodGlucose,
                    value: '${widget.bloodGlucoseMgdl!.toStringAsFixed(1)} mg/dL',
                    iconColor: const Color(0xFFD81B60),
                  ),
                if (widget.comment.isNotEmpty)
                  _CommentRow(comment: widget.comment),
              ],
            ),
          ),
          const SizedBox(height: 12),

                    FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: _SectionCard(
              title: l.healthMetrics,
              icon: Icons.monitor_heart_outlined,
              color: const Color(0xFFE53935),
              children: _loadingHealth
                  ? [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ]
                  : !widget.healthGranted
                      ? [
                          _MetricRow(
                            icon: Icons.lock_outline_rounded,
                            label: l.healthMetrics,
                            value: l.permissionNotGranted,
                            iconColor: Colors.grey,
                          ),
                        ]
                      : [
                          _MetricRow(
                            icon: Icons.directions_walk_rounded,
                            label: l.labelStepsToday,
                            value: _steps != null ? '$_steps steps' : l.noData,
                            iconColor: const Color(0xFF00897B),
                            hasData: _steps != null,
                          ),
                          _MetricRow(
                            icon: Icons.favorite_rounded,
                            label: l.labelHeartRate,
                            value: _heartRate != null ? '${_heartRate!.round()} bpm' : l.noData,
                            iconColor: const Color(0xFFE53935),
                            hasData: _heartRate != null,
                          ),
                          _MetricRow(
                            icon: Icons.favorite_border_rounded,
                            label: l.labelRestingHeartRate,
                            value: _restingHeartRate != null ? '${_restingHeartRate!.round()} bpm' : l.noData,
                            iconColor: const Color(0xFFEC407A),
                            hasData: _restingHeartRate != null,
                          ),
                          _MetricRow(
                            icon: Icons.nights_stay_rounded,
                            label: l.labelSleep,
                            value: _sleepHours != null ? '${_sleepHours!.toStringAsFixed(1)} h' : l.noData,
                            iconColor: const Color(0xFF5C6BC0),
                            hasData: _sleepHours != null,
                          ),
                          _MetricRow(
                            icon: Icons.local_fire_department_rounded,
                            label: l.labelActiveEnergy,
                            value: _activeEnergy != null ? '${_activeEnergy!.round()} kcal' : l.noData,
                            iconColor: const Color(0xFFF57C00),
                            hasData: _activeEnergy != null,
                          ),
                          _MetricRow(
                            icon: Icons.speed_rounded,
                            label: l.labelWalkingSpeed,
                            value: _walkingSpeed != null
                                ? '${(_walkingSpeed! * 3.6).toStringAsFixed(1)} km/h'
                                : l.noData,
                            iconColor: const Color(0xFF8E24AA),
                            hasData: _walkingSpeed != null,
                          ),
                          _MetricRow(
                            icon: Icons.route_rounded,
                            label: l.labelDistance,
                            value: _distance != null ? '${_distance!.toStringAsFixed(2)} km' : l.noData,
                            iconColor: const Color(0xFF43A047),
                            hasData: _distance != null,
                          ),
                          if (_stepLengthM != null)
                            _MetricRow(
                              icon: Icons.straighten_rounded,
                              label: l.labelStepLength,
                              value: '${(_stepLengthM! * 100).toStringAsFixed(1)} cm',
                              iconColor: const Color(0xFF00897B),
                            ),
                          if (_asymmetryPct != null)
                            _MetricRow(
                              icon: Icons.swap_horiz_rounded,
                              label: l.labelWalkingAsymmetry,
                              value: '${_asymmetryPct!.toStringAsFixed(1)} %',
                              iconColor: const Color(0xFFAB47BC),
                            ),
                          if (_doubleSupportPct != null)
                            _MetricRow(
                              icon: Icons.directions_walk_rounded,
                              label: l.labelDoubleSupport,
                              value: '${_doubleSupportPct!.toStringAsFixed(1)} %',
                              iconColor: const Color(0xFF3949AB),
                            ),
                          if (_steadinessPct != null)
                            _MetricRow(
                              icon: Icons.balance_rounded,
                              label: l.labelWalkingSteadiness,
                              value: '${_steadinessPct!.toStringAsFixed(1)} %',
                              iconColor: const Color(0xFF26A69A),
                            ),
                          if (_headphoneDb != null)
                            _MetricRow(
                              icon: Icons.headphones_rounded,
                              label: l.labelHeadphoneAudio,
                              value: '${_headphoneDb!.toStringAsFixed(1)} dB',
                              iconColor: const Color(0xFFFF7043),
                            ),
                          if (!_nativeDataFound)
                            _MetricRow(
                              icon: Icons.info_outline_rounded,
                              label: l.nativeNoData,
                              value: '—',
                              iconColor: Colors.grey,
                              hasData: false,
                            ),
                        ],
            ),
          ),
          const SizedBox(height: 28),

                    FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: FilledButton.icon(
              onPressed: (_submitting || _loadingHealth) ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(_submitting ? '' : l.submit),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: OutlinedButton.icon(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l.editAnswers),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          FadeSlideIn(
            delay: const Duration(milliseconds: 210),
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(
                l.cancel,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Text(
              l.reviewEndpointNote,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateHeroCard extends StatelessWidget {
  final DateTime date;
  final String locale;
  final AppLocalizations l;

  const _DateHeroCard({required this.date, required this.locale, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dayStr     = DateFormat('EEEE', locale).format(date);
    final dateStr    = DateFormat('d MMMM yyyy', locale).format(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.reviewConfirm,
                  style: tt.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayStr,
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  dateStr,
                  style: tt.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool hasData;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.hasData = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              fontWeight: hasData ? FontWeight.w600 : FontWeight.normal,
              color: hasData ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int max;
  final Color color;

  const _RatingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dotCount = max <= 5 ? max : 10;
    final filled = value.clamp(0, dotCount);
    final dotSize = max <= 5 ? 10.0 : 8.0;
    final gap = max <= 5 ? 5.0 : 4.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(dotCount, (i) {
              final active = i < filled;
              return Container(
                width: dotSize,
                height: dotSize,
                margin: EdgeInsets.only(left: i == 0 ? 0 : gap),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? color : color.withValues(alpha: 0.15),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '$value/$max',
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final String comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: cs.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                comment,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
