import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/student.dart';

class StudentService {
  static Future<StudentListResponse> listStudents({
    String? search,
    String? batchId,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParameters = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      if (batchId != null && batchId.isNotEmpty) {
        queryParameters['batch_id'] = batchId;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final uri = AppConfig.apiUri('/students', queryParameters: queryParameters);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return StudentListResponse.fromJson(json);
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Student> getStudent(String id) async {
    try {
      final uri = AppConfig.apiUri('/students/$id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return Student.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load student: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Student> createStudent({
    required String parentPhone,
    required String fatherName,
    required String motherName,
    required DateTime dateOfBirth,
    required String gender,
    String? batchId,
    String? classId,
    String? address,
  }) async {
    try {
      final uri = AppConfig.apiUri('/students');
      final body = jsonEncode({
        'parent_phone': parentPhone,
        'father_name': fatherName,
        'mother_name': motherName,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        'gender': gender,
        'batch_id': batchId,
        'class_id': classId,
        'address': address,
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201) {
        return Student.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create student');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Student> updateStudent(
    String id, {
    String? parentPhone,
    String? fatherName,
    String? motherName,
    DateTime? dateOfBirth,
    String? gender,
    String? batchId,
    String? classId,
    String? address,
    String? status,
  }) async {
    try {
      final uri = AppConfig.apiUri('/students/$id');
      final payload = <String, dynamic>{
        'parent_phone': parentPhone,
        'father_name': fatherName,
        'mother_name': motherName,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        'gender': gender,
        'batch_id': batchId,
        'class_id': classId,
        'address': address,
        'status': status,
      };
      final body = jsonEncode(payload);

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return Student.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update student');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteStudent(String id) async {
    try {
      final uri = AppConfig.apiUri('/students/$id');
      final response = await http.delete(uri);

      if (response.statusCode != 204) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete student');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Batch>> getBatches() async {
    try {
      final uri = AppConfig.apiUri('/metadata');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => Batch.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load batches');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Class>> getClasses(String batchId) async {
    try {
      final uri = AppConfig.apiUri('/metadata/batch/$batchId/classes');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => Class.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load classes');
      }
    } catch (e) {
      rethrow;
    }
  }
}
