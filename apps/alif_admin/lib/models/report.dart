class ReportSummary {
  const ReportSummary({
    required this.students,
    required this.totalMarks,
    required this.totalActivities,
  });

  final int students;
  final int totalMarks;
  final int totalActivities;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      students: (json['students'] as num? ?? 0).toInt(),
      totalMarks: (json['total_marks'] as num? ?? 0).toInt(),
      totalActivities: (json['total_activities'] as num? ?? 0).toInt(),
    );
  }
}

class ReportRow {
  const ReportRow({
    required this.studentId,
    required this.studentName,
    required this.parentPhone,
    required this.batchId,
    required this.batchName,
    required this.totalMarks,
    required this.activitiesCompleted,
  });

  final String studentId;
  final String studentName;
  final String? parentPhone;
  final String? batchId;
  final String? batchName;
  final int totalMarks;
  final int activitiesCompleted;

  factory ReportRow.fromJson(Map<String, dynamic> json) {
    return ReportRow(
      studentId: json['student_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '-',
      parentPhone: json['parent_phone'] as String?,
      batchId: json['batch_id'] as String?,
      batchName: json['batch_name'] as String?,
      totalMarks: (json['total_marks'] as num? ?? 0).toInt(),
      activitiesCompleted: (json['activities_completed'] as num? ?? 0).toInt(),
    );
  }
}

class ReportResponse {
  const ReportResponse({
    required this.period,
    required this.summary,
    required this.data,
  });

  final Map<String, dynamic> period;
  final ReportSummary summary;
  final List<ReportRow> data;

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      period: (json['period'] as Map<String, dynamic>? ?? const {}),
      summary: ReportSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      data: (json['data'] as List<dynamic>? ?? const [])
          .map((item) => ReportRow.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
