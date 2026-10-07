import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/follow_up/data/local_follow_up_repository.dart';
import 'package:church_service_management_system/features/follow_up/data/offline_first_follow_up_repository.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late OfflineFirstFollowUpRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    repo = OfflineFirstFollowUpRepository(
      local: LocalFollowUpRepository(db),
      queue: queue,
    );
  });

  tearDown(() async => db.close());

  test('follow-up is immediately available locally and queued for sync', () async {
    final record = await repo.create(
      studentId: 'student-1',
      createdBy: 'servant-1',
      followUpDate: '2026-10-07',
      contactStatus: 'contacted',
      contactMethod: 'phone',
      parentResponse: 'Will attend next week',
      actionRequired: 'Monitor attendance',
      anotherFollowUpNeeded: true,
      nextFollowUpDate: '2026-10-14',
    );

    final local = await repo.watchForStudent('student-1').firstWhere(
      (items) => items.isNotEmpty,
    );
    final pending = await queue.pending();
    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;

    expect(local.single.id, record.id);
    expect(local.single.parentResponse, 'Will attend next week');
    expect(local.single.anotherFollowUpNeeded, isTrue);
    expect(local.single.nextFollowUpDate, '2026-10-14');
    expect(pending, hasLength(1));
    expect(pending.single.entityType, 'follow_up');
    expect(pending.single.operationType, 'insert');
    expect(payload['client_operation_id'], record.clientOperationId);
    expect(payload['student_id'], 'student-1');
    expect(payload['contact_method'], 'phone');
  });

  test('follow-up history is ordered newest first', () async {
    await repo.create(
      studentId: 'student-1',
      createdBy: 'servant-1',
      followUpDate: '2026-10-01',
      contactStatus: 'no_answer',
    );
    await repo.create(
      studentId: 'student-1',
      createdBy: 'servant-1',
      followUpDate: '2026-10-07',
      contactStatus: 'contacted',
    );

    final rows = await repo.watchForStudent('student-1').firstWhere(
      (items) => items.length == 2,
    );

    expect(rows.map((item) => item.followUpDate), ['2026-10-07', '2026-10-01']);
  });

  test('follow-up records for another student are excluded', () async {
    await repo.create(
      studentId: 'student-1',
      createdBy: 'servant-1',
      followUpDate: '2026-10-07',
      contactStatus: 'contacted',
    );
    await repo.create(
      studentId: 'student-2',
      createdBy: 'servant-1',
      followUpDate: '2026-10-07',
      contactStatus: 'contacted',
    );

    final rows = await repo.watchForStudent('student-1').firstWhere(
      (items) => items.length == 1,
    );

    expect(rows.single.studentId, 'student-1');
  });
}
