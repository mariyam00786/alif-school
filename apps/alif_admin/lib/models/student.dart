class Student {
  final String id;
  final String parentPhone;
  final String fatherName;
  final String motherName;
  final DateTime dateOfBirth;
  final String gender;
  final String? batchId;
  final String? classId;
  final String? address;
  final DateTime enrollmentDate;
  final String status;
  final String? fullName;
  final String? fullNameMl;
  final Batch? batch;
  final Class? classInfo;

  Student({
    required this.id,
    required this.parentPhone,
    required this.fatherName,
    required this.motherName,
    required this.dateOfBirth,
    required this.gender,
    this.batchId,
    this.classId,
    this.address,
    required this.enrollmentDate,
    this.status = 'active',
    this.fullName,
    this.fullNameMl,
    this.batch,
    this.classInfo,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      parentPhone: json['parent_phone'] as String,
      fatherName: json['father_name'] as String,
      motherName: json['mother_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String,
      batchId: json['batch_id'] as String?,
      classId: json['class_id'] as String?,
      address: json['address'] as String?,
      enrollmentDate: DateTime.parse(json['enrollment_date'] as String),
      status: json['status'] as String? ?? 'active',
      batch:
          json['batches'] != null ? Batch.fromJson(json['batches']) : null,
      classInfo: json['classes'] != null ? Class.fromJson(json['classes']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_phone': parentPhone,
      'father_name': fatherName,
      'mother_name': motherName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'gender': gender,
      'batch_id': batchId,
      'class_id': classId,
      'address': address,
      'status': status,
    };
  }
}

class Batch {
  final String id;
  final String name;
  final String? nameMl;
  final String? description;
  final int? capacity;
  final String? timing;
  final String status;

  Batch({
    required this.id,
    required this.name,
    this.nameMl,
    this.description,
    this.capacity,
    this.timing,
    this.status = 'active',
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      name: json['name'] as String,
      nameMl: json['name_ml'] as String?,
      description: json['description'] as String?,
      capacity: json['capacity'] as int?,
      timing: json['timing'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class Class {
  final String id;
  final String name;
  final String? nameMl;
  final String? level;
  final String? batchId;
  final String status;
  final Batch? batch;

  Class({
    required this.id,
    required this.name,
    this.nameMl,
    this.level,
    this.batchId,
    this.status = 'active',
    this.batch,
  });

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      id: json['id'] as String,
      name: json['name'] as String,
      nameMl: json['name_ml'] as String?,
      level: json['level'] as String?,
      batchId: json['batch_id'] as String?,
      status: json['status'] as String? ?? 'active',
      batch: json['batches'] != null ? Batch.fromJson(json['batches']) : null,
    );
  }
}

class StudentListResponse {
  final List<Student> data;
  final Pagination pagination;

  StudentListResponse({
    required this.data,
    required this.pagination,
  });

  factory StudentListResponse.fromJson(Map<String, dynamic> json) {
    return StudentListResponse(
      data: (json['data'] as List).map((e) => Student.fromJson(e)).toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Pagination {
  final int limit;
  final int offset;
  final int total;

  Pagination({
    required this.limit,
    required this.offset,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      limit: json['limit'] as int,
      offset: json['offset'] as int,
      total: json['total'] as int,
    );
  }

  int get pages => (total / limit).ceil();
  int get currentPage => (offset ~/ limit) + 1;
}
