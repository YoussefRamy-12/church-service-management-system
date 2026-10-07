import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/students/data/local_student_repository.dart';
import 'package:church_service_management_system/features/students/data/offline_first_student_registration.dart';

void main() {
  late AppDatabase db;
  late LocalStudentRepository local;
  late SyncQueueRepository queue;
  late OfflineFirstStudentRegistration registration;

  setUp(() {
    db = AppDatabase.forTesting();
    local = LocalStudentRepository(db);
    queue = SyncQueueRepository(db);
    registration = OfflineFirstStudentRegistration(local, queue, db);
  });

  tearDown(() async => db.close());

  test('pending registration is immediately cached with proposed class and queued', () async {
    final student = await registration.registerPending(
      serviceId: 'service-1',
      proposedClassId: 'class-1',
      name: '  New Student  ',
      phone: '01000000000',
      school: 'School',
      grade: 'Grade 5',
    );

    expect(student.serviceId, 'service-1');
    expect(student.approvalStatus, 'pending');
    expect(student.proposedClassId, 'class-1');
    expect(student.currentClassId, isNull);
    expect(student.name, '  New Student  ');

    final cached = await local.findById(student.id);
    expect(cached?.approvalStatus, 'pending');
    expect(cached?.proposedClassId, 'class-1');

    final pending = await queue.pending();
    expect(pending.length, 1);
    expect(pending.single.entityType, 'student');
    expect(pending.single.operationType, 'insert');

    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;
    expect(payload['id'], student.id);
    expect(payload['service_id'], 'service-1');
    expect(payload['proposed_class_id'], 'class-1');
    expect(payload['approval_status'], 'pending');
  });
}
