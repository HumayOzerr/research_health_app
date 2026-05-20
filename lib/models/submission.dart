import 'dart:io';

class Submission {
  final String id;
  final DateTime timestamp;
  final String participantId;
  final String ageRange;
  final int wellbeingRating;
  final String comment;
  final int? stepCount;

  Submission({
    required this.id,
    required this.timestamp,
    required this.participantId,
    required this.ageRange,
    required this.wellbeingRating,
    required this.comment,
    this.stepCount,
  });

  Map<String, dynamic> toJson() {
    final now = timestamp.toUtc();
    final periodStart = DateTime(now.year, now.month, now.day).toUtc();

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
      },
      'self_report': {
        'wellbeing_rating': {
          'value': wellbeingRating,
          'scale_min': 1,
          'scale_max': 5,
          'scale_description': '1=very poor, 5=excellent',
        },
        'comment': comment,
      },
      'health_metrics': stepCount != null
          ? [
              {
                'type': 'step_count',
                'value': stepCount,
                'unit': 'count',
                'aggregation': 'sum',
                'period_start_utc': periodStart.toIso8601String(),
                'period_end_utc': now.toIso8601String(),
                'source': Platform.isIOS ? 'HealthKit' : 'Health Connect',
              }
            ]
          : [],
      'device': {
        'platform': Platform.isIOS ? 'iOS' : 'Android',
      },
    };
  }
}
