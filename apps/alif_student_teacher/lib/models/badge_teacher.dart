import 'package:flutter/foundation.dart';

@immutable
class StudentBadge {
  final String id;
  final String badgeName;
  final String? badgeIcon;
  final String? description;
  final DateTime? awardedAt;
  final bool earned;

  const StudentBadge({
    required this.id,
    required this.badgeName,
    this.badgeIcon,
    this.description,
    this.awardedAt,
    required this.earned,
  });

  factory StudentBadge.fromJson(Map<String, dynamic> json) {
    final nestedBadge = json['badges'] as Map<String, dynamic>?;
    return StudentBadge(
      id: json['id'] as String,
      badgeName: json['badge_name'] as String? ?? nestedBadge?['name'] as String? ?? 'Badge',
      badgeIcon: json['badge_icon'] as String? ?? nestedBadge?['icon'] as String?,
      description: json['description'] as String? ?? nestedBadge?['description'] as String?,
      awardedAt: (json['awarded_at'] ?? json['earned_at']) is String
          ? DateTime.parse((json['awarded_at'] ?? json['earned_at']) as String)
          : null,
      earned: (json['earned'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'badge_name': badgeName,
      'badge_icon': badgeIcon,
      'description': description,
      'awarded_at': awardedAt?.toIso8601String(),
      'earned': earned,
    };
  }
}

@immutable
class TeacherInfo {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String email;
  final List<String> batchIds;
  final List<String> batchNames;
  final int studentCount;

  const TeacherInfo({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.batchIds,
    required this.batchNames,
    required this.studentCount,
  });

  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    final batchesList = (json['batches'] as List<dynamic>?) ?? [];
    final batchIds = <String>[];
    final batchNames = <String>[];
    for (final batch in batchesList) {
      if (batch is Map<String, dynamic>) {
        if (batch['id'] != null) batchIds.add(batch['id'] as String);
        if (batch['name'] != null) batchNames.add(batch['name'] as String);
      }
    }

    return TeacherInfo(
      id: (json['id'] ?? json['teacher_id']) as String,
      fullName: json['full_name'] as String? ?? json['teacher_name'] as String? ?? 'Unknown',
      mobileNumber: json['mobile_number'] as String? ?? 'N/A',
      email: json['email'] as String? ?? 'N/A',
      batchIds: batchIds,
      batchNames: batchNames,
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'email': email,
      'batch_ids': batchIds,
      'batch_names': batchNames,
      'student_count': studentCount,
    };
  }
}

@immutable
class TeacherBatchAnalytics {
  final String batchId;
  final String batchName;
  final int totalStudents;
  final int completionRate;
  final int averageMarks;
  final List<String> topPerformers;
  final String? areasForImprovement;

  const TeacherBatchAnalytics({
    required this.batchId,
    required this.batchName,
    required this.totalStudents,
    required this.completionRate,
    required this.averageMarks,
    required this.topPerformers,
    this.areasForImprovement,
  });

  factory TeacherBatchAnalytics.fromJson(Map<String, dynamic> json) {
    return TeacherBatchAnalytics(
      batchId: json['batch_id'] as String,
      batchName: json['batch_name'] as String,
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toInt() ?? 0,
      averageMarks: (json['average_marks'] as num?)?.toInt() ?? 0,
      topPerformers: ((json['top_performers'] as List<dynamic>?) ?? [])
          .map((e) => e as String)
          .toList(),
      areasForImprovement: json['areas_for_improvement'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'batch_name': batchName,
      'total_students': totalStudents,
      'completion_rate': completionRate,
      'average_marks': averageMarks,
      'top_performers': topPerformers,
      'areas_for_improvement': areasForImprovement,
    };
  }
}
