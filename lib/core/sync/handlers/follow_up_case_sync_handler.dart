import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';
import '../sync_conflict_exception.dart';

/// Sync handler for 'follow_up_case' entities.
class FollowUpCaseSyncHandler implements EntitySyncHandler {
  const FollowUpCaseSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'follow_up_case';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation.operationType == 'insert') {
      final serviceId = payload['service_id'] as String;
      final studentId = payload['student_id'] as String;
      var membershipId = payload['service_student_id'] as String?;
      if (membershipId?.isEmpty == true) membershipId = null;
      if (membershipId == null) {
        // Resolve case creation queued by older clients against its service.
        final membership = await client
            .from('service_students')
            .select('id')
            .eq('student_id', studentId)
            .eq('service_id', serviceId)
            .maybeSingle();
        membershipId = membership?['id'] as String?;
      }
      if (membershipId == null) {
        throw const SyncConflictException(
          'Follow-up case cannot sync because its service student membership no longer exists.',
        );
      }
      await client.from('follow_up_cases').upsert({
        ...payload,
        'service_student_id': membershipId,
      });
    } else if (operation.operationType == 'update') {
      final id = payload['id'] as String;
      await client.from('follow_up_cases').update(payload).eq('id', id);
    }
  }
}

