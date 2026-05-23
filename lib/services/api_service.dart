import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/submission.dart';
import 'storage_service.dart';

class ApiService {
  static const _endpoint = 'https://httpbin.org/post';
  final _storage = StorageService();

  // Returns (success, queued) — queued=true means saved offline for later
  Future<({bool success, bool queued})> submit(Submission submission) async {
    final json = submission.toJson();
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(json),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _storage.saveSubmission(json, status: 'submitted');
        return (success: true, queued: false);
      } else {
        await _storage.saveSubmission(json, status: 'pending');
        return (success: false, queued: true);
      }
    } catch (_) {
      // Network unavailable — save to offline queue
      await _storage.saveSubmission(json, status: 'pending');
      return (success: false, queued: true);
    }
  }

  // Try to resend all pending submissions
  Future<int> flushQueue() async {
    final pending = await _storage.getPendingSubmissions();
    int sent = 0;
    for (final entry in pending) {
      final data = entry['data'] as Map<String, dynamic>;
      final id = data['submission']?['id'] as String?;
      if (id == null) continue;
      try {
        final response = await http
            .post(
              Uri.parse(_endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(data),
            )
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          await _storage.updateStatus(id, 'submitted');
          sent++;
        }
      } catch (_) {
        // Still offline, keep in queue
      }
    }
    return sent;
  }
}
