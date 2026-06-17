import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/badge.dart';

class BadgeService {
  static Future<List<BadgeItem>> listBadges({String? status}) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final response = await http.get(
      AppConfig.apiUri('/badges', queryParameters: query),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load badges: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => BadgeItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<BadgeItem> createBadge({
    required String name,
    String? nameMl,
    String? description,
    String? icon,
    int bonusPoints = 0,
    String status = 'active',
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/badges'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'name_ml': nameMl,
        'description': description,
        'icon': icon,
        'bonus_points': bonusPoints,
        'status': status,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create badge: ${response.body}');
    }

    return BadgeItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<BadgeItem> updateBadge(
    String id, {
    String? name,
    String? nameMl,
    String? description,
    String? icon,
    int? bonusPoints,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'name_ml': nameMl,
      'description': description,
      'icon': icon,
      'bonus_points': bonusPoints,
      'status': status,
    }..removeWhere((_, value) => value == null);

    final response = await http.put(
      AppConfig.apiUri('/badges/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update badge: ${response.body}');
    }

    return BadgeItem.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteBadge(String id) async {
    final response = await http.delete(AppConfig.apiUri('/badges/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete badge: ${response.body}');
    }
  }
}
