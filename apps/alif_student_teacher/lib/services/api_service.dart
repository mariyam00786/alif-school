import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:alif_student_teacher/config/app_config.dart';
import 'package:alif_student_teacher/models/activity.dart';
import 'package:alif_student_teacher/models/badge_teacher.dart';
import 'package:alif_student_teacher/models/leaderboard.dart';
import 'package:alif_student_teacher/models/student.dart';
import 'package:alif_student_teacher/models/teacher_remark.dart';
import 'package:alif_student_teacher/services/auth_service.dart';

class ApiService {
  ApiService._();

  static const Duration timeout = Duration(seconds: 30);

  static Future<List<LinkedStudent>> getLinkedStudents({
    required String parentPhone,
  }) async {
    final response = await http
        .get(
          AppConfig.apiUri(
            '/student/children',
            queryParameters: {'parent_phone': parentPhone},
          ),
        )
        .timeout(timeout);

    if (response.statusCode == 404) {
      return const [];
    }

    final data = _decodeList(response);
    return data.map((json) => LinkedStudent.fromJson(json)).toList();
  }

  static Future<String> getFirstStudentId() async {
    try {
      final response = await http
          .get(
            AppConfig.apiUri(
              '/students',
              queryParameters: {'limit': '1', 'offset': '0'},
            ),
          )
          .timeout(timeout);
      final body = _decodeMap(response);
      final data = (body['data'] as List<dynamic>?) ?? const [];
      if (data.isNotEmpty) {
        return (data.first as Map<String, dynamic>)['id'] as String;
      }
    } catch (_) {
    }

    return '55555555-5555-4555-8555-555555555555';
  }

  static Future<List<ActivityCategory>> listCategories() async {
    final data = _decodeList(
      await http.get(AppConfig.apiUri('/categories')).timeout(timeout),
    );
    return data.map(ActivityCategory.fromJson).toList();
  }

  static Future<List<ActivityItem>> listActivities() async {
    final data = _decodeList(
      await http.get(AppConfig.apiUri('/activities')).timeout(timeout),
    );
    return data.map(ActivityItem.fromJson).toList();
  }

  static Future<List<RatingOption>> listRatings() async {
    final data = _decodeList(
      await http.get(AppConfig.apiUri('/ratings')).timeout(timeout),
    );
    return data.map(RatingOption.fromJson).toList();
  }

  static Future<ActivityLog> createActivityLog({
    required String studentId,
    required String activityId,
    required String ratingId,
    required String logDate,
    int? quantity,
    String? notes,
  }) async {
    final response = await http
        .post(
          AppConfig.apiUri('/activity-logs'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': studentId,
            'activity_id': activityId,
            'rating_id': ratingId,
            'log_date': logDate,
            'quantity': quantity,
            'notes': notes,
          }),
        )
        .timeout(timeout);

