import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/category.dart';

class CategoryService {
  static Future<List<ActivityCategory>> listCategories({String? status}) async {
    final queryParameters = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    final uri = AppConfig.apiUri('/categories', queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => ActivityCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ActivityCategory> createCategory({
    required String name,
    String? nameMl,
    String? icon,
    int displayOrder = 0,
    String status = 'active',
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'name_ml': nameMl,
        'icon': icon,
        'display_order': displayOrder,
        'status': status,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create category: ${response.body}');
    }

    return ActivityCategory.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<ActivityCategory> updateCategory(
    String id, {
    String? name,
    String? nameMl,
    String? icon,
    int? displayOrder,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'name_ml': nameMl,
      'icon': icon,
      'display_order': displayOrder,
      'status': status,
    }..removeWhere((_, value) => value == null);

    final response = await http.put(
      AppConfig.apiUri('/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update category: ${response.body}');
    }

    return ActivityCategory.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<void> deleteCategory(String id) async {
    final response = await http.delete(AppConfig.apiUri('/categories/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }
}