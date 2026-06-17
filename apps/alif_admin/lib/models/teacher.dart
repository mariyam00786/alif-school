import 'student.dart';

class TeacherBatchAssignment {
  final String batchId;
  final Batch batch;

  TeacherBatchAssignment({
    required this.batchId,
    required this.batch,
  });

  factory TeacherBatchAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherBatchAssignment(
      batchId: json['batch_id'] as String,
      batch: Batch.fromJson(json['batches'] as Map<String, dynamic>),
    );
  }
}

class Teacher {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? qualification;
  final String status;
  final List<String> batchIds;
  final List<TeacherBatchAssignment> teacherBatches;

  Teacher({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.qualification,
    required this.status,
    required this.batchIds,
    required this.teacherBatches,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final assignments = (json['teacher_batches'] as List<dynamic>? ?? [])
        .map(
          (item) => TeacherBatchAssignment.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    return Teacher(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      email: json['email'] as String?,
      qualification: json['qualification'] as String?,
      status: json['status'] as String? ?? 'active',
      batchIds: (json['batch_ids'] as List<dynamic>? ?? [])
          .map((item) => item as String)
          .toList(),
      teacherBatches: assignments,
    );
  }
}