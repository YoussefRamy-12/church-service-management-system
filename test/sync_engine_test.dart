import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/core/sync/sync_status.dart';

class _FakeTransport implements SyncTransport {
  final List<String> applied = [];
  final Set<String> retryFailures = {};
  final Set<String> conflicts = {};

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    applied.add(operation.operationId);
    if (conflicts.contains(operation.operationId)) {
      throw const SyncConflictException('test conflict');
    }
    if (retryFailures.contains(operation.operationId)) {
      throw StateError('temporary failure');
    }
  }
}

SyncOperation _operation({
  required String id,
  String entityType = 'attendance',
  String operationType = 'upsert',
  Map<String, dynamic> payload = const {'value': 'ok'},
}) {
  return SyncOperation(
    operationId: id,
    entityType: entityType,
    operationType: operationType,
    payloadJson: jsonEncode(payload),
  );
}

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late _FakeTransport transport;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    transport = _FakeTransport();
  });

  tearDown(() async {
    await db.close();
  });

  SyncEngine engine({
    Future<List<ConnectivityResult>> Function()? connectivityChecker,
  }) {
    return SyncEngine(
      queue: queue,
      transport: transport,
      connectivityChecker: connectivityChecker ??
          () async => <ConnectivityResult>[ConnectivityResult.wifi],
    );
  }

  test('syncNow applies pending operations and removes them from the queue', () async {
    await queue.enqueue(_operation(id: 'op-1'));
    await queue.enqueue(_operation(id: 'op-2'));

    final sync = engine();
    await sync.syncNow();

    expect(transport.applied, ['op-1', 'op-2']);
    expect(await queue.pending(), isEmpty);
    expect(await queue.countByStatus('conflict'), 0);
    expect(sync.status, SyncStatus.idle);
    expect(sync.lastError, isNull);
  });

  test('temporary transport failure keeps operation pending and increments retry count', () async {
    transport.retryFailures.add('op-1');
    await queue.enqueue(_operation(id: 'op-1'));

    final sync = engine();
    await sync.syncNow();

    final pending = await queue.pending();
    expect(pending.map((op) => op.operationId), contains('op-1'));
    expect(await queue.countByStatus('conflict'), 0);

    final row = await (db.select(db.syncQueueEntries)
          ..where((t) => t.operationId.equals('op-1')))
        .getSingle();

    expect(row.attempts, 1);
    expect(row.lastAttemptAt, isNotNull);
    expect(row.status, 'pending');
    expect(sync.status, SyncStatus.idle);
  });

  test('sync conflict moves operation out of pending and into conflict state', () async {
    transport.conflicts.add('op-1');
    await queue.enqueue(_operation(id: 'op-1'));

    final sync = engine();
    await sync.syncNow();

    expect(await queue.pending(), isEmpty);
    expect(await queue.countByStatus('conflict'), 1);
    expect(sync.status, SyncStatus.idle);
  });

  test('offline sync does not consume the queue', () async {
    await queue.enqueue(_operation(id: 'op-1'));

    final sync = engine(
      connectivityChecker: () async => <ConnectivityResult>[ConnectivityResult.none],
    );

    await sync.syncNow();

    expect(transport.applied, isEmpty);
    expect(await queue.pending(), hasLength(1));
    expect(sync.status, SyncStatus.offline);
  });

  test('invalid queued JSON is retried instead of being lost', () async {
    await queue.enqueue(
      const SyncOperation(
        operationId: 'op-invalid',
        entityType: 'attendance',
        operationType: 'upsert',
        payloadJson: '{invalid-json',
      ),
    );

    final sync = engine();
    await sync.syncNow();

    expect(await queue.pending(), hasLength(1));

    final row = await (db.select(db.syncQueueEntries)
          ..where((t) => t.operationId.equals('op-invalid')))
        .getSingle();

    expect(row.attempts, 1);
    expect(row.status, 'pending');
    expect(transport.applied, isEmpty);
  });

  test('sync continues after one operation fails', () async {
    transport.retryFailures.add('op-1');
    await queue.enqueue(_operation(id: 'op-1'));
    await queue.enqueue(_operation(id: 'op-2'));

    final sync = engine();
    await sync.syncNow();

    expect(transport.applied, ['op-1', 'op-2']);
    expect(await queue.pending(), hasLength(1));
    expect((await queue.pending()).single.operationId, 'op-1');
  });
}
