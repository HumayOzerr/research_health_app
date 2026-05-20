import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  Future<void> configure() async {
    await _health.configure();
  }

  Future<bool> requestPermissions() async {
    try {
      return await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
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
}
