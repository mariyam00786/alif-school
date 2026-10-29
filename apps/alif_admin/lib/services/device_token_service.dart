import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class DeviceTokenService {
  DeviceTokenService._();

  static const Duration _timeout = Duration(seconds: 20);

  static String _platform() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'unknown';
    }
  }

  static Future<void> registerToken({
    required String accessToken,
    required String token,
    required String role,
  }) async {
    final response = await http
        .post(
          AppConfig.apiUri('/device-tokens/register'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'token': token,
            'platform': _platform(),
            'app_name': 'admin',
            'notifications_enabled': true,
            'role': role,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to register device token: ${response.body}');
    }
  }

  static Future<void> unregisterToken({
    required String accessToken,
    required String token,
  }) async {
    final response = await http
        .post(
          AppConfig.apiUri('/device-tokens/unregister'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'token': token}),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to unregister device token: ${response.body}');
    }
  }
}
