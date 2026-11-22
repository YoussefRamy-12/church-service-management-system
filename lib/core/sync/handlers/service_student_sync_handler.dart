import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_conflict_exception.dart';
import '../sync_operation.dart';

/// Syncs service membership independently from the global student identity.
class ServiceStudentSyncHandler implements EntitySyncHandler {
  const ServiceStudentSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'service_student';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    final membershipId = payload['id'] as String?;

    if (operation.operationType == 'delete') {
      if (membershipId == null) {
        throw const SyncConflictException('Membership ID is required.');
      }
      final rows = await client
          .from('service_students')
          .update({'status': 'inactive'})
          .eq('id', membershipId)
          .select('id');
      if (rows.isEmpty) {
        throw const SyncConflictException(
          'Membership archive was rejected or is no longer accessible.',
        );
      }
      return;
    }

    if (operation.operationType == 'insert' ||
        operation.operationType == 'update' ||
        operation.operationType == 'upsert') {
      final rows = await client
          .from('service_students')
          .upsert(payload, onConflict: 'student_id,service_id')
          .select('id');
      if (rows.isEmpty) {
        throw const SyncConflictException(
          'Membership upsert was rejected or is no longer accessible.',
        );
      }
      return;
    }

    throw UnsupportedError(
      'Unsupported service membership operation: ${operation.operationType}',
    );
  }
}
