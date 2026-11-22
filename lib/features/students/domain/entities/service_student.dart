import 'package:flutter/foundation.dart';

@immutable
class ServiceStudent {
  const ServiceStudent({
    required this.id,
    required this.studentId,
    required this.serviceId,
    required this.enrollmentDate,
    required this.status,
    this.classId,
    this.proposedClassId,
    this.school,
    this.grade,
    this.isDeacon = false,
    this.notes,
    this.studentName = '',
    this.birthDate,
    this.phone,
    this.photoPath,
    this.identityServiceId,
  });

  final String id;
  final String studentId;
  final String serviceId;
  final String? classId;
  final String? proposedClassId;
  final DateTime enrollmentDate;
  final String status;
  final String? school;
  final String? grade;
  final bool isDeacon;
  final String? notes;
  final String studentName;
  final DateTime? birthDate;
  final String? phone;
  final String? photoPath;
  final String? identityServiceId;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  Map<String, dynamic> toMap() => {
    'id': id,
    'student_id': studentId,
    'service_id': serviceId,
    'class_id': classId,
    'proposed_class_id': proposedClassId,
    'enrollment_date': enrollmentDate.toUtc().toIso8601String(),
    'status': status,
    'school': school,
    'grade': grade,
    'is_deacon': isDeacon,
    'notes': notes,
  };

  factory ServiceStudent.fromMap(Map<String, dynamic> row) => ServiceStudent(
    id: (row['membership_id'] ?? row['id']) as String,
    studentId: row['student_id'] as String,
    serviceId: row['service_id'] as String,
    classId: row['class_id'] as String?,
    proposedClassId: row['proposed_class_id'] as String?,
    enrollmentDate: DateTime.parse(row['enrollment_date'] as String).toLocal(),
    status: (row['membership_status'] ?? row['status']) as String,
    school: row['school'] as String?,
    grade: row['grade'] as String?,
    isDeacon: row['is_deacon'] as bool? ?? false,
    notes: (row['membership_notes'] ?? row['notes']) as String?,
    studentName: (row['student_name'] ?? '') as String,
    birthDate: row['birth_date'] == null
        ? null
        : DateTime.tryParse(row['birth_date'].toString()),
    phone: row['phone'] as String?,
    photoPath: row['photo_path'] as String?,
    identityServiceId: row['identity_service_id'] as String?,
  );
}
