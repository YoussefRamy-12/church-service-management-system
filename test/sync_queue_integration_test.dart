import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('queue preserves FIFO order for pending operations', () async {
    await queue.enqueue(const SyncOperation(
      operationId: 'op-1',
      entityType: 'student',
      operationType: 'update',
      payloadJson: '{"id":"student-1"}',
    ));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await queue.enqueue(const SyncOperation(
      operationId: 'op-2',
      entityType: 'attendance',
      operationType: 'upsert',
      payloadJson: '{"id":"attendance-1"}',
    ));

    final pending = await queue.pending();

    expect(pending.map((e) => e.operationId).toList(), ['op-1', 'op-2']);
  });

  test('retry increments attempts and keeps operation pending', () async {
    await queue.enqueue(const SyncOperation(
      operationId: 'op-1',
      entityType: 'student',
      operationType: 'update',
      payloadJson: '{"id":"student-1"}',
    ));

    await queue.markRetry('op-1');

    final row = await (db.select(db.syncQueueEntries)
          ..where((t) => t.operationId.equals('op-1')))
        .getSingle();

    expect(row.status, 'pending');
    expect(row.attempts, 1);
    expect(row.lastAttemptAt, isNotNull);
  });

  test('conflict can be surfaced and explicitly retried', () async {
    await queue.enqueue(const SyncOperation(
      operationId: 'op-1',
      entityType: 'student',
      operationType: 'update',
      payloadJson: '{"id":"student-1"}',
    ));

    await queue.markConflict('op-1');

    expect(await queue.countByStatus('conflict'), 1);
    expect(await queue.pending(), isEmpty);

    await queue.retryConflict('op-1');

    expect(await queue.countByStatus('conflict'), 0);
    final pending = await queue.pending();
    expect(pending, hasLength(1));
    expect(pending.single.operationId, 'op-1');
  });

  test('queued payload remains valid JSON after persistence', () async {
    const payload = {
      'id': 'student-1',
      'name': 'Peter',
      'approval_status': 'approved',
    };

    await queue.enqueue(SyncOperation(
      operationId: 'op-json',
      entityType: 'student',
      operationType: 'update',
      payloadJson: jsonEncode(payload),
    ));

    final pending = await queue.pending();
    expect(queue.decode(pending.single.payloadJson), payload);
  });
}
