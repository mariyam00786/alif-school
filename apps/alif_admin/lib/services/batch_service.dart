import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/student.dart';

class BatchService {
  static Future<List<Batch>> listBatches({String? status}) async {
    final queryParameters = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final uri = AppConfig.apiUri('/batches', queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load batches: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Batch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<Batch> createBatch({
    required String name,
    String? nameMl,
    String? description,
    int? capacity,
    String? timing,
    String status = 'active',
  }) async {
    final uri = AppConfig.apiUri('/batches');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'name_ml': nameMl,
        'description': description,
        'capacity': capacity,
        'timing': timing,
        'status': status,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create batch: ${response.body}');
    }

    return Batch.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<Batch> updateBatch(
    String id, {
    String? name,
    String? nameMl,
    String? description,
    int? capacity,
    String? timing,
    String? status,
  }) async {
    final uri = AppConfig.apiUri('/batches/$id');
    final payload = <String, dynamic>{
      'name': name,
      'name_ml': nameMl,
      'description': description,
      'capacity': capacity,
      'timing': timing,
      'status': status,
    }..removeWhere((_, value) => value == null);

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update batch: ${response.body}');
    }

    return Batch.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteBatch(String id) async {
    final uri = AppConfig.apiUri('/batches/$id');
    final response = await http.delete(uri);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete batch: ${response.body}');
    }
  }
}