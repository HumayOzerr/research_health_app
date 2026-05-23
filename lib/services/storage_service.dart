import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _historyKey = 'submissions_history';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveSubmission(Map<String, dynamic> json, {required String status}) async {
    final prefs = await _prefs;
    final history = prefs.getStringList(_historyKey) ?? [];
    final entry = jsonEncode({'status': status, 'data': json});
    history.insert(0, entry); // newest first
    if (history.length > 100) history.removeLast();
    await prefs.setStringList(_historyKey, history);
  }

  Future<void> updateStatus(String submissionId, String newStatus) async {
    final prefs = await _prefs;
    final history = prefs.getStringList(_historyKey) ?? [];
    for (int i = 0; i < history.length; i++) {
      final entry = jsonDecode(history[i]) as Map<String, dynamic>;
      final data = entry['data'] as Map<String, dynamic>;
      if (data['submission']?['id'] == submissionId) {
        entry['status'] = newStatus;
        history[i] = jsonEncode(entry);
        break;
      }
    }
    await prefs.setStringList(_historyKey, history);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await _prefs;
    final history = prefs.getStringList(_historyKey) ?? [];
    return history.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    final all = await getHistory();
    return all.where((e) => e['status'] == 'pending').toList();
  }
}
