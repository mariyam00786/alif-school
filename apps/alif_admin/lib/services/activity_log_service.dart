import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  static Future<List<ActivityLogEntry>> listLogs({
    String? studentId,
    String? logDate,
  }) async {
    final query = <String, String>{};
    if (studentId != null && studentId.isNotEmpty) {
      query['student_id'] = studentId;
    }
    if (logDate != null && logDate.isNotEmpty) {
      query['log_date'] = logDate;
    }

    final response = await http.get(
      AppConfig.apiUri('/activity-logs', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load activity logs: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => ActivityLogEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ActivityLogEntry> upsertLog({
    required String studentId,
    required String activityId,
    required String ratingId,
    required String logDate,
    int? quantity,
    String? notes,
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/activity-logs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'activity_id': activityId,
        'rating_id': ratingId,
        'log_date': logDate,
        'quantity': quantity,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save activity log: ${response.body}');
    }

    return ActivityLogEntry.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}