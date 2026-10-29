import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'package:alif_student_teacher/config/app_config.dart';
import 'package:alif_student_teacher/models/auth_session.dart';

class AuthService {
  AuthService._();

  static const Duration timeout = Duration(seconds: 30);
  static AuthSession? _currentSession;

  static SupabaseClient get _supabase => Supabase.instance.client;

  static AuthSession? get currentSession => _currentSession;
  static String? get token => _currentSession?.accessToken ?? _supabase.auth.currentSession?.accessToken;
  static Future<String?> getToken() async => token;

  static Map<String, String> authHeaders([String? token]) {
    final resolvedToken = token ?? _currentSession?.accessToken ?? _supabase.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (resolvedToken != null && resolvedToken.isNotEmpty)
        'Authorization': 'Bearer $resolvedToken',
    };
  }

  static Future<AuthSession?> restoreSession() async {
    final session = _supabase.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      _currentSession = null;
      return null;
    }

    try {
      final user = await fetchCurrentUser(session.accessToken);
      _currentSession = AuthSession(
        accessToken: session.accessToken,
        tokenType: session.tokenType,
        user: user,
      );
      return _currentSession;
    } catch (_) {
      await logout();
      return null;
    }
  }

  static Future<String?> sendOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
    return null;
  }

  static Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );

    final session = response.session ?? _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Supabase did not return a session');
    }

    final user = await fetchCurrentUser(session.accessToken);
    _currentSession = AuthSession(
      accessToken: session.accessToken,
      tokenType: session.tokenType,
      user: user,
    );
    return _currentSession!;
  }

  static Future<AuthUser> fetchCurrentUser([String? token]) async {
    final response = await http
        .get(
          AppConfig.apiUri('/auth/me'),
          headers: authHeaders(token),
        )
        .timeout(timeout);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Failed to fetch session');
    }

    return AuthUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } finally {
      _currentSession = null;
    }
  }
}
