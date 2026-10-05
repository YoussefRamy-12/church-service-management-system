import 'dart:convert';

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'sync_operation.dart';

class SyncQueueRepository {
  SyncQueueRepository(this._db);
  final AppDatabase _db;

  Future<void> enqueue(SyncOperation operation) async {
    await _db.into(_db.syncQueueEntries).insertOnConflictUpdate(
      SyncQueueEntriesCompanion.insert(
        operationId: operation.operationId,
        entityType: operation.entityType,
        operationType: operation.operationType,
        payloadJson: operation.payloadJson,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<SyncOperation>> pending() async {
    final rows = await (_db.select(_db.syncQueueEntries)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
    return rows.map((row) => SyncOperation(
      operationId: row.operationId,
      entityType: row.entityType,
      operationType: row.operationType,
      payloadJson: row.payloadJson,
    )).toList();
  }

  Future<void> markDone(String operationId) async {
    await (_db.delete(_db.syncQueueEntries)
      ..where((t) => t.operationId.equals(operationId))).go();
  }

  Future<void> markConflict(String operationId) async {
    await (_db.update(_db.syncQueueEntries)..where((t) => t.operationId.equals(operationId))).write(
      const SyncQueueEntriesCompanion(status: Value('conflict'), lastAttemptAt: Value.absent()),
    );
  }

  Future<void> markRetry(String operationId) async {
    final row = await (_db.select(_db.syncQueueEntries)
      ..where((t) => t.operationId.equals(operationId))).getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.syncQueueEntries)
      ..where((t) => t.operationId.equals(operationId))).write(
      SyncQueueEntriesCompanion(
        attempts: Value(row.attempts + 1),
        lastAttemptAt: Value(DateTime.now()),
        status: const Value('pending'),
      ),
    );
  }

  Future<int> countByStatus(String status) async => await ((_db.select(_db.syncQueueEntries)..where((t) => t.status.equals(status))).get()).length;

  Stream<int> watchCountByStatus(String status) => (_db.select(_db.syncQueueEntries)..where((t) => t.status.equals(status))).watch().map((rows) => rows.length);

  Map<String, dynamic> decode(String payload) => jsonDecode(payload) as Map<String, dynamic>;
}
