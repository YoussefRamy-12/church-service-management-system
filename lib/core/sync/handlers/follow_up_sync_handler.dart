import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';

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
    await client.from('follow_up_records').insert(payload);
  }
}
