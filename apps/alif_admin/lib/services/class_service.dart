import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/student.dart';

class ClassService {
  static Future<List<Class>> listClasses({
    String? batchId,
    String? status,
  }) async {
    final queryParameters = <String, String>{};
    if (batchId != null && batchId.isNotEmpty) {
      queryParameters['batch_id'] = batchId;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final response = await http.get(
      AppConfig.apiUri('/classes', queryParameters: queryParameters),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch classes: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Class.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<Class> createClass({
    required String name,
    String? nameMl,
    String? level,
    required String batchId,
    String status = 'active',
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/classes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'name_ml': nameMl,
        'level': level,
        'batch_id': batchId,
        'status': status,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create class: ${response.body}');
    }

    return Class.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<Class> updateClass(
    String id, {
    String? name,
    String? nameMl,
    String? level,
    String? batchId,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'name_ml': nameMl,
      'level': level,
      'batch_id': batchId,
      'status': status,
    };
    payload.removeWhere((_, value) => value == null);

    final response = await http.put(
      AppConfig.apiUri('/classes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update class: ${response.body}');
    }

    return Class.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteClass(String id) async {
    final response = await http.delete(AppConfig.apiUri('/classes/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete class: ${response.body}');
    }
  }
}
