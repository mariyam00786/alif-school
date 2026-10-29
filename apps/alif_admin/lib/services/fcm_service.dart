import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/notification_manager.dart';
import 'auth_service.dart';

/// FCM service for admin app - handles Firebase Cloud Messaging
class FcmService {
  static final FcmService _instance = FcmService._internal();
  static FirebaseMessaging? _messaging;
  static String? _fcmToken;

  factory FcmService() {
    return _instance;
  }

  FcmService._internal();

  /// Get or initialize Firebase Messaging
  static FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  /// Get the current FCM token
  static String? getToken() => _fcmToken;

  /// Initialize FCM for admin app
  static Future<void> initialize() async {
    try {
      // Request notification permissions (iOS)
      if (Platform.isIOS) {
        await messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      }

      // Get FCM token
      _fcmToken = await messaging.getToken();
      debugPrint('[FCM] Admin token: $_fcmToken');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Admin foreground message: ${message.notification?.title}');
        _handleMessage(message);
      });

      // Handle background message
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle message when app is opened from notification (terminated state)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] Admin initial message: ${initialMessage.notification?.title}');
        _handleMessage(initialMessage);
      }

      // Handle notification when app is opened from notification (background state)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Admin message opened: ${message.notification?.title}');
        _handleMessage(message);
      });

      debugPrint('[FCM] Admin FCM initialized successfully');
      
      // Register token with backend
      await _registerTokenWithBackend();
      
      // Listen for token refresh and register new token
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _registerTokenWithBackend();
      });
    } catch (e) {
      debugPrint('[FCM] Admin initialization failed: $e');
      rethrow;
    }
  }

  /// Refresh the FCM token
  static Future<String?> refreshToken() async {
    try {
      _fcmToken = await messaging.getToken();
      debugPrint('[FCM] Admin token refreshed: $_fcmToken');
      await _registerTokenWithBackend();
      return _fcmToken;
    } catch (e) {
      debugPrint('[FCM] Admin token refresh failed: $e');
      return null;
    }
  }

  /// Register the FCM token with the backend
  static Future<void> _registerTokenWithBackend() async {
    try {
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        debugPrint('[FCM] No token to register');
        return;
      }

      final token = AuthService.getToken();
      if (token == null) {
        debugPrint('[FCM] No auth token available');
        return;
      }

      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'unknown';

      final response = await http
          .post(
            AppConfig.apiUri('/notifications/device-tokens/register'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'x-alif-role': 'admin',
            },
            body: jsonEncode({
              'device_token': _fcmToken,
              'platform': platform,
              'app_name': 'admin',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[FCM] Token registered successfully with backend');
      } else {
        debugPrint('[FCM] Failed to register token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] Error registering token with backend: $e');
    }
  }

  /// Listen to token changes
  static void onTokenRefresh(Function(String) callback) {
    messaging.onTokenRefresh.listen(callback);
  }

  /// Handle incoming message
  static void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    debugPrint('[FCM] Admin message title: ${notification?.title}');
    debugPrint('[FCM] Admin message body: ${notification?.body}');
    debugPrint('[FCM] Admin message data: $data');

    // Pass to notification manager for UI handling
    notificationManager.handleNotification(message);
  }

  /// Request notification permission explicitly
  static Future<NotificationSettings> requestPermission() async {
    return await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await messaging.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] Admin token deleted');
    } catch (e) {
      debugPrint('[FCM] Admin token deletion failed: $e');
    }
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Admin background message: ${message.notification?.title}');
  // Handle background message here
  notificationManager.handleNotification(message);
}

