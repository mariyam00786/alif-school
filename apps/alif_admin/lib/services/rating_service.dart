import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/rating.dart';

class RatingService {
  static Future<List<RatingOption>> listRatings({String? activityId}) async {
    final queryParameters = <String, String>{};
    if (activityId != null && activityId.isNotEmpty) {
      queryParameters['activity_id'] = activityId;
    }

    final response = await http.get(
      AppConfig.apiUri('/ratings', queryParameters: queryParameters),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load ratings: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => RatingOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<RatingOption> createRating({
    required String activityId,
    required String ratingName,
    String? ratingNameMl,
    required int marks,
    required String color,
    required int displayOrder,
  }) async {
    final response = await http.post(
      AppConfig.apiUri('/ratings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'activity_id': activityId,
        'rating_name': ratingName,
        'rating_name_ml': ratingNameMl,
        'marks': marks,
        'color': color,
        'display_order': displayOrder,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create rating: ${response.body}');
    }

    return RatingOption.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<RatingOption> updateRating(
    String id, {
    String? activityId,
    String? ratingName,
    String? ratingNameMl,
    int? marks,
    String? color,
    int? displayOrder,
  }) async {
    final payload = <String, dynamic>{
      'activity_id': activityId,
      'rating_name': ratingName,
      'rating_name_ml': ratingNameMl,
      'marks': marks,
      'color': color,
      'display_order': displayOrder,
    }..removeWhere((_, value) => value == null);

    final response = await http.put(
      AppConfig.apiUri('/ratings/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update rating: ${response.body}');
    }

    return RatingOption.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> deleteRating(String id) async {
    final response = await http.delete(AppConfig.apiUri('/ratings/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete rating: ${response.body}');
    }
  }
}