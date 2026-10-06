import '../domain/entities/student.dart';
import '../domain/repositories/student_repository.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
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

  Future<void> refreshStudents(String classId) async {
    final values = await remote.fetchStudentsForClass(classId);
    await local.cacheStudents(values);
  }

  Future<Student> updateStudent({
    required String studentId,
    required String name,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    String? notes,
  }) async {
    final updated = await local.updateStudent(
      studentId: studentId,
      name: name,
      birthDate: birthDate,
      phone: phone,
      school: school,
      grade: grade,
      notes: notes,
    );
    await _enqueueUpdate(updated);
    return updated;
  }

  Future<Student> approvePending(String studentId) async {
    final updated = await local.approvePending(studentId);
    await _enqueueUpdate(updated);
    return updated;
  }

  Future<void> _enqueueUpdate(Student student) async {
    await queue.enqueue(SyncOperation(
      operationId: const Uuid().v4(),
      entityType: 'student',
      operationType: 'update',
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
        'enrollment_at': student.enrollmentAt?.toIso8601String(),
        'approval_status': student.approvalStatus,
        'photo_path': student.photoPath,
        'notes': student.notes,
      }),
    ));
  }
}

