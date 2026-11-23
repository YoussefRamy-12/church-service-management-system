import 'dart:convert';

import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'sync_operation.dart';

class SyncConflictItem {
  const SyncConflictItem({
    required this.operationId,
    required this.entityType,
    required this.operationType,
    required this.payloadJson,
    required this.createdAt,
  });

  final String operationId;
  final String entityType;
  final String operationType;
  final String payloadJson;
  final DateTime createdAt;
}

class SyncQueueRepository {
  SyncQueueRepository(this._db, {bool enabled = true})
      : _enabled = enabled;

  final AppDatabase _db;
  final bool _enabled;

  bool get isEnabled => _enabled;

  Future<void> enqueue(SyncOperation operation) async {
    if (!_enabled) {
      throw StateError(
        'Offline sync is disabled. Mutations cannot be queued.',
      );
    }
    await _enqueue(operation);
  }

  /// Inserts one queue row. SQLite's implicit rowid is the authoritative
  /// insertion sequence; DateTime precision is not sufficient for FIFO order.
  Future<void> _enqueue(SyncOperation operation) async {
    await _db
        .into(_db.syncQueueEntries)
        .insertOnConflictUpdate(
          SyncQueueEntriesCompanion.insert(
            operationId: operation.operationId,
            entityType: operation.entityType,
            operationType: operation.operationType,
            payloadJson: operation.payloadJson,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Replaces older pending snapshots for the same entity before enqueueing
  /// the latest full snapshot. A fresh operation ID is intentional: if an
  /// older snapshot is already being replayed by SyncEngine, its completion
  /// must not delete the newly queued snapshot.
  Future<void> enqueueReplacingEntity({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
  }) async {
    if (!_enabled) {
      throw StateError(
        'Offline sync is disabled. Mutations cannot be queued.',
      );
    }
    if (operation.entityType != entityType) {
      throw ArgumentError('Replacement entity type does not match operation.');
    }

    await _db.transaction(() async {
      final existing = await (_db.select(_db.syncQueueEntries)
            ..where(
              (t) =>
                  t.entityType.equals(entityType) &
                  t.status.isIn(['pending', 'conflict']),
            ))
          .get();

      for (final row in existing) {
        final payload = decode(row.payloadJson);
        if (payload['id'] == entityId) {
          await (_db.delete(_db.syncQueueEntries)
                ..where((t) => t.operationId.equals(row.operationId)))
              .go();
        }
      }

      await _enqueue(operation);
    });
  }

  Stream<List<SyncConflictItem>> watchConflicts() {
    return (_db.select(_db.syncQueueEntries)
          ..where((t) => t.status.equals('conflict'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => SyncConflictItem(
                  operationId: row.operationId,
                  entityType: row.entityType,
                  operationType: row.operationType,
                  payloadJson: row.payloadJson,
                  createdAt: row.createdAt,
                ),
              )
              .toList(),
        );
  }

  Future<void> retryConflict(String operationId) async {
    if (!_enabled) return;
    await (_db.update(
      _db.syncQueueEntries,
    )..where((t) => t.operationId.equals(operationId))).write(
      const SyncQueueEntriesCompanion(
        status: Value('pending'),
        attempts: Value(0),
        lastAttemptAt: Value.absent(),
      ),
    );
  }

  Future<void> retryAllConflicts() async {
    if (!_enabled) return;
    await (_db.update(
      _db.syncQueueEntries,
    )..where((t) => t.status.equals('conflict'))).write(
      const SyncQueueEntriesCompanion(
        status: Value('pending'),
        attempts: Value(0),
        lastAttemptAt: Value.absent(),
      ),
    );
  }

  /// Meeting inserts describe a service-wide resource. Re-check these at the
  /// next online sync because another device may already have created it.
  Future<void> retryMeetingConflicts() async {
    if (!_enabled) return;
    await (_db.update(_db.syncQueueEntries)..where(
          (t) => t.status.equals('conflict') & t.entityType.equals('meeting'),
        ))
        .write(
          const SyncQueueEntriesCompanion(
            status: Value('pending'),
            attempts: Value(0),
            lastAttemptAt: Value.absent(),
          ),
        );
  }

  Future<List<SyncOperation>> pending() async {
    if (!_enabled) {
      return const [];
    }
    final rows = await _db
        .customSelect(
          'SELECT operation_id, entity_type, operation_type, payload_json '
          'FROM sync_queue_entries WHERE status = ? ORDER BY rowid ASC',
          variables: [Variable.withString('pending')],
          readsFrom: {_db.syncQueueEntries},
        )
        .get();
    return rows
        .map(
          (row) => SyncOperation(
            operationId: row.read<String>('operation_id'),
            entityType: row.read<String>('entity_type'),
            operationType: row.read<String>('operation_type'),
            payloadJson: row.read<String>('payload_json'),
          ),
        )
        .toList();
  }

  Future<void> markDone(String operationId) async {
    await (_db.delete(
      _db.syncQueueEntries,
    )..where((t) => t.operationId.equals(operationId))).go();
  }

  Future<void> markConflict(String operationId) async {
    await (_db.update(
      _db.syncQueueEntries,
    )..where((t) => t.operationId.equals(operationId))).write(
      const SyncQueueEntriesCompanion(
        status: Value('conflict'),
        lastAttemptAt: Value.absent(),
      ),
    );
  }

  Future<void> markRetry(String operationId) async {
    final row = await (_db.select(
      _db.syncQueueEntries,
    )..where((t) => t.operationId.equals(operationId))).getSingleOrNull();
    if (row == null) return;
    await (_db.update(
      _db.syncQueueEntries,
    )..where((t) => t.operationId.equals(operationId))).write(
      SyncQueueEntriesCompanion(
        attempts: Value(row.attempts + 1),
        lastAttemptAt: Value(DateTime.now()),
        status: const Value('pending'),
      ),
    );
  }

  Future<int> countByStatus(String status) async {
    final rows = await (_db.select(
      _db.syncQueueEntries,
    )..where((t) => t.status.equals(status))).get();
    return rows.length;
  }

  Stream<int> watchCountByStatus(String status) => (_db.select(
    _db.syncQueueEntries,
  )..where((t) => t.status.equals(status))).watch().map((rows) => rows.length);

  Map<String, dynamic> decode(String payload) =>
      jsonDecode(payload) as Map<String, dynamic>;
}
