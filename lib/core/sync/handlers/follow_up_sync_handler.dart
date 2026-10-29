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
    if (operation.operationType == 'update') {
      final id = payload['id'] as String?;
      if (id == null) throw const FormatException('Follow-up update requires an id.');
      final changes = Map<String, dynamic>.from(payload)..remove('id');
      await client.from('follow_up_records').update(changes).eq('id', id);
      return;
    }
    await client.from('follow_up_records').insert(payload);
  }
}
