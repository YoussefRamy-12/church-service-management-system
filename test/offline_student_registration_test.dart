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
    registration = OfflineFirstStudentRegistration(local, queue);
  });

  tearDown(() async => db.close());

  test('registration without required birth date is rejected before queueing', () async {
    await expectLater(
      registration.registerPending(
        serviceId: 'service-1',
        proposedClassId: 'class-1',
        name: 'Missing Birth Date',
        grade: 'Grade 5',
      ),
      throwsArgumentError,
    );
    expect(await queue.pending(), isEmpty);
  });

  test(
    'pending registration is immediately cached with proposed class and queued',
    () async {
      final student = await registration.registerPending(
        serviceId: 'service-1',
        proposedClassId: 'class-1',
        name: '  New Student  ',
        phone: '01000000000',
        school: 'School',
        grade: 'Grade 5',
        birthDate: DateTime(2015, 3, 12),
      );

      expect(student.serviceId, 'service-1');
      expect(student.approvalStatus, 'pending');
      expect(student.proposedClassId, 'class-1');
      expect(student.currentClassId, isNull);
      expect(student.name, 'New Student');
      expect(student.membershipId, isNotNull);
      expect(student.membershipStatus, 'pending');

      final cached = await local.findById(student.id);
      expect(cached?.approvalStatus, 'pending');
      expect(cached?.proposedClassId, 'class-1');

      final pending = await queue.pending();
      expect(pending.length, 2);
      final studentOperation = pending.firstWhere((op) => op.entityType == 'student');
      final membershipOperation = pending.firstWhere((op) => op.entityType == 'service_student');
      expect(studentOperation.operationType, 'insert');
      expect(membershipOperation.operationType, 'upsert');

      final payload =
          jsonDecode(studentOperation.payloadJson) as Map<String, dynamic>;
      final membershipPayload =
          jsonDecode(membershipOperation.payloadJson) as Map<String, dynamic>;
      expect(payload['id'], student.id);
      expect(payload['service_id'], 'service-1');
      expect(payload['proposed_class_id'], 'class-1');
      expect(payload['approval_status'], 'pending');
      expect(membershipPayload['student_id'], student.id);
      expect(membershipPayload['id'], student.membershipId);
      expect(membershipPayload['status'], 'pending');
    },
  );
}
