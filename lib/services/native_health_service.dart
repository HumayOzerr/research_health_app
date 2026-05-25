import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeHealthService {
  static const _channel = MethodChannel('com.healife.app/native_health');

  static final NativeHealthService _instance = NativeHealthService._();
  factory NativeHealthService() => _instance;
  NativeHealthService._();

  /// Returns 'pong' if the native channel is reachable, null otherwise.
  Future<String?> ping() async {
    try {
      return await _channel.invokeMethod<String>('ping');
    } catch (e) {
      debugPrint('[NativeHealth] ping failed: $e');
      return null;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      return await _channel.invokeMethod<bool>('requestPermissions') ?? false;
    } catch (e) {
      debugPrint('[NativeHealth] requestPermissions failed: $e');
      return false;
    }
  }

  Future<WalkingMetrics> getWalkingMetrics(DateTime date) async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getWalkingMetrics',
        {'date': date.toIso8601String().split('T').first},
      );
      final m = Map<String, dynamic>.from(raw ?? {});
      debugPrint('[NativeHealth] walkingMetrics: $m');
      return WalkingMetrics(
        stepLengthM: (m['step_length_m'] as num?)?.toDouble(),
        asymmetryPct: (m['asymmetry_pct'] as num?)?.toDouble(),
        doubleSupportPct: (m['double_support_pct'] as num?)?.toDouble(),
        steadinessPct: (m['steadiness_pct'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('[NativeHealth] getWalkingMetrics failed: $e');
      return const WalkingMetrics();
    }
  }

  /// Returns daily avg/min/max data points for the 7-day week starting at [weekStart].
  /// Each key maps to a list of [NativeRangePt].
  /// Keys: 'stepLen', 'asymmetry', 'dblSupport', 'steadiness', 'headphone'
  Future<Map<String, List<NativeRangePt>>> getWeeklyNativeMetrics(
      DateTime weekStart) async {
    try {
      final iso = weekStart.toIso8601String().split('T').first;
      final results = await Future.wait([
        _channel.invokeMethod<Map<Object?, Object?>>('getWalkingMetricsRange', {'start': iso}),
        _channel.invokeMethod<Map<Object?, Object?>>('getAudioMetricsRange', {'start': iso}),
      ]);
      final walkRaw = results[0];
      final audioRaw = results[1];

      List<NativeRangePt> parse(Map<Object?, Object?>? raw, String key) {
        final list = (raw?[key] as List?) ?? [];
        return list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final avg = (m['avg'] as num).toDouble();
          final min = (m['min'] as num?)?.toDouble() ?? avg;
          final max = (m['max'] as num?)?.toDouble() ?? avg;
          return (
            date: DateTime.parse(m['date'] as String),
            avg: avg, min: min, max: max,
          );
        }).toList();
      }

      return {
        'stepLen':    parse(walkRaw, 'step_length_m'),
        'asymmetry':  parse(walkRaw, 'asymmetry_pct'),
        'dblSupport': parse(walkRaw, 'double_support_pct'),
        'steadiness': parse(walkRaw, 'steadiness_pct'),
        'headphone':  parse(audioRaw, 'headphone_db'),
      };
    } catch (e) {
      debugPrint('[NativeHealth] getWeeklyNativeMetrics error: $e');
      return {};
    }
  }

  Future<AudioMetrics> getAudioMetrics(DateTime date) async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getAudioMetrics',
        {'date': date.toIso8601String().split('T').first},
      );
      final m = Map<String, dynamic>.from(raw ?? {});
      debugPrint('[NativeHealth] audioMetrics: $m');
      return AudioMetrics(
        headphoneDb: (m['headphone_db'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('[NativeHealth] getAudioMetrics failed: $e');
      return const AudioMetrics();
    }
  }
}

typedef NativeRangePt = ({DateTime date, double avg, double min, double max});

class WalkingMetrics {
  final double? stepLengthM;
  final double? asymmetryPct;
  final double? doubleSupportPct;
  final double? steadinessPct;

  const WalkingMetrics({
    this.stepLengthM,
    this.asymmetryPct,
    this.doubleSupportPct,
    this.steadinessPct,
  });
}

class AudioMetrics {
  final double? headphoneDb;

  const AudioMetrics({this.headphoneDb});
}
