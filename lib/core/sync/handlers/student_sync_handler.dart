import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_conflict_exception.dart';
import '../sync_operation.dart';

/// Sync handler for 'student' entities.
class StudentSyncHandler implements EntitySyncHandler {
  const StudentSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'student';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation.operationType == 'delete') {
      final rows = await client
          .from('students')
          .delete()
          .eq('id', payload['id'] as String)
          .select('id');
      if (rows.isEmpty) {
        throw const SyncConflictException(
          'Student deletion was rejected or is no longer accessible.',
        );
      }
      return;
    }

    if (operation.operationType == 'insert') {
      final sensitiveData = payload.remove('sensitive_data');
      await client.from('students').upsert(payload, onConflict: 'id');
      if (sensitiveData is Map<String, dynamic> &&
          sensitiveData.values.any(
            (value) => value != null && value.toString().trim().isNotEmpty,
          )) {
        await _safeUpsertSensitiveData(
          client,
          payload['id'] as String,
          sensitiveData,
        );
      }
      return;
    }

    if (operation.operationType == 'update') {
      final sensitiveData = payload.remove('sensitive_data');
      final rows = await client
          .from('students')
          .update(payload)
          .eq('id', payload['id'] as String)
          .select('id');
      if (rows.isEmpty) {
        throw const SyncConflictException(
          'Student update was rejected or is no longer accessible.',
        );
      }
      if (sensitiveData is Map<String, dynamic> &&
          sensitiveData.values.any(
            (value) => value != null && value.toString().trim().isNotEmpty,
          )) {
        await _safeUpsertSensitiveData(
          client,
          payload['id'] as String,
          sensitiveData,
        );
      }
      return;
    }

    throw UnsupportedError(
      'Unsupported student operation: ${operation.operationType}',
    );
  }

  static Future<void> _safeUpsertSensitiveData(
    SupabaseClient client,
    String studentId,
    Map<String, dynamic> sensitiveData,
  ) async {
    final payload = <String, dynamic>{
      'student_id': studentId,
      ...sensitiveData,
    };

    while (payload.length > 1) {
      try {
        await client.from('student_sensitive_data').upsert(
              payload,
              onConflict: 'student_id',
            );
        return;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' ||
            e.message.contains('Could not find the column')) {
          final match = RegExp(r"column '([^']+)'").firstMatch(e.message);
          if (match != null) {
            final missingCol = match.group(1);
            if (missingCol != null && payload.containsKey(missingCol)) {
              payload.remove(missingCol);
              continue;
            }
          }
        }
        rethrow;
      }
    }
  }
}
