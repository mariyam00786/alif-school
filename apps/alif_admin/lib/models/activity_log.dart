import 'activity.dart';
import 'rating.dart';

class ActivityLogEntry {
  final String id;
  final String studentId;
  final String activityId;
  final String ratingId;
  final String logDate;
  final int? quantity;
  final int marksEarned;
  final bool parentApproved;
  final String? notes;
  final ActivityItem? activity;
  final RatingOption? rating;

  ActivityLogEntry({
    required this.id,
    required this.studentId,
    required this.activityId,
    required this.ratingId,
    required this.logDate,
    this.quantity,
    required this.marksEarned,
    required this.parentApproved,
    this.notes,
    this.activity,
    this.rating,
  });

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      activityId: json['activity_id'] as String,
      ratingId: json['rating_id'] as String,
      logDate: json['log_date'] as String,
      quantity: json['quantity'] as int?,
      marksEarned: json['marks_earned'] as int? ?? 0,
      parentApproved: json['parent_approved'] as bool? ?? false,
      notes: json['notes'] as String?,
      activity: json['activities'] != null
          ? ActivityItem.fromJson(
              {
                ...(json['activities'] as Map<String, dynamic>),
                'display_order': 0,
                'has_quantity': false,
                'status': 'active',
              },
            )
          : null,
      rating: json['activity_ratings'] != null
          ? RatingOption.fromJson(
              {
                ...(json['activity_ratings'] as Map<String, dynamic>),
                'activity_id': json['activity_id'],
                'color': '#9CA3AF',
                'display_order': 0,
              },
            )
          : null,
    );
  }
}