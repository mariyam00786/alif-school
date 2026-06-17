import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/remark.dart';

class RemarkService {
  static Future<List<TeacherRemark>> listRemarks({
    String? teacherId,
    String? studentId,
    int limit = 50,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      if (teacherId != null && teacherId.isNotEmpty) 'teacher_id': teacherId,
      if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
    };

    final response = await http.get(AppConfig.apiUri('/remarks', queryParameters: query));
    if (response.statusCode != 200) {
      throw Exception('Failed to load remarks: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => TeacherRemark.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<TeacherRemark> createRemark({
    required String teacherId,
    required String studentId,
    required String remark,
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/remarks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'teacher_id': teacherId,
        'student_id': studentId,
        'remark': remark,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create remark: ${response.body}');
    }

    return TeacherRemark.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
