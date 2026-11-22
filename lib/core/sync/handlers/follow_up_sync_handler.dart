import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';
import '../sync_conflict_exception.dart';

/// Sync handler for 'follow_up' entities.
class FollowUpSyncHandler implements EntitySyncHandler {
  const FollowUpSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'follow_up';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    final studentId = payload['student_id'] as String;
    final createdBy = payload['created_by'] as String;
    final profile = await client
        .from('servant_profiles')
        .select('service_id')
        .eq('id', createdBy)
        .single();
    final profileServiceId = profile['service_id'] as String;
    final serviceId = payload['service_id'] as String? ?? profileServiceId;
    if (serviceId != profileServiceId) {
      throw const SyncConflictException(
        'Follow-up creator and student membership belong to different services.',
      );
    }

    var serviceStudentId = payload['service_student_id'] as String?;
    if (serviceStudentId?.isEmpty == true) serviceStudentId = null;
    if (serviceStudentId == null) {
      // Resolve old queued records using the creator's service, never the
      // global identity's legacy owner-service field.
      final membership = await client
          .from('service_students')
          .select('id')
          .eq('student_id', studentId)
          .eq('service_id', serviceId)
          .maybeSingle();
      serviceStudentId = membership?['id'] as String?;
    }
    if (serviceStudentId == null) {
      throw const SyncConflictException(
        'Follow-up cannot sync because the service student membership no longer exists.',
      );
    }

    await client.from('follow_up_records').upsert({
      ...payload,
      'service_id': serviceId,
      'service_student_id': serviceStudentId,
      'client_operation_id': operation.operationId,
    }, onConflict: 'client_operation_id');
  }
}
