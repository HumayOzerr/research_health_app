import 'dart:io';

class Submission {
  final String id;
  final DateTime timestamp;
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
  final int? stepCount;
  final double? heartRateBpm;
  final double? restingHeartRateBpm;
  final double? sleepHours;
  final double? activeEnergyKcal;
  final double? walkingSpeedKmh;
  final int? flightsClimbed;
  final double? distanceKm;
  // Native HealthKit extras
  final double? walkingStepLengthM;
  final double? walkingAsymmetryPct;
  final double? walkingDoubleSupportPct;
  final double? walkingStabilityPct;
  final double? headphoneAudioDb;

  Submission({
    required this.id,
    required this.timestamp,
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
    this.stepCount,
    this.heartRateBpm,
    this.restingHeartRateBpm,
    this.sleepHours,
    this.activeEnergyKcal,
    this.walkingSpeedKmh,
    this.flightsClimbed,
    this.distanceKm,
    this.walkingStepLengthM,
    this.walkingAsymmetryPct,
    this.walkingDoubleSupportPct,
    this.walkingStabilityPct,
    this.headphoneAudioDb,
  });

  Map<String, dynamic> toJson() {
    final now = timestamp.toUtc();
    final todayMidnight = DateTime(now.year, now.month, now.day).toUtc();
    final yesterday = now.subtract(const Duration(hours: 24)).toUtc();
    final lastNightStart = DateTime(now.year, now.month, now.day - 1, 18, 0).toUtc();
    final source = Platform.isIOS ? 'HealthKit' : 'Health Connect';

    final metrics = <Map<String, dynamic>>[];

    if (stepCount != null) {
      metrics.add({
        'type': 'step_count',
        'value': stepCount,
        'unit': 'count',
        'aggregation': 'sum',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (heartRateBpm != null) {
      metrics.add({
        'type': 'heart_rate',
        'value': heartRateBpm!.round(),
        'unit': 'bpm',
        'aggregation': 'latest',
        'period_start_utc': yesterday.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (sleepHours != null) {
      metrics.add({
        'type': 'sleep_duration',
        'value': double.parse(sleepHours!.toStringAsFixed(1)),
        'unit': 'hours',
        'aggregation': 'sum',
        'period_start_utc': lastNightStart.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (activeEnergyKcal != null) {
      metrics.add({
        'type': 'active_energy_burned',
        'value': activeEnergyKcal!.round(),
        'unit': 'kcal',
        'aggregation': 'sum',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (walkingSpeedKmh != null) {
      metrics.add({
        'type': 'walking_speed',
        'value': double.parse(walkingSpeedKmh!.toStringAsFixed(2)),
        'unit': 'km/h',
        'aggregation': 'average',
        'period_start_utc': yesterday.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (flightsClimbed != null) {
      metrics.add({
        'type': 'flights_climbed',
        'value': flightsClimbed,
        'unit': 'count',
        'aggregation': 'sum',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (distanceKm != null) {
      metrics.add({
        'type': 'distance_walking_running',
        'value': double.parse(distanceKm!.toStringAsFixed(3)),
        'unit': 'km',
        'aggregation': 'sum',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (restingHeartRateBpm != null) {
      metrics.add({
        'type': 'resting_heart_rate',
        'value': restingHeartRateBpm!.round(),
        'unit': 'bpm',
        'aggregation': 'latest',
        'period_start_utc': yesterday.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (walkingStepLengthM != null) {
      metrics.add({
        'type': 'walking_step_length',
        'value': double.parse(walkingStepLengthM!.toStringAsFixed(3)),
        'unit': 'm',
        'aggregation': 'average',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (walkingAsymmetryPct != null) {
      metrics.add({
        'type': 'walking_asymmetry',
        'value': double.parse(walkingAsymmetryPct!.toStringAsFixed(1)),
        'unit': '%',
        'aggregation': 'average',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (walkingDoubleSupportPct != null) {
      metrics.add({
        'type': 'walking_double_support',
        'value': double.parse(walkingDoubleSupportPct!.toStringAsFixed(1)),
        'unit': '%',
        'aggregation': 'average',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (walkingStabilityPct != null) {
      metrics.add({
        'type': 'walking_steadiness',
        'value': double.parse(walkingStabilityPct!.toStringAsFixed(1)),
        'unit': '%',
        'aggregation': 'average',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    if (headphoneAudioDb != null) {
      metrics.add({
        'type': 'headphone_audio_exposure',
        'value': double.parse(headphoneAudioDb!.toStringAsFixed(1)),
        'unit': 'dBASPL',
        'aggregation': 'average',
        'period_start_utc': todayMidnight.toIso8601String(),
        'period_end_utc': now.toIso8601String(),
        'source': source,
      });
    }

    return {
      'schema_version': '1.0',
      'submission': {
        'id': id,
        'timestamp_utc': now.toIso8601String(),
        'app_version': '0.1.0',
      },
      'participant': {
        'id': participantId,
        'age_range': ageRange,
        if (gender != null) 'gender': gender,
      },
      'self_report': {
        'wellbeing_rating': {
          'value': wellbeingRating,
          'scale_min': 1,
          'scale_max': 5,
          'scale_description': '1=very poor, 5=excellent',
        },
        'sleep_quality': {
          'value': sleepQuality,
          'scale_min': 1,
          'scale_max': 5,
          'scale_description': '1=very poor, 5=excellent',
        },
        'pain': {
          'neuropathic': {
            'value': neuropathicPain,
            'descriptor': 'burning/tingling/electric',
            'scale_min': 0,
            'scale_max': 10,
          },
          'musculoskeletal': {
            'value': musculoskeletalPain,
            'descriptor': 'aching/stiffness/pressure',
            'scale_min': 0,
            'scale_max': 10,
          },
        },
        'comment': comment,
        if (weightKg != null) 'weight_kg': double.parse(weightKg!.toStringAsFixed(1)),
        if (bmi != null) 'bmi': double.parse(bmi!.toStringAsFixed(1)),
        if (gender == 'female') 'menstrual_status': {
          'on_period': hasPeriod,
          if (cycleDay != null) 'cycle_day': cycleDay,
          if (cyclePhase != null) 'cycle_phase': cyclePhase,
          if (lastPeriodStart != null)
            'last_period_start':
                lastPeriodStart!.toIso8601String().split('T').first,
        },
      },
      'health_metrics': metrics,
      'device': {
        'platform': Platform.isIOS ? 'iOS' : 'Android',
      },
    };
  }
}
