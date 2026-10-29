import 'package:flutter/foundation.dart';

@immutable
class LinkedStudent {
  final String id;
  final String name;
  final String batchName;

  const LinkedStudent({
    required this.id,
    required this.name,
    required this.batchName,
  });

  factory LinkedStudent.fromJson(Map<String, dynamic> json) {
    final studentName = json['student_name'] as String?;
    final fallbackName = [json['father_name'], json['mother_name']]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' / ');

    return LinkedStudent(
      id: json['id'] as String,
      name: studentName ?? (fallbackName.isEmpty ? 'Unknown' : fallbackName),
      batchName: json['batch_name'] as String? ?? 'Unassigned',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_name': name,
      'batch_name': batchName,
    };
  }
}

@immutable
class StudentProfile {
  final String id;
  final String fatherName;
  final String motherName;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String batchName;
  final String className;
  final String? profilePhotoPath;
  final String? profilePhotoUrl;

  const StudentProfile({
    required this.id,
    required this.fatherName,
    required this.motherName,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.batchName,
    required this.className,
    this.profilePhotoPath,
    this.profilePhotoUrl,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      fatherName: json['father_name'] as String? ?? 'Unknown',
      motherName: json['mother_name'] as String? ?? 'Unknown',
      dateOfBirth: json['date_of_birth'] as String? ?? 'N/A',
      gender: json['gender'] as String? ?? 'N/A',
      address: json['address'] as String? ?? 'N/A',
      batchName: json['batch_name'] as String? ?? ((json['batches'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unassigned'),
      className: json['class_name'] as String? ?? ((json['classes'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unassigned'),
      profilePhotoPath: json['profile_photo_path'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'father_name': fatherName,
      'mother_name': motherName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'address': address,
      'batch_name': batchName,
      'class_name': className,
      'profile_photo_path': profilePhotoPath,
      'profile_photo_url': profilePhotoUrl,
    };
  }
}
