class TeacherRemark {
  const TeacherRemark({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.remark,
    required this.createdAt,
    this.teacherName,
  });

  final String id;
  final String teacherId;
  final String studentId;
  final String remark;
  final String createdAt;
  final String? teacherName;

  factory TeacherRemark.fromJson(Map<String, dynamic> json) {
    return TeacherRemark(
      id: json['id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      teacherName: json['teacher_name'] as String?,
    );
  }
}