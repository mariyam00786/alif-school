import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/notification_item.dart';

class NotificationService {
  static Future<List<NotificationItem>> listNotifications({
    String? targetType,
    String? targetId,
  }) async {
    final query = <String, String>{
      if (targetType != null && targetType.isNotEmpty) 'target_type': targetType,
      if (targetId != null && targetId.isNotEmpty) 'target_id': targetId,
    };

    final response = await http.get(
      AppConfig.apiUri('/notifications', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load notifications: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<NotificationItem> createNotification({
    required String title,
    String? body,
    required String targetType,
    String? targetId,
    DateTime? scheduledAt,
    String? frequency,
  }) async {
    final isReminder = scheduledAt != null || frequency != null;
    final endpoint = isReminder ? '/notifications/reminders' : '/notifications';
    final response = await http.post(
      AppConfig.apiUri(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'body': body,
        'target_type': targetType,
        'target_id': targetId,
        'scheduled_at': scheduledAt?.toIso8601String(),
        if (isReminder) 'frequency': frequency ?? 'once',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create notification: ${response.body}');
    }

    return NotificationItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<void> deleteNotification(String id) async {
    final response = await http.delete(AppConfig.apiUri('/notifications/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete notification: ${response.body}');
    }
  }
}
