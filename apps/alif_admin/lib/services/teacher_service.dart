import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/teacher.dart';

class TeacherService {
  static Future<List<Teacher>> listTeachers({
    String? search,
    String? status,
    String? batchId,
  }) async {
    final queryParameters = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (batchId != null && batchId.isNotEmpty) {
      queryParameters['batch_id'] = batchId;
    }

    final uri = AppConfig.apiUri('/teachers', queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load teachers: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Teacher.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Teacher> createTeacher({
    required String fullName,
    required String mobileNumber,
    String? email,
    String? qualification,
    String status = 'active',
    List<String> batchIds = const [],
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/teachers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'mobile_number': mobileNumber,
        'email': email,
        'qualification': qualification,
        'status': status,
        'batch_ids': batchIds,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create teacher: ${response.body}');
    }

    return Teacher.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<Teacher> updateTeacher(
    String id, {
    String? fullName,
    String? mobileNumber,
    String? email,
    String? qualification,
    String? status,
    List<String>? batchIds,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'email': email,
      'qualification': qualification,
      'status': status,
      'batch_ids': batchIds,
    }..removeWhere((_, value) => value == null);

    final response = await http.put(
      AppConfig.apiUri('/teachers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update teacher: ${response.body}');
    }

    return Teacher.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteTeacher(String id) async {
    final response = await http.delete(AppConfig.apiUri('/teachers/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete teacher: ${response.body}');
    }
  }
}