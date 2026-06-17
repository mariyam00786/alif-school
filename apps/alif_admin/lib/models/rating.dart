import 'activity.dart';

class RatingOption {
  final String id;
  final String activityId;
  final String ratingName;
  final String? ratingNameMl;
  final int marks;
  final String color;
  final int displayOrder;
  final ActivityItem? activity;

  RatingOption({
    required this.id,
    required this.activityId,
    required this.ratingName,
    this.ratingNameMl,
    required this.marks,
    required this.color,
    required this.displayOrder,
    this.activity,
  });

  factory RatingOption.fromJson(Map<String, dynamic> json) {
    return RatingOption(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      ratingName: json['rating_name'] as String,
      ratingNameMl: json['rating_name_ml'] as String?,
      marks: json['marks'] as int? ?? 0,
      color: json['color'] as String? ?? '#9CA3AF',
      displayOrder: json['display_order'] as int? ?? 0,
      activity: json['activities'] != null
          ? ActivityItem.fromJson(
              {
                ...json['activities'] as Map<String, dynamic>,
                'id': (json['activities'] as Map<String, dynamic>)['id'],
                'category_id': '',
                'display_order': 0,
                'has_quantity': false,
                'status': 'active',
              },
            )
          : null,
    );
  }
}