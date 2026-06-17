class TeacherRemark {
  const TeacherRemark({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.remark,
    required this.createdAt,
    this.teacherName,
    this.studentName,
    this.parentPhone,
  });

  final String id;
  final String teacherId;
  final String studentId;
  final String remark;
  final DateTime createdAt;
  final String? teacherName;
  final String? studentName;
  final String? parentPhone;

  factory TeacherRemark.fromJson(Map<String, dynamic> json) {
    return TeacherRemark(
      id: json['id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      teacherName: json['teacher_name'] as String?,
      studentName: json['student_name'] as String?,
      parentPhone: json['parent_phone'] as String?,
    );
  }
}
