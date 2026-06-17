import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String phone;
  final String fullName;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthService {
  static const String _devOtp = '123456';

  static String get devOtp => _devOtp;

  static Future<void> sendOtp({required String phone}) async {
    final response = await http.post(
      AppConfig.apiUri('/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  static Future<AuthSession> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession.fromJson(decoded);
  }
}
