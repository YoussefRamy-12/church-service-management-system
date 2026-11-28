import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';

/// Sync handler for 'follow_up_case_assignment' entities.
class FollowUpCaseAssignmentSyncHandler implements EntitySyncHandler {
  const FollowUpCaseAssignmentSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'follow_up_case_assignment';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation.operationType == 'insert') {
      await client.from('follow_up_case_assignments').upsert(payload);
    } else if (operation.operationType == 'update') {
      final id = payload['id'] as String;
      await client.from('follow_up_case_assignments').update(payload).eq('id', id);
    }
  }
}

