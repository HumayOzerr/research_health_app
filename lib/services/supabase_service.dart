import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  static const _url = 'https://siljwyndsbihphhlxjco.supabase.co';
  static const _anonKey =
      'sb_publishable_-Z6nbg63UZK39o8VEN8T_A_mAZn9OxU';

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static String _toEmail(String participantId) =>
      '${participantId.toLowerCase().replaceAll(' ', '-')}@healthresearch.app';

  Future<AuthResponse> signUp({
    required String participantId,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    String? ageRange,
  }) async {
    final email = _toEmail(participantId);
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'participant_id': participantId},
    );
    if (res.user != null) {
      await client.from('profiles').insert({
        'id': res.user!.id,
        'participant_id': participantId,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'age_range': ageRange,
      });
    }
    return res;
  }

  Future<AuthResponse> signIn({
    required String participantId,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: _toEmail(participantId),
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    return await client
        .from('profiles')
        .select('participant_id, first_name, last_name, age_range, gender, last_period_start, consent_given')
        .eq('id', currentUser!.id)
        .single();
  }

  Future<String?> getParticipantId() async {
    final profile = await getProfile();
    return profile?['participant_id'] as String?;
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? ageRange,
    String? gender,
    String? participantId,
    DateTime? lastPeriodStart,
  }) async {
    if (currentUser == null) return;
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (ageRange != null) updates['age_range'] = ageRange;
    if (gender != null) updates['gender'] = gender;
    if (participantId != null) updates['participant_id'] = participantId;
    if (lastPeriodStart != null) {
      updates['last_period_start'] =
          lastPeriodStart.toIso8601String().split('T').first;
    }
    if (updates.isEmpty) return;
    await client.from('profiles').update(updates).eq('id', currentUser!.id);
  }

  Future<void> markConsentGiven() async {
    if (currentUser == null) return;
    await client
        .from('profiles')
        .update({'consent_given': true})
        .eq('id', currentUser!.id);
  }

  Future<void> changePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── Submissions ───────────────────────────────────────────────────────────

  Future<void> saveSubmission({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    if (currentUser == null) return;
    await client.from('submissions').insert({
      'id': id,
      'user_id': currentUser!.id,
      'payload': payload,
      'status': 'submitted',
    });
  }

  Future<List<Map<String, dynamic>>> getSubmissions() async {
    if (currentUser == null) return [];
    final res = await client
        .from('submissions')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}
