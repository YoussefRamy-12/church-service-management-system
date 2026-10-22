import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';

/// Sync handler for 'meeting' entities.
class MeetingSyncHandler implements EntitySyncHandler {
  const MeetingSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'meeting';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    // A service has one shared meeting for a given scheduled date. A
    // meeting created offline becomes a reference to the existing shared
    // meeting if another device has already published that date.
    final existing = await client
        .from('meetings')
        .select('id')
        .eq('service_id', payload['service_id'] as String)
        .eq('meeting_date', payload['meeting_date'] as String)
        .limit(1);
    if (existing.isEmpty) {
      await client.from('meetings').upsert(payload, onConflict: 'id');
    }
  }
}
