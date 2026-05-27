import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  static const _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WALKING_SPEED,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.RESTING_HEART_RATE,
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

  Future<double?> getWalkingSpeed() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.WALKING_SPEED],
      );
      if (data.isEmpty) return null;
      final total = data.fold<double>(
          0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toDouble());
      return total / data.length;
    } catch (_) {
      return null;
    }
  }

  Future<int?> getTodayFlightsClimbed() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.FLIGHTS_CLIMBED],
      );
      if (data.isEmpty) return null;
      return data
          .fold<double>(
              0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toDouble())
          .round();
    } catch (_) {
      return null;
    }
  }

  Future<double?> getTodayDistanceWalking() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
      );
      if (data.isEmpty) return null;
      final totalMeters = data.fold<double>(
          0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toDouble());
      return totalMeters / 1000;
    } catch (_) {
      return null;
    }
  }

  Future<double?> getRestingHeartRate() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.RESTING_HEART_RATE],
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<int?> getStepsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final effectiveEnd = end.isAfter(now) ? now : end;
    try {
      return await _health.getTotalStepsInInterval(start, effectiveEnd);
    } catch (_) {
      return null;
    }
  }

  Future<double?> getHeartRateForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final effectiveEnd = end.isAfter(now) ? now : end;
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: effectiveEnd,
        types: [HealthDataType.HEART_RATE],
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<double?> getSleepForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day - 1, 18, 0);
    final end = DateTime(date.year, date.month, date.day, 12, 0);
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

  Future<double?> getActiveEnergyForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final effectiveEnd = end.isAfter(now) ? now : end;
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: effectiveEnd,
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

  Future<double?> getWalkingSpeedForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final effectiveEnd = end.isAfter(now) ? now : end;
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: effectiveEnd,
        types: [HealthDataType.WALKING_SPEED],
      );
      if (data.isEmpty) return null;
      final total = data.fold<double>(
          0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toDouble());
      return total / data.length;
    } catch (_) {
      return null;
    }
  }

  Future<int?> getFlightsClimbedForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final effectiveEnd = end.isAfter(now) ? now : end;
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: effectiveEnd,
        types: [HealthDataType.FLIGHTS_CLIMBED],
      );
      if (data.isEmpty) return null;
      return data
          .fold<double>(
              0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toDouble())
          .round();
    } catch (_) {
      return null;
    }
  }

  Future<double?> getDistanceWalkingForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final effectiveEnd = end.isAfter(now) ? now : end;
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: effectiveEnd,
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
      );
      if (data.isEmpty) return null;
      final totalMeters = data.fold<double>(
          0, (s, p) => s + (p.value as NumericHealthValue).numericValue.toDouble());
      return totalMeters / 1000;
    } catch (_) {
      return null;
    }
  }

  Future<double?> getRestingHeartRateForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final end = start.add(const Duration(days: 1));
    final effectiveEnd = end.isAfter(now) ? now : end;
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: effectiveEnd,
        types: [HealthDataType.RESTING_HEART_RATE],
      );
      if (data.isEmpty) return null;
      return (data.last.value as NumericHealthValue).numericValue.toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<List<({DateTime date, int steps})>> getStepsInRange(DateTime weekStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <({DateTime date, int steps})>[];
    for (int i = 0; i < 7; i++) {
      final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      if (day.isAfter(today)) break;
      final dayEnd = day.add(const Duration(days: 1));
      final end = dayEnd.isAfter(now) ? now : dayEnd;
      try {
        final steps = await _health.getTotalStepsInInterval(day, end);
        results.add((date: day, steps: steps ?? 0));
      } catch (_) {
        results.add((date: day, steps: 0));
      }
    }
    return results;
  }

        Future<Map<String, dynamic>> getWeeklyMetrics(DateTime weekStart) async {
    final now = DateTime.now();
    final weekEnd = weekStart.add(const Duration(days: 7));
    final effectiveEnd = weekEnd.isAfter(now) ? now : weekEnd;

    List<({DateTime date, double value})> group(
      List<HealthDataPoint> data, {
      bool sum = false,
      double factor = 1.0,
    }) {
      final byIndex = <int, List<double>>{};
      for (final d in data) {
        final idx = d.dateFrom.difference(weekStart).inDays;
        if (idx < 0 || idx >= 7) continue;
        byIndex.putIfAbsent(idx, () => []).add(
            (d.value as NumericHealthValue).numericValue.toDouble() * factor);
      }
      final out = <({DateTime date, double value})>[];
      for (final e in byIndex.entries) {
        final day = weekStart.add(Duration(days: e.key));
        if (day.isAfter(now)) continue;
        final v = sum
            ? e.value.reduce((a, b) => a + b)
            : e.value.reduce((a, b) => a + b) / e.value.length;
        out.add((date: day, value: v));
      }
      out.sort((a, b) => a.date.compareTo(b.date));
      return out;
    }

    List<({DateTime date, double avg, double min, double max})> groupRange(
      List<HealthDataPoint> data, {
      double factor = 1.0,
    }) {
      final byIndex = <int, List<double>>{};
      for (final d in data) {
        final idx = d.dateFrom.difference(weekStart).inDays;
        if (idx < 0 || idx >= 7) continue;
        byIndex.putIfAbsent(idx, () => []).add(
            (d.value as NumericHealthValue).numericValue.toDouble() * factor);
      }
      final out = <({DateTime date, double avg, double min, double max})>[];
      for (final e in byIndex.entries) {
        final day = weekStart.add(Duration(days: e.key));
        if (day.isAfter(now)) continue;
        final vals = e.value;
        final avg = vals.reduce((a, b) => a + b) / vals.length;
        final mn = vals.reduce((a, b) => a < b ? a : b);
        final mx = vals.reduce((a, b) => a > b ? a : b);
        out.add((date: day, avg: avg, min: mn, max: mx));
      }
      out.sort((a, b) => a.date.compareTo(b.date));
      return out;
    }

    Future<List<({DateTime date, double value})>> fetch(
      HealthDataType type, {
      bool sum = false,
      double factor = 1.0,
    }) async {
      try {
        final data = await _health.getHealthDataFromTypes(
          startTime: weekStart,
          endTime: effectiveEnd,
          types: [type],
        );
        return group(data, sum: sum, factor: factor);
      } catch (_) {
        return [];
      }
    }

    Future<List<({DateTime date, double avg, double min, double max})>> fetchRange(
      HealthDataType type, {
      double factor = 1.0,
    }) async {
      try {
        final data = await _health.getHealthDataFromTypes(
          startTime: weekStart,
          endTime: effectiveEnd,
          types: [type],
        );
        return groupRange(data, factor: factor);
      } catch (_) {
        return [];
      }
    }

    Future<List<({DateTime date, double value})>> fetchSleep() async {
      try {
        final sleepStart = weekStart.subtract(const Duration(hours: 6));
        final data = await _health.getHealthDataFromTypes(
          startTime: sleepStart,
          endTime: effectiveEnd,
          types: [HealthDataType.SLEEP_ASLEEP],
        );
        final byDay = <String, double>{};
        for (final d in data) {
          final mins = d.dateTo.difference(d.dateFrom).inMinutes.toDouble();
          final wakeDay =
              DateTime(d.dateTo.year, d.dateTo.month, d.dateTo.day);
          final k = '${wakeDay.year}-${wakeDay.month}-${wakeDay.day}';
          byDay[k] = (byDay[k] ?? 0) + mins;
        }
        final out = <({DateTime date, double value})>[];
        for (int i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          if (day.isAfter(now)) break;
          final k = '${day.year}-${day.month}-${day.day}';
          final mins = byDay[k];
          if (mins != null && mins > 0) out.add((date: day, value: mins / 60));
        }
        return out;
      } catch (_) {
        return [];
      }
    }

    final flat = await Future.wait([
      fetch(HealthDataType.HEART_RATE),
      fetch(HealthDataType.RESTING_HEART_RATE),
      fetch(HealthDataType.ACTIVE_ENERGY_BURNED, sum: true),
      fetch(HealthDataType.DISTANCE_WALKING_RUNNING, sum: true, factor: 1 / 1000),
      fetch(HealthDataType.FLIGHTS_CLIMBED, sum: true),
      fetchSleep(),
    ]);
    final speedRange = await fetchRange(HealthDataType.WALKING_SPEED, factor: 3.6);

    return {
      'hr':      flat[0],
      'restHr':  flat[1],
      'energy':  flat[2],
      'dist':    flat[3],
      'flights': flat[4],
      'sleep':   flat[5],
      'speed':   speedRange,
    };
  }

  Future<List<({DateTime date, int steps})>> getLast7DaysSteps() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - 6);
    return getStepsInRange(weekStart);
  }
}
