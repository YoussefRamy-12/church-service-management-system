import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/features/students/data/local_service_student_repository.dart';
import 'package:church_service_management_system/features/students/domain/entities/service_student.dart';

class _RecordingTransport implements SyncTransport {
  final List<SyncOperation> applied = [];

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    applied.add(operation);
  }
}

class _BlockingTransport implements SyncTransport {
  final Completer<void> firstApplyStarted = Completer<void>();
  final Completer<void> releaseFirstApply = Completer<void>();
  int calls = 0;

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    calls++;
    if (calls == 1) {
      firstApplyStarted.complete();
      await releaseFirstApply.future;
    }
  }
}

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late LocalServiceStudentRepository memberships;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    memberships = LocalServiceStudentRepository(db, queue);
  });

  tearDown(() async {
    await db.close();
  });

  test('service directory RPC maps membership and global identity fields', () {
    final membership = ServiceStudent.fromMap({
      'membership_id': 'membership-rpc-1',
      'student_id': 'global-student-rpc-1',
      'service_id': 'service-b',
      'class_id': 'class-b',
      'proposed_class_id': null,
      'enrollment_date': '2026-11-20T00:00:00.000Z',
      'membership_status': 'active',
      'school': 'مدرسة',
      'grade': 'السادس',
      'is_deacon': false,
      'membership_notes': 'ملاحظة خاصة بالخدمة',
      'student_name': 'تلميذ مشترك',
      'birth_date': '2015-03-12',
      'phone': '01000000000',
      'photo_path': null,
    });

    expect(membership.id, 'membership-rpc-1');
    expect(membership.status, 'active');
    expect(membership.studentName, 'تلميذ مشترك');
    expect(membership.birthDate, DateTime(2015, 3, 12));
    expect(membership.notes, 'ملاحظة خاصة بالخدمة');
  });

  test('directory projection maps inactive membership without changing global identity', () {
    final membership = ServiceStudent.fromMap({
      'membership_id': 'membership-inactive-1',
      'student_id': 'global-student-1',
      'service_id': 'service-a',
      'class_id': null,
      'proposed_class_id': null,
      'enrollment_date': '2026-11-20T00:00:00.000Z',
      'membership_status': 'inactive',
      'school': null,
      'grade': null,
      'is_deacon': false,
      'membership_notes': null,
      'student_name': 'تلميذ مؤرشف',
      'birth_date': '2015-03-12',
      'phone': null,
      'photo_path': null,
    });
    expect(membership.id, 'membership-inactive-1');
    expect(membership.studentId, 'global-student-1');
    expect(membership.status, 'inactive');
    expect(membership.studentName, 'تلميذ مؤرشف');
  });

  test('membership remains available offline and queues an idempotent sync payload', () async {
    final membership = ServiceStudent(
      id: 'membership-a-1',
      studentId: 'global-student-1',
      serviceId: 'service-a',
      classId: 'class-a',
      enrollmentDate: DateTime.utc(2026, 11, 20),
      status: 'active',
      school: 'مدرسة الخدمة أ',
      grade: 'الخامس',
      studentName: 'طالب متعدد الخدمات',
      birthDate: DateTime(2015, 3, 12),
      phone: '01000000000',
    );

    await memberships.saveOffline(membership);

    final cached = await memberships.findById(membership.id);
    final pending = await queue.pending();

    expect(cached, isNotNull);
    expect(cached!.studentId, membership.studentId);
    expect(cached.serviceId, 'service-a');
    expect(cached.classId, 'class-a');
    expect(cached.studentName, 'طالب متعدد الخدمات');
    expect(cached.birthDate, DateTime(2015, 3, 12));
    expect(cached.phone, '01000000000');
    expect(pending, hasLength(1));
    expect(pending.single.entityType, 'service_student');
    expect(pending.single.operationType, 'upsert');

    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;
    expect(payload['id'], membership.id);
    expect(payload['student_id'], membership.studentId);
    expect(payload['service_id'], membership.serviceId);
  });

  test('same global student can have isolated cached memberships in two services', () async {
    await memberships.cache([
      ServiceStudent(
        id: 'membership-a-2',
        studentId: 'global-student-2',
        serviceId: 'service-a',
        enrollmentDate: DateTime.utc(2026, 11, 20),
        status: 'active',
      ),
      ServiceStudent(
        id: 'membership-b-2',
        studentId: 'global-student-2',
        serviceId: 'service-b',
        enrollmentDate: DateTime.utc(2026, 11, 21),
        status: 'pending',
      ),
    ]);

    final serviceA = await memberships.watchForService('service-a').first;
    final serviceB = await memberships.watchForService('service-b').first;

    expect(serviceA.map((m) => m.id), ['membership-a-2']);
    expect(serviceB.map((m) => m.id), ['membership-b-2']);
    expect(serviceA.single.studentId, serviceB.single.studentId);
  });

  test('online sync dispatches queued service membership operations', () async {
    final membership = ServiceStudent(
      id: 'membership-sync-1',
      studentId: 'global-student-sync-1',
      serviceId: 'service-a',
      enrollmentDate: DateTime.utc(2026, 11, 20),
      status: 'active',
    );
    await memberships.saveOffline(membership);

    final transport = _RecordingTransport();
    final engine = SyncEngine(
      queue: queue,
      transport: transport,
      connectivityChecker: () async => [ConnectivityResult.wifi],
    );
    try {
      await engine.syncNow();
      expect(transport.applied, hasLength(1));
      expect(transport.applied.single.entityType, 'service_student');
      expect(await queue.pending(), isEmpty);
    } finally {
      engine.dispose();
    }
  });

  test('offline sync preserves queued service membership operations', () async {
    final membership = ServiceStudent(
      id: 'membership-offline-1',
      studentId: 'global-student-offline-1',
      serviceId: 'service-a',
      enrollmentDate: DateTime.utc(2026, 11, 20),
      status: 'active',
    );
    await memberships.saveOffline(membership);

    final transport = _RecordingTransport();
    final engine = SyncEngine(
      queue: queue,
      transport: transport,
      connectivityChecker: () async => [ConnectivityResult.none],
    );
    try {
      await engine.syncNow();
      expect(transport.applied, isEmpty);
      expect(await queue.pending(), hasLength(1));
      expect((await queue.pending()).single.entityType, 'service_student');
    } finally {
      engine.dispose();
    }
  });

  test(
    'archive during an in-flight membership upload preserves the newer snapshot',
    () async {
      final membership = ServiceStudent(
        id: 'membership-race-1',
        studentId: 'global-student-race-1',
        serviceId: 'service-a',
        enrollmentDate: DateTime.utc(2026, 11, 20),
        status: 'active',
      );
      await memberships.saveOffline(membership);
      final originalOperation = (await queue.pending()).single;

      final transport = _BlockingTransport();
      final engine = SyncEngine(
        queue: queue,
        transport: transport,
        connectivityChecker: () async => [ConnectivityResult.wifi],
      );
      try {
        final firstSync = engine.syncNow();
        await transport.firstApplyStarted.future;

        await memberships.archiveOffline(membership);
        final replacement = (await queue.pending()).single;
        final replacementPayload =
            jsonDecode(replacement.payloadJson) as Map<String, dynamic>;

        expect(replacement.operationId, isNot(originalOperation.operationId));
        expect(replacementPayload['status'], 'inactive');

        transport.releaseFirstApply.complete();
        await firstSync;

        // Completing the older in-flight operation must not delete the
        // replacement operation that carries the archived membership.
        final stillPending = await queue.pending();
        expect(stillPending, hasLength(1));
        expect(stillPending.single.operationId, replacement.operationId);
        expect(
          (jsonDecode(stillPending.single.payloadJson)
              as Map<String, dynamic>)['status'],
          'inactive',
        );

        await engine.syncNow();
        expect(await queue.pending(), isEmpty);
        expect(transport.calls, 2);
      } finally {
        if (!transport.releaseFirstApply.isCompleted) {
          transport.releaseFirstApply.complete();
        }
        engine.dispose();
      }
    },
  );

  test('offline archive changes only membership status and queues it', () async {
    final membership = ServiceStudent(
      id: 'membership-archive-1',
      studentId: 'global-student-3',
      serviceId: 'service-a',
      enrollmentDate: DateTime.utc(2026, 11, 20),
      status: 'active',
    );

    await memberships.saveOffline(membership);
    await memberships.archiveOffline(membership);

    final archived = await memberships.findById(membership.id);
    final pending = await queue.pending();

    expect(archived?.status, 'inactive');
    expect(pending, hasLength(1));
    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;
    expect(payload['status'], 'inactive');
    expect(payload['id'], membership.id);
    expect(payload['student_id'], membership.studentId);
    expect(payload['service_id'], membership.serviceId);
  });
}
