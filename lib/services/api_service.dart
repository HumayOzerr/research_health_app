import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/submission.dart';

class ApiService {
  static const _endpoint = 'https://httpbin.org/post';

  Future<bool> submit(Submission submission) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(submission.toJson()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
