import 'package:flutter/foundation.dart';
import '../models/submission.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class ApiService {
  final _storage = StorageService();
  final _supabase = SupabaseService();

  Future<({bool success, bool queued})> submit(Submission submission) async {
    final json = submission.toJson();
    final id = json['submission']?['id'] as String? ?? submission.id;

    try {
      await _supabase
          .saveSubmission(id: id, payload: json)
          .timeout(const Duration(seconds: 12));
      await _storage.saveSubmission(json, status: 'submitted');
      return (success: true, queued: false);
    } catch (e) {
      debugPrint('[ApiService] submit failed: $e');
      await _storage.saveSubmission(json, status: 'pending');
      return (success: false, queued: true);
    }
  }

  Future<int> flushQueue() async {
    final pending = await _storage.getPendingSubmissions();
    int sent = 0;
    for (final entry in pending) {
      final data = entry['data'] as Map<String, dynamic>;
      final id = data['submission']?['id'] as String?;
      if (id == null) continue;
      try {
        await _supabase
            .saveSubmission(id: id, payload: data)
            .timeout(const Duration(seconds: 12));
        await _storage.updateStatus(id, 'submitted');
        sent++;
      } catch (e) {
        debugPrint('[ApiService] flush failed for $id: $e');
      }
    }
    return sent;
  }
}
