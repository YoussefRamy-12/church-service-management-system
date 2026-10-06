import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_queue_repository.dart';
import 'sync_status.dart';
import 'sync_operation.dart';

class SyncConflictException implements Exception {
  const SyncConflictException(this.message);
  final String message;
}

class SyncEngine {
  SyncEngine({required this.queue, required this.client, Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final SyncQueueRepository queue;
  final SupabaseClient client;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _running = false;
  SyncStatus status = SyncStatus.idle;
  Object? lastError;

  Future<void> start() async {
    _subscription ??= _connectivity.onConnectivityChanged.listen((_) => syncNow());
    await syncNow();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> syncNow() async {
    if (_running) return;
    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) { status = SyncStatus.offline; return; }
    status = SyncStatus.syncing;
    lastError = null;
    _running = true;
    try {
      for (final operation in await queue.pending()) {
        try {
          await _apply(operation);
          await queue.markDone(operation.operationId);
        } catch (error) {
          if (error is PostgrestException && (error.code == '23505' || error.code == '23503' || error.code == '42501')) {
            await queue.markConflict(operation.operationId);
          } else if (error is SyncConflictException) {
            await queue.markConflict(operation.operationId);
          } else {
            await queue.markRetry(operation.operationId);
          }
        }
      }
    } catch (error) {
      lastError = error;
      status = SyncStatus.error;
    } finally {
      _running = false;
      if (lastError == null) status = SyncStatus.idle;
    }
  }

  Future<void> _apply(SyncOperation operation) async {
    final payload = queue.decode(operation.payloadJson);
    switch (operation.entityType) {
      case 'meeting':
        await client.from('meetings').insert(payload);
        return;
      case 'student':
        if (operation.operationType == 'insert') {
          await client.from('students').insert(payload);
          return;
        }
        if (operation.operationType == 'update') {
          final rows = await client.from('students').update(payload).eq('id', payload['id'] as String).select('id');
          if (rows.isEmpty) {
            throw const SyncConflictException('Student update was rejected or is no longer accessible.');
          }
          return;
        }
        throw UnsupportedError('Unsupported student operation: ' + operation.operationType);
        return;
      case 'attendance':
        await client.from('attendance_records').upsert({
          'id': payload['id'],
          'meeting_id': payload['meeting_id'],
          'student_id': payload['student_id'],
          'class_id_at_attendance': payload['class_id_at_attendance'],
          'checked_in_at': payload['checked_in_at'],
          'recorded_by': payload['recorded_by'],
          'client_operation_id': operation.operationId,
        }, onConflict: 'client_operation_id');
        return;
      default:
        throw UnsupportedError('Unsupported sync entity: ${operation.entityType}');
    }
  }
}
