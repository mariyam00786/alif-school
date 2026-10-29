import 'package:flutter/foundation.dart';

@immutable
class LeaderboardRow {
  final int rank;
  final String studentId;
  final String studentName;
  final String? batchId;
  final String? batchName;
  final int totalMarks;
  final int activitiesCompleted;

  const LeaderboardRow({
    required this.rank,
    required this.studentId,
    required this.studentName,
    this.batchId,
    this.batchName,
    required this.totalMarks,
    required this.activitiesCompleted,
  });

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardRow(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      batchId: json['batch_id'] as String?,
      batchName: json['batch_name'] as String?,
      totalMarks: (json['total_marks'] as num?)?.toInt() ?? 0,
      activitiesCompleted: (json['activities_completed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'student_id': studentId,
      'student_name': studentName,
      'batch_id': batchId,
      'batch_name': batchName,
      'total_marks': totalMarks,
      'activities_completed': activitiesCompleted,
    };
  }
}

@immutable
class ProgressSummary {
  final int totalMarks;
  final int totalActivities;
  final double averageMarksPerDay;

  const ProgressSummary({
    required this.totalMarks,
    required this.totalActivities,
    required this.averageMarksPerDay,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      totalMarks: (json['total_marks'] as num?)?.toInt() ?? 0,
      totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
      averageMarksPerDay: (json['average_marks_per_day'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_marks': totalMarks,
      'total_activities': totalActivities,
      'average_marks_per_day': averageMarksPerDay,
    };
  }
}

@immutable
class ProgressLogRow {
  final String logDate;
  final int marksEarned;

  const ProgressLogRow({
    required this.logDate,
    required this.marksEarned,
  });

  factory ProgressLogRow.fromJson(Map<String, dynamic> json) {
    return ProgressLogRow(
      logDate: json['log_date'] as String,
      marksEarned: (json['marks_earned'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_date': logDate,
      'marks_earned': marksEarned,
    };
  }
}

@immutable
class ProgressResult {
  final ProgressSummary summary;
  final List<ProgressLogRow> rows;

  const ProgressResult({
    required this.summary,
    required this.rows,
  });

  factory ProgressResult.fromJson(Map<String, dynamic> json) {
    return ProgressResult(
      summary: ProgressSummary.fromJson((json['summary'] as Map<String, dynamic>?) ?? {}),
      rows: ((json['data'] as List<dynamic>?) ?? [])
          .map((e) => ProgressLogRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
