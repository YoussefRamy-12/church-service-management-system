import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';
import '../domain/repositories/student_registration.dart';
import 'local_student_repository.dart';

export '../domain/repositories/student_registration.dart';

class OfflineFirstStudentRegistration implements StudentRegistration {
  OfflineFirstStudentRegistration(this.local, this.queue, [this.db]);
  final LocalStudentRepository local;
  final SyncQueueRepository queue;
  final AppDatabase? db;
  final Uuid _uuid = const Uuid();

  @override
  Future<Student> registerPending({
    required String serviceId,
    required String proposedClassId,
    required String name,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    bool isDeacon = false,
    DateTime? enrollmentAt,
    String? photoPath,
    String? notes,
    Map<String, dynamic> sensitiveData = const {},
  }) async {
    final batchResult = await registerBatch(
      serviceId: serviceId,
      proposedClassId: proposedClassId,
      inputs: [
        StudentRegistrationInput(
          name: name,
          birthDate: birthDate,
          phone: phone,
          school: school,
          grade: grade,
          isDeacon: isDeacon,
          enrollmentAt: enrollmentAt,
          photoPath: photoPath,
          notes: notes,
          sensitiveData: sensitiveData,
        ),
      ],
    );
    return batchResult.first;
  }

  @override
  Future<List<Student>> registerBatch({
    required String serviceId,
    String? currentClassId,
    String? proposedClassId,
    required List<StudentRegistrationInput> inputs,
  }) async {
    final students = <Student>[];
    final operations = <SyncOperation>[];

    for (final input in inputs) {
      final effectiveCurrentClassId = input.currentClassId ??
          (input.proposedClassId != null || proposedClassId != null
              ? null
              : currentClassId);
      final effectiveProposedClassId = input.proposedClassId ??
          (effectiveCurrentClassId != null ? null : proposedClassId);
      final effectiveApprovalStatus = input.approvalStatus ??
          (effectiveCurrentClassId != null ? 'approved' : 'pending');

      final effectiveGrade = input.grade?.trim();
      if (effectiveGrade == null || effectiveGrade.isEmpty) {
        throw ArgumentError(
          'Student "${input.name}" is missing a required grade.',
        );
      }

      final student = Student(
        id: _uuid.v4(),
        serviceId: serviceId,
        name: input.name.trim(),
        approvalStatus: effectiveApprovalStatus,
        currentClassId: effectiveCurrentClassId,
        proposedClassId: effectiveProposedClassId,
        birthDate: input.birthDate,
        phone: input.phone?.trim().isEmpty == true ? null : input.phone?.trim(),
        school: input.school?.trim().isEmpty == true
            ? null
            : input.school?.trim(),
        grade: effectiveGrade,
        isDeacon: input.isDeacon,
        enrollmentAt: input.enrollmentAt ?? DateTime.now(),
        photoPath: input.photoPath?.trim().isEmpty == true
            ? null
            : input.photoPath?.trim(),
        notes: input.notes?.trim().isEmpty == true ? null : input.notes?.trim(),
      );
      students.add(student);

      final cleanedSensitiveData = <String, dynamic>{};
      for (final entry in input.sensitiveData.entries) {
        final val = entry.value;
        if (val == null) continue;
        if (val is String) {
          final trimmed = val.trim();
          if (trimmed.isNotEmpty) {
            cleanedSensitiveData[entry.key] = trimmed;
          }
        } else {
          cleanedSensitiveData[entry.key] = val;
        }
      }

      // Cache locally if sensitive data is present
      if (cleanedSensitiveData.isNotEmpty) {
        final sensitiveObj = SensitiveStudentData.fromMap(
          cleanedSensitiveData,
          studentId: student.id,
        );
        await local.cacheSensitiveData(sensitiveObj);
      }

      operations.add(
        SyncOperation(
          operationId: _uuid.v4(),
          entityType: 'student',
          operationType: 'insert',
          payloadJson: jsonEncode({
            'id': student.id,
            'service_id': student.serviceId,
            'current_class_id': student.currentClassId,
            'proposed_class_id': student.proposedClassId,
            'name': student.name,
            'birth_date': student.birthDate?.toIso8601String().split('T').first,
            'phone': student.phone,
            'school': student.school,
            'grade': student.grade,
            'is_deacon': student.isDeacon,
            'approval_status': student.approvalStatus,
            'enrollment_at': student.enrollmentAt
                ?.toIso8601String()
                .split('T')
                .first,
            'photo_path': student.photoPath,
            'notes': student.notes,
            'sensitive_data': cleanedSensitiveData,
          }),
        ),
      );
    }

    await local.cacheStudents(students);
    for (final op in operations) {
      await queue.enqueue(op);
    }
    return students;
  }
}