    return ActivityLog.fromJson(_decodeMap(response));
  }

  static Future<List<LeaderboardRow>> getLeaderboard({
    required String period,
    String? batchId,
    String? date,
  }) async {
    final query = <String, String>{'period': period};
    if (batchId != null) {
      query['batch_id'] = batchId;
    }
    if (date != null) {
      query['date'] = date;
    }

    final response = await http
        .get(AppConfig.apiUri('/student/leaderboard', queryParameters: query))
        .timeout(timeout);
    final body = _decodeMap(response);
    final data = (body['data'] as List<dynamic>?) ?? const [];
    return data
        .map((row) => LeaderboardRow.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<ProgressResult> getWeeklyProgress({
    required String studentId,
    String? weekStart,
  }) async {
    final query = <String, String>{'student_id': studentId};
    if (weekStart != null) {
      query['week_start'] = weekStart;
    }

    final response = await http
        .get(AppConfig.apiUri('/student/progress/weekly', queryParameters: query))
        .timeout(timeout);
    return ProgressResult.fromJson(_decodeMap(response));
  }

  static Future<ProgressResult> getMonthlyProgress({
    required String studentId,
    String? monthStart,
  }) async {
    final query = <String, String>{'student_id': studentId};
    if (monthStart != null) {
      query['month_start'] = monthStart;
    }

    final response = await http
        .get(AppConfig.apiUri('/student/progress/monthly', queryParameters: query))
        .timeout(timeout);
    return ProgressResult.fromJson(_decodeMap(response));
  }

  static Future<List<StudentBadge>> getBadges({required String studentId}) async {
    final response = await http
        .get(
          AppConfig.apiUri(
            '/student/badges',
            queryParameters: {'student_id': studentId},
          ),
        )
        .timeout(timeout);
    return _decodeList(response).map(StudentBadge.fromJson).toList();
  }

  static Future<StudentProfile> getStudentProfile({required String studentId}) async {
    final response = await http
        .get(
          AppConfig.apiUri(
            '/student/profile',
            queryParameters: {'student_id': studentId},
          ),
        )
        .timeout(timeout);
    return StudentProfile.fromJson(_decodeMap(response));
  }

  static Future<StudentProfile> uploadStudentProfilePhoto({
    required String studentId,
    required String fileName,
    required String contentType,
    required List<int> bytes,
  }) async {
    final response = await http
        .post(
          AppConfig.apiUri('/student/profile-photo'),
          headers: AuthService.authHeaders(),
          body: jsonEncode({
            'student_id': studentId,
            'file_name': fileName,
            'content_type': contentType,
            'data_base64': base64Encode(bytes),
          }),
        )
        .timeout(timeout);

    final upload = _decodeMap(response);
    final existing = await getStudentProfile(studentId: studentId);
    return StudentProfile(
      id: existing.id,
      fatherName: existing.fatherName,
      motherName: existing.motherName,
      dateOfBirth: existing.dateOfBirth,
      gender: existing.gender,
      address: existing.address,
      batchName: existing.batchName,
      className: existing.className,
      profilePhotoPath: upload['profile_photo_path'] as String?,
      profilePhotoUrl: upload['profile_photo_url'] as String?,
    );
  }

  static Future<List<TeacherInfo>> getTeacherBatches() async {
    final response = await http
        .get(AppConfig.apiUri('/teacher/batches'))
        .timeout(timeout);
    return _decodeList(response).map(TeacherInfo.fromJson).toList();
  }

  static Future<List<Map<String, dynamic>>> getTeacherStudents({
    required String batchId,
  }) async {
    final response = await http
        .get(
          AppConfig.apiUri('/teacher/students', queryParameters: {'batch_id': batchId}),
        )
        .timeout(timeout);
    return _decodeList(response);
  }

  static Future<TeacherBatchAnalytics> getBatchAnalytics({
    required String batchId,
  }) async {
    final response = await http
        .get(AppConfig.apiUri('/teacher/batch/$batchId/analytics'))
        .timeout(timeout);
    return TeacherBatchAnalytics.fromJson(_decodeMap(response));
  }

  static Future<List<TeacherRemark>> getTeacherRemarks({
    required String studentId,
    int limit = 10,
  }) async {
    final response = await http
        .get(
          AppConfig.apiUri(
            '/remarks',
            queryParameters: {
              'student_id': studentId,
              'limit': '$limit',
            },
          ),
        )
        .timeout(timeout);
    return _decodeList(response).map(TeacherRemark.fromJson).toList();
  }

  // Notification Preferences
  static Future<List<Map<String, dynamic>>> getNotificationDevices() async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .get(
          AppConfig.apiUri('/notifications/device-tokens'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      return _decodeList(response);
    } else if (response.statusCode == 404) {
      return [];
    }
    throw Exception('Failed to fetch devices');
  }

  static Future<Map<String, dynamic>> updateNotificationPreference({
    required String deviceId,
    required bool notificationsEnabled,
  }) async {
    final token = AuthService.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http
        .put(
          AppConfig.apiUri('/notifications/device-tokens/$deviceId/preference'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'notifications_enabled': notificationsEnabled,
          }),
        )
        .timeout(timeout);

    return _decodeMap(response);
  }

  static Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] ?? 'Request failed with status ${response.statusCode}');
    }
    return decoded;
  }

  static List<Map<String, dynamic>> _decodeList(http.Response response) {
    final decoded = jsonDecode(response.body) as List<dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed with status ${response.statusCode}');
    }
    return decoded.cast<Map<String, dynamic>>();
  }
}
