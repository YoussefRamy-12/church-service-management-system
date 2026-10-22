import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';

/// Sync handler for 'attendance' entities.
class AttendanceSyncHandler implements EntitySyncHandler {
  const AttendanceSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'attendance';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    await client.from('attendance_records').upsert({
      'id': payload['id'],
      'meeting_id': payload['meeting_id'],
      'student_id': payload['student_id'],
      'class_id_at_attendance': payload['class_id_at_attendance'],
      'checked_in_at': payload['checked_in_at'],
      'recorded_by': payload['recorded_by'],
      'client_operation_id': operation.operationId,
    }, onConflict: 'meeting_id,student_id');
  }
}
