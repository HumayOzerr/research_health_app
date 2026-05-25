import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';
import '../models/submission.dart';
import '../services/api_service.dart';
import '../services/health_service.dart';
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
  int? _flights;
  double? _distance;
  double? _restingHeartRate;
  bool _loadingHealth = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    if (widget.healthGranted) {
      final d = widget.selectedDate;
      final results = await Future.wait([
        widget.healthService.getStepsForDate(d),
        widget.healthService.getHeartRateForDate(d),
        widget.healthService.getSleepForDate(d),
        widget.healthService.getActiveEnergyForDate(d),
        widget.healthService.getWalkingSpeedForDate(d),
        widget.healthService.getFlightsClimbedForDate(d),
        widget.healthService.getDistanceWalkingForDate(d),
        widget.healthService.getRestingHeartRateForDate(d),
      ]);
      if (mounted) {
        setState(() {
          _steps = results[0] as int?;
          _heartRate = results[1] as double?;
          _sleepHours = results[2] as double?;
          _activeEnergy = results[3] as double?;
          _walkingSpeed = results[4] as double?;
          _flights = results[5] as int?;
          _distance = results[6] as double?;
          _restingHeartRate = results[7] as double?;
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
      stepCount: _steps,
      heartRateBpm: _heartRate,
      sleepHours: _sleepHours,
      activeEnergyKcal: _activeEnergy,
      walkingSpeedKmh: _walkingSpeed,
      flightsClimbed: _flights,
      distanceKm: _distance,
      restingHeartRateBpm: _restingHeartRate,
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

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(l.reviewTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeSlideIn(
            child: Text(
              l.reviewConfirm,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: _SectionCard(
              title: l.participant,
              icon: Icons.badge_outlined,
              children: [
                _Row(l.recordDate,
                    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(widget.selectedDate)),
                _Row(l.labelId, widget.participantId),
                _Row(l.ageRange, widget.ageRange),
                if (widget.gender != null)
                  _Row(l.gender, _genderLabel(widget.gender!, l)),
                if (widget.gender == 'female') ...[
                  _Row(l.onPeriodQuestion,
                      widget.hasPeriod == null
                          ? '—'
                          : widget.hasPeriod!
                              ? l.yes
                              : l.no),
                  if (widget.cycleDay != null)
                    _Row(l.cycleDay, '${widget.cycleDay} — ${_phaseLabel(widget.cyclePhase, l)}'),
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
              children: [
                _Row(l.labelRating, '${widget.wellbeingRating} / 5'),
                _Row(l.sleepQuality, '${widget.sleepQuality} / 5'),
                _Row(l.neuropathicPain, '${widget.neuropathicPain} / 10'),
                _Row(l.musculoskeletalPain, '${widget.musculoskeletalPain} / 10'),
                if (widget.weightKg != null)
                  _Row(l.weightKg, '${widget.weightKg!.toStringAsFixed(1)} kg'),
                if (widget.bmi != null)
                  _Row(l.bmiTitle, widget.bmi!.toStringAsFixed(1)),
                if (widget.comment.isNotEmpty) _Row(l.labelComment, widget.comment),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: _SectionCard(
              title: l.healthMetrics,
              icon: Icons.monitor_heart_outlined,
              children: _loadingHealth
                  ? [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    ]
                  : !widget.healthGranted
                      ? [_Row(l.healthMetrics, l.permissionNotGranted)]
                      : [
                          _Row(l.labelStepsToday,
                              _steps != null ? '$_steps steps' : l.noData),
                          _Row(l.labelHeartRate,
                              _heartRate != null ? '${_heartRate!.round()} bpm' : l.noData),
                          _Row(l.labelRestingHeartRate,
                              _restingHeartRate != null ? '${_restingHeartRate!.round()} bpm' : l.noData),
                          _Row(l.labelSleep,
                              _sleepHours != null
                                  ? '${_sleepHours!.toStringAsFixed(1)} h'
                                  : l.noData),
                          _Row(l.labelActiveEnergy,
                              _activeEnergy != null
                                  ? '${_activeEnergy!.round()} kcal'
                                  : l.noData),
                          _Row(l.labelWalkingSpeed,
                              _walkingSpeed != null
                                  ? '${(_walkingSpeed! * 3.6).toStringAsFixed(1)} km/h'
                                  : l.noData),
                          _Row(l.labelFlightsClimbed,
                              _flights != null ? '$_flights' : l.noData),
                          _Row(l.labelDistance,
                              _distance != null
                                  ? '${_distance!.toStringAsFixed(2)} km'
                                  : l.noData),
                        ],
            ),
          ),
          const SizedBox(height: 32),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: FilledButton(
              onPressed: (_submitting || _loadingHealth) ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.submit),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: OutlinedButton.icon(
              onPressed: _submitting ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(l.editAnswers),
            ),
          ),
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 210),
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(l.cancel,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Text(
              l.reviewEndpointNote,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
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
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: tt.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
          Expanded(child: Text(value, style: tt.bodyMedium)),
        ],
      ),
    );
  }
}
