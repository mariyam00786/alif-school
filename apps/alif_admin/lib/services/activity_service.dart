import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/activity.dart';

class ActivityService {
  static Future<List<ActivityItem>> listActivities({
    String? categoryId,
    String? status,
  }) async {
    final queryParameters = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParameters['category_id'] = categoryId;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final uri = AppConfig.apiUri('/activities', queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load activities: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => ActivityItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ActivityItem> createActivity({
    required String categoryId,
    required String name,
    String? nameMl,
    int displayOrder = 0,
    bool hasQuantity = false,
    String status = 'active',
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/activities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'category_id': categoryId,
        'name': name,
        'name_ml': nameMl,
        'display_order': displayOrder,
        'has_quantity': hasQuantity,
        'status': status,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create activity: ${response.body}');
    }

    return ActivityItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<ActivityItem> updateActivity(
    String id, {
    String? categoryId,
    String? name,
    String? nameMl,
    int? displayOrder,
    bool? hasQuantity,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'category_id': categoryId,
      'name': name,
      'name_ml': nameMl,
      'display_order': displayOrder,
      'has_quantity': hasQuantity,
      'status': status,
    }..removeWhere((_, value) => value == null);

    final response = await http.put(
      AppConfig.apiUri('/activities/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update activity: ${response.body}');
    }

    return ActivityItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteActivity(String id) async {
    final response = await http.delete(AppConfig.apiUri('/activities/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete activity: ${response.body}');
    }
  }
}