import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';

/// Sync handler for 'follow_up_activity' entities.
class FollowUpActivitySyncHandler implements EntitySyncHandler {
  const FollowUpActivitySyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'follow_up_activity';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    await client.from('follow_up_activities').insert(payload);
  }
}

