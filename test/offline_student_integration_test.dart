import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/students/data/local_student_repository.dart';
import 'package:church_service_management_system/features/students/data/offline_first_student_repository.dart';
import 'package:church_service_management_system/features/students/data/supabase_student_repository.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';

Student _student({
  String id = 'student-1',
  String name = 'Peter',
  String approvalStatus = 'approved',
  String? currentClassId = 'class-1',
  String? proposedClassId,
}) {
  return Student(
    id: id,
    serviceId: 'service-1',
    currentClassId: currentClassId,
    proposedClassId: proposedClassId,
    name: name,
    approvalStatus: approvalStatus,
    birthDate: DateTime(2014, 5, 10),
    enrollmentAt: DateTime(2026, 9, 1),
  );
}

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late OfflineFirstStudentRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    final remote = SupabaseStudentRepository(
      SupabaseClient('https://example.supabase.co', 'test-key'),
    );
    repo = OfflineFirstStudentRepository(
      local: LocalStudentRepository(db),
      remote: remote,
      queue: queue,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('offline student update changes local state and queues the complete payload', () async {
    await repo.local.cacheStudents([_student()]);

    final updated = await repo.updateStudent(
      studentId: 'student-1',
      name: '  Peter Updated  ',
      phone: '01000000000',
      school: 'School',
      grade: '6',
      notes: 'Needs follow-up',
    );

    final pending = await queue.pending();
    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;

    expect(updated.name, 'Peter Updated');
    expect(await repo.local.findById('student-1'), isNotNull);
    expect(pending, hasLength(1));
    expect(pending.single.entityType, 'student');
    expect(pending.single.operationType, 'update');
    expect(payload['id'], 'student-1');
    expect(payload['name'], 'Peter Updated');
    expect(payload['current_class_id'], 'class-1');
    expect(payload['approval_status'], 'approved');
    expect(payload['phone'], '01000000000');
    expect(payload['notes'], 'Needs follow-up');
  });

  test('offline pending approval moves the student and queues the approved state', () async {
    await repo.local.cacheStudents([
      _student(
        approvalStatus: 'pending',
        currentClassId: null,
        proposedClassId: 'class-2',
      ),
    ]);

    final approved = await repo.approvePending('student-1');

    final pending = await queue.pending();
    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;

    expect(approved.approvalStatus, 'approved');
    expect(approved.currentClassId, 'class-2');
    expect(approved.proposedClassId, isNull);
    expect(pending, hasLength(1));
    expect(payload['approval_status'], 'approved');
    expect(payload['current_class_id'], 'class-2');
    expect(payload['proposed_class_id'], isNull);
  });

  test('multiple offline student edits create independently retryable operations', () async {
    await repo.local.cacheStudents([
      _student(id: 'student-1'),
      _student(id: 'student-2', name: 'Mark'),
    ]);

    await repo.updateStudent(studentId: 'student-1', name: 'Peter New');
    await repo.updateStudent(studentId: 'student-2', name: 'Mark New');

    final pending = await queue.pending();

    expect(pending, hasLength(2));
    expect(pending.map((op) => op.operationId).toSet(), hasLength(2));

    final names = pending
        .map((op) => (jsonDecode(op.payloadJson) as Map<String, dynamic>)['name'])
        .toSet();
    expect(names, containsAll(<String>['Peter New', 'Mark New']));
  });
}
