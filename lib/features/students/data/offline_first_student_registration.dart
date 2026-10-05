import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/student.dart';
import 'local_student_repository.dart';

class OfflineFirstStudentRegistration {
  OfflineFirstStudentRegistration(this.local, this.queue, this.db);
  final LocalStudentRepository local;
  final SyncQueueRepository queue;
  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  Future<Student> registerPending({
    required String serviceId,
    required String proposedClassId,
    required String name,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
  }) async {
    final student = Student(
      id: _uuid.v4(), serviceId: serviceId, name: name,
      approvalStatus: 'pending', proposedClassId: proposedClassId,
      birthDate: birthDate, phone: phone, school: school, grade: grade,
    );
    await local.cacheStudents([student]);
    await queue.enqueue(SyncOperation(
      operationId: _uuid.v4(), entityType: 'student', operationType: 'insert',
      payloadJson: jsonEncode({
        'id': student.id, 'service_id': student.serviceId,
        'proposed_class_id': student.proposedClassId, 'name': student.name,
        'birth_date': student.birthDate?.toIso8601String(), 'phone': student.phone,
        'school': student.school, 'grade': student.grade,
        'approval_status': 'pending',
      }),
    ));
    return student;
  }
}
