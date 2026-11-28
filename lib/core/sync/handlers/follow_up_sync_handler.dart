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
    final authUserId = client.auth.currentUser?.id;
    if (authUserId == null) {
      throw StateError('A signed-in account is required to sync follow-up.');
    }
    final profile = await client
        .from('servant_profiles')
        .select('service_id')
        .eq('id', createdBy)
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    if (profile == null) {
      // The queue may belong to a different account on a shared device.
      // Defer it instead of replaying it as the newly signed-in user or
      // converting a temporary account mismatch into a permanent conflict.
      throw StateError(
        'Queued follow-up belongs to another account; sync it after that account signs in.',
      );
    }
    final profileServiceId = profile['service_id'] as String;
    final serviceId = payload['service_id'] as String? ?? profileServiceId;
    if (serviceId != profileServiceId) {
      throw const SyncConflictException(
        'Follow-up creator and student membership belong to different services.',
      );
    }

    var serviceStudentId = payload['service_student_id'] as String?;
    if (serviceStudentId?.isEmpty == true) serviceStudentId = null;

    // Resolve legacy queue items by student + creator service. For current
    // items, validate the supplied membership ID against both dimensions.
    final membershipQuery = client
        .from('service_students')
        .select('id')
        .eq('student_id', studentId)
        .eq('service_id', serviceId);
    final membership = serviceStudentId == null
        ? await membershipQuery.maybeSingle()
        : await membershipQuery.eq('id', serviceStudentId).maybeSingle();
    serviceStudentId = membership?['id'] as String?;

    if (serviceStudentId == null) {
      throw const SyncConflictException(
        'Follow-up cannot sync because its membership does not belong to the creator service and student.',
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
