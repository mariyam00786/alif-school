import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_notification.dart';

/// Manager for handling push notifications and providing streams
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  
  final _notificationController = StreamController<PushNotification>.broadcast();
  final List<PushNotification> _history = [];

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  /// Stream of notifications
  Stream<PushNotification> get notifications => _notificationController.stream;

  /// Get notification history
  List<PushNotification> getHistory({int limit = 50}) {
    return _history.take(limit).toList();
  }

  /// Clear notification history
  void clearHistory() {
    _history.clear();
  }

  /// Handle a notification
  void handleNotification(RemoteMessage message) {
    final notification = PushNotification(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
      receivedAt: DateTime.now(),
    );

    _history.insert(0, notification);
    if (_history.length > 200) {
      _history.removeLast();
    }

    _notificationController.add(notification);
  }

  /// Dispose resources
  void dispose() {
    _notificationController.close();
  }
}

/// Global notification manager instance
final notificationManager = NotificationManager();
