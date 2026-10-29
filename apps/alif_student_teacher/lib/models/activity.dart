import 'package:flutter/foundation.dart';

@immutable
class ActivityCategory {
  final String id;
  final String name;
  final String? nameMl;
  final String? description;

  const ActivityCategory({
    required this.id,
    required this.name,
    this.nameMl,
    this.description,
  });

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameMl: json['name_ml'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ml': nameMl,
      'description': description,
    };
  }
}

@immutable
class ActivityItem {
  final String id;
  final String categoryId;
  final String name;
  final String? nameMl;
  final String? description;
  final bool hasQuantity;
  final String status;

  const ActivityItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.nameMl,
    this.description,
    required this.hasQuantity,
    required this.status,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      nameMl: json['name_ml'] as String?,
      description: json['description'] as String?,
      hasQuantity: (json['has_quantity'] as bool?) ?? false,
      status: (json['status'] as String?) ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'name_ml': nameMl,
      'description': description,
      'has_quantity': hasQuantity,
      'status': status,
    };
  }
}

@immutable
class RatingOption {
  final String id;
  final String ratingName;
  final int marks;
  final String? activityId;
  final String? description;

  const RatingOption({
    required this.id,
    required this.ratingName,
    required this.marks,
    this.activityId,
    this.description,
  });

  factory RatingOption.fromJson(Map<String, dynamic> json) {
    return RatingOption(
      id: json['id'] as String,
      ratingName: json['rating_name'] as String,
      marks: (json['marks'] as num?)?.toInt() ?? 0,
      activityId: json['activity_id'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating_name': ratingName,
      'marks': marks,
      'activity_id': activityId,
      'description': description,
    };
  }
}

@immutable
class ActivityLog {
  final String id;
  final String studentId;
  final String activityId;
  final String ratingId;
  final String logDate;
  final int? quantity;
  final int marksEarned;
  final String? notes;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.studentId,
    required this.activityId,
    required this.ratingId,
    required this.logDate,
    this.quantity,
    required this.marksEarned,
    this.notes,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      activityId: json['activity_id'] as String,
      ratingId: json['rating_id'] as String,
      logDate: json['log_date'] as String,
      quantity: json['quantity'] as int?,
      marksEarned: (json['marks_earned'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'activity_id': activityId,
      'rating_id': ratingId,
      'log_date': logDate,
      'quantity': quantity,
      'marks_earned': marksEarned,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
