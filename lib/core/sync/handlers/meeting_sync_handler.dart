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
    // A schedule may have one meeting on a given date; distinct named
    // schedules are allowed to meet on the same date.
    final rows = await client
        .from('meetings')
        .select('id, schedule_id, name')
        .eq('service_id', payload['service_id'] as String)
        .eq('meeting_date', payload['meeting_date'] as String);
    final scheduleId = payload['schedule_id'] as String?;
    final name = (payload['name'] as String?) ?? 'اجتماع الخدمة';
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final sameSchedule = scheduleId != null
          ? row['schedule_id'] == scheduleId
          : row['schedule_id'] == null && row['name'] == name;
      if (sameSchedule) return;
    }
    await client.from('meetings').upsert({
      ...payload,
      'name': name,
      'schedule_id': scheduleId,
    }, onConflict: 'id');
  }
}
