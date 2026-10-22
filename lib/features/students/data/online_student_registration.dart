import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/student.dart';
import '../domain/repositories/student_registration.dart';

/// Online-only implementation of [StudentRegistration].
///
/// Sends new student registrations directly to Supabase without persisting
/// to local Drift/SQLite or mutation queues.
class OnlineStudentRegistration implements StudentRegistration {
  const OnlineStudentRegistration(this._client);

  final SupabaseClient _client;
  static const Uuid _uuid = Uuid();

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

    for (final input in inputs) {
      final studentId = _uuid.v4();
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
        id: studentId,
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

      final studentPayload = <String, dynamic>{
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
      };

      // Directly insert to Supabase
      await _client.from('students').insert(studentPayload);

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

      if (cleanedSensitiveData.isNotEmpty) {
        await _safeInsertSensitiveData(student.id, cleanedSensitiveData);
      }

      students.add(student);
    }

    return students;
  }

  Future<void> _safeInsertSensitiveData(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    final payload = <String, dynamic>{
      'student_id': studentId,
      ...data,
    };

    while (payload.length > 1) {
      try {
        await _client.from('student_sensitive_data').insert(payload);
        return;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' ||
            e.message.contains('Could not find the column')) {
          final match = RegExp(r"column '([^']+)'").firstMatch(e.message);
          if (match != null) {
            final missingCol = match.group(1);
            if (missingCol != null && payload.containsKey(missingCol)) {
              payload.remove(missingCol);
              continue;
            }
          }
        }
        rethrow;
      }
    }
  }
}
