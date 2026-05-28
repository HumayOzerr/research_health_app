import 'package:flutter/foundation.dart';
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

  static String _toEmail(String participantId) =>
      '${participantId.toLowerCase().replaceAll(' ', '-')}@healthresearch.app';

  Future<AuthResponse> signUp({
    required String participantId,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    String? ageRange,
    int? heightCm,
    String? email,
  }) async {
    final authEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim().toLowerCase()
        : _toEmail(participantId);
    final res = await client.auth.signUp(
      email: authEmail,
      password: password,
      data: {'participant_id': participantId},
    );
    if (res.user != null) {
      final profileData = <String, dynamic>{
        'id': res.user!.id,
        'participant_id': participantId,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'auth_email': authEmail,
      };
      if (ageRange != null) profileData['age_range'] = ageRange;
      if (heightCm != null) profileData['height_cm'] = heightCm;
      await client.from('profiles').insert(profileData);
    }
    return res;
  }

  Future<AuthResponse> signIn({
    required String participantId,
    required String password,
  }) async {
    if (participantId.contains('@')) {
      return await client.auth.signInWithPassword(
        email: participantId.trim().toLowerCase(),
        password: password,
      );
    }
    try {
      return await client.auth.signInWithPassword(
        email: _toEmail(participantId),
        password: password,
      );
    } on AuthException {
      try {
        final result = await client
            .from('profiles')
            .select('auth_email')
            .eq('participant_id', participantId.trim().toUpperCase())
            .maybeSingle();
        final authEmail = result?['auth_email'] as String?;
        if (authEmail != null && authEmail.isNotEmpty && !authEmail.endsWith('@healthresearch.app')) {
          return await client.auth.signInWithPassword(
            email: authEmail,
            password: password,
          );
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> sendPasswordResetOtp(String email) async {
    await client.auth.signInWithOtp(email: email.trim().toLowerCase());
  }

  Future<AuthResponse> verifyPasswordResetOtp(String email, String token) async {
    try {
      return await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.email,
      );
    } on AuthException {
      return await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.magiclink,
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) {
      debugPrint('[getProfile] currentUser is null');
      return null;
    }
    try {
      final result = await client
          .from('profiles')
          .select('participant_id, first_name, last_name, gender, age_range, last_period_start, consent_given, height_cm')
          .eq('id', currentUser!.id)
          .single();
      debugPrint('[getProfile] success: $result');
      return result;
    } catch (e) {
      debugPrint('[getProfile] full query failed: $e');
      try {
        final result = await client
            .from('profiles')
            .select('participant_id, first_name, last_name, gender, age_range, height_cm')
            .eq('id', currentUser!.id)
            .single();
        debugPrint('[getProfile] fallback success: $result');
        return result;
      } catch (e2) {
        debugPrint('[getProfile] fallback also failed: $e2');
        try {
          final result = await client
              .from('profiles')
              .select('participant_id, first_name, last_name, gender')
              .eq('id', currentUser!.id)
              .single();
          debugPrint('[getProfile] minimal fallback: $result');
          return result;
        } catch (e3) {
          debugPrint('[getProfile] all queries failed: $e3');
          return null;
        }
      }
    }
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
    int? heightCm,
  }) async {
    if (currentUser == null) return;
    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (ageRange != null) updates['age_range'] = ageRange;
    if (gender != null) updates['gender'] = gender;
    if (participantId != null) updates['participant_id'] = participantId;
    if (heightCm != null) updates['height_cm'] = heightCm;
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

  bool get hasRealEmail =>
      !(currentUser?.email?.endsWith('@healthresearch.app') ?? true);

  Future<void> sendChangePasswordOtp() async {
    if (currentUser == null) throw Exception('Not authenticated');
    await client.auth.reauthenticate();
  }

  Future<void> changePasswordWithOtp(String newPassword, String otp) async {
    final email = currentUser?.email;
    if (email == null) throw Exception('No email linked');
    try {
      await client.auth.verifyOTP(
        email: email,
        token: otp.trim(),
        type: OtpType.email,
      );
    } on AuthException {
      await client.auth.verifyOTP(
        email: email,
        token: otp.trim(),
        type: OtpType.magiclink,
      );
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> changePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> saveSubmission({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    if (currentUser == null) throw Exception('Not authenticated');
    await client.from('submissions').upsert({
      'id': id,
      'user_id': currentUser!.id,
      'payload': payload,
      'status': 'submitted',
    });
  }

  Future<void> deleteSubmission(String id) async {
    if (currentUser == null) throw Exception('Not authenticated');
    await client
        .from('submissions')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUser!.id)
        .select();
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
