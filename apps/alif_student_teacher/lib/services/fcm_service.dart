import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/notification_manager.dart';
import 'auth_service.dart';
import 'firebase_options.dart';

/// FCM service for handling Firebase Cloud Messaging
class FcmService {
  static final FcmService _instance = FcmService._internal();
  static FirebaseMessaging? _messaging;
  static String? _fcmToken;

  factory FcmService() {
    return _instance;
  }

  FcmService._internal();

  /// Initialize Firebase and FCM
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _messaging = FirebaseMessaging.instance;

      // Request notification permissions (iOS)
      if (Platform.isIOS) {
        await _messaging?.requestPermission(
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
      _fcmToken = await _messaging?.getToken();
      debugPrint('[FCM] Token: $_fcmToken');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message: ${message.notification?.title}');
        _handleMessage(message);
      });

      // Handle background message (when app is closed)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle message when app is opened from notification (terminated state)
      final initialMessage = await _messaging?.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] Initial message: ${initialMessage.notification?.title}');
        _handleMessage(initialMessage);
      }

      // Handle notification when app is opened from notification (background state)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] Message opened: ${message.notification?.title}');
        _handleMessage(message);
      });

      debugPrint('[FCM] Firebase initialized successfully');
      
      // Register token with backend
      await _registerTokenWithBackend();
      
      // Listen for token refresh and register new token
      _messaging?.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _registerTokenWithBackend();
      });
    } catch (e) {
      debugPrint('[FCM] Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Get the current FCM token
  static String? getToken() => _fcmToken;

  /// Refresh the FCM token
  static Future<String?> refreshToken() async {
    try {
      _fcmToken = await _messaging?.getToken();
      debugPrint('[FCM] Token refreshed: $_fcmToken');
      await _registerTokenWithBackend();
      return _fcmToken;
    } catch (e) {
      debugPrint('[FCM] Token refresh failed: $e');
      return null;
    }
  }

  /// Listen for token refreshes
  static void onTokenRefresh(void Function(String token) callback) {
    _messaging?.onTokenRefresh.listen(callback);
  }

  /// Register the FCM token with the backend
  static Future<void> _registerTokenWithBackend() async {
    try {
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        debugPrint('[FCM] No token to register');
        return;
      }

      final token = AuthService.token;
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
              'x-alif-role': 'student',
            },
            body: jsonEncode({
              'device_token': _fcmToken,
              'platform': platform,
              'app_name': 'student_teacher',
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

  /// Handle incoming message
  static void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    debugPrint('[FCM] Message title: ${notification?.title}');
    debugPrint('[FCM] Message body: ${notification?.body}');
    debugPrint('[FCM] Message data: $data');

    // Pass to notification manager for UI handling
    notificationManager.handleNotification(message);
  }

  /// Request notification permission explicitly
  static Future<NotificationSettings> requestPermission() async {
    if (_messaging == null) {
      throw Exception('Firebase Messaging not initialized');
    }

    return await _messaging!.requestPermission(
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
      await _messaging?.deleteToken();
      _fcmToken = null;
      debugPrint('[FCM] Token deleted');
    } catch (e) {
      debugPrint('[FCM] Token deletion failed: $e');
    }
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
  // Handle background message here
  // Note: Limited execution time in background
  notificationManager.handleNotification(message);
}

