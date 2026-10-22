import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';
import '../domain/repositories/student_repository.dart';
import 'local_student_repository.dart';
import 'supabase_student_repository.dart';

class OfflineFirstStudentRepository implements StudentRepository {
  OfflineFirstStudentRepository({
    required this.local,
    required this.remote,
    required this.queue,
  });

  final LocalStudentRepository local;
  final SupabaseStudentRepository remote;
  final SyncQueueRepository queue;

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) =>
      local.watchStudentsForClass(classId);

  @override
  Stream<List<Student>> watchStudentsForService(String serviceId) =>
      local.watchStudentsForService(serviceId);

  @override
  Future<void> refreshStudents(String classId) async {
    final values = await remote.fetchStudentsForClass(classId);
    await local.cacheStudents(values);
  }

  @override
  Future<void> refreshStudentsForService(String serviceId) async {
    final values = await remote.fetchStudentsForService(serviceId);
    await local.cacheStudents(values);
  }

  @override
  Future<SensitiveStudentData?> getSensitiveData(String studentId) async {
    try {
      final remoteRow = await remote.fetchSensitiveData(studentId);
      if (remoteRow != null) {
        final data = SensitiveStudentData.fromMap(
          remoteRow,
          studentId: studentId,
        );
        await local.cacheSensitiveData(data);
        return data;
      }
    } catch (_) {}
    return local.findSensitiveData(studentId);
  }

  @override
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    bool? isDeacon,
    DateTime? enrollmentAt,
    String? photoPath,
    String? notes,
    SensitiveStudentData? sensitiveData,
  }) async {
    final updated = await local.updateStudent(
      studentId: studentId,
      name: name,
      birthDate: birthDate,
      phone: phone,
      school: school,
      grade: grade,
      isDeacon: isDeacon,
      enrollmentAt: enrollmentAt,
      photoPath: photoPath,
      notes: notes,
    );
    if (sensitiveData != null) {
      await local.cacheSensitiveData(sensitiveData);
    }
    await _enqueueUpdate(updated, sensitiveData: sensitiveData);
    return updated;
  }

  @override
  Future<Student> approvePending(String studentId) async {
    final updated = await local.approvePending(studentId);
    await _enqueueUpdate(updated);
    return updated;
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    final current = await local.findById(studentId);
    if (current == null) return;
    await local.deleteStudent(studentId);
    await queue.enqueue(
      SyncOperation(
        operationId: const Uuid().v4(),
        entityType: 'student',
        operationType: 'delete',
        payloadJson: jsonEncode({'id': studentId}),
      ),
    );
  }

  @override
  Future<Student> assignClass(String studentId, String classId) async {
    final updated = await local.assignClass(studentId, classId);
    await _enqueueUpdate(updated);
    return updated;
  }

  Future<void> _enqueueUpdate(
    Student student, {
    SensitiveStudentData? sensitiveData,
  }) async {
    final payload = <String, dynamic>{
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
      'enrollment_at': student.enrollmentAt?.toIso8601String(),
      'approval_status': student.approvalStatus,
      'photo_path': student.photoPath,
      'notes': student.notes,
    };

    if (sensitiveData != null) {
      payload['sensitive_data'] = sensitiveData.toMap();
    }

    await queue.enqueue(
      SyncOperation(
        operationId: const Uuid().v4(),
        entityType: 'student',
        operationType: 'update',
        payloadJson: jsonEncode(payload),
      ),
    );
  }
}
