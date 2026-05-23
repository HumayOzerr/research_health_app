import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  static const _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestPermissions() async {
    try {
      final permissions = _readTypes.map((_) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(_readTypes, permissions: permissions);
    } catch (_) {
      return false;
    }
  }

  Future<int?> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      return await _health.getTotalStepsInInterval(midnight, now);
    } catch (_) {
      return null;
    }
  }

  Future<double?> getLatestHeartRate() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<double?> getLastNightSleep() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 1, 18, 0);
    final end = DateTime(now.year, now.month, now.day, 12, 0);
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.SLEEP_ASLEEP],
      );
      if (data.isEmpty) return null;
      final totalMinutes = data.fold<double>(
        0,
        (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes,
      );
      return totalMinutes / 60;
    } catch (_) {
      return null;
    }
  }

  Future<double?> getTodayActiveEnergy() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      if (data.isEmpty) return null;
      return data.fold<double>(
        0,
        (sum, p) => sum + (p.value as NumericHealthValue).numericValue.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<({DateTime date, int steps})>> getLast7DaysSteps() async {
    final now = DateTime.now();
    final results = <({DateTime date, int steps})>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final end = i == 0 ? now : day.add(const Duration(days: 1));
      try {
        final steps = await _health.getTotalStepsInInterval(day, end);
        results.add((date: day, steps: steps ?? 0));
      } catch (_) {
        results.add((date: day, steps: 0));
      }
    }
    return results;
  }
}
