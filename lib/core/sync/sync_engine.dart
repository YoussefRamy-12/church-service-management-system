import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_queue_repository.dart';
import 'sync_operation.dart';

class SyncEngine {
  SyncEngine({required this.queue, required this.client, Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final SyncQueueRepository queue;
  final SupabaseClient client;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _running = false;

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
    if (results.every((r) => r == ConnectivityResult.none)) return;
    _running = true;
    try {
      for (final operation in await queue.pending()) {
        try {
          await _apply(operation);
          await queue.markDone(operation.operationId);
        } catch (_) {
          await queue.markRetry(operation.operationId);
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _apply(SyncOperation operation) async {
    final payload = queue.decode(operation.payloadJson);
    switch (operation.entityType) {
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
        throw UnsupportedError('Unsupported sync entity: ' + operation.entityType);
    }
  }
}
