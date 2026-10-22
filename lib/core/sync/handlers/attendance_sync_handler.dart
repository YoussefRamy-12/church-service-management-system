import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';
import '../../../features/attendance/data/attendance_profile_resolver.dart';

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
    final recordedBy = await resolveAttendanceRecorderProfileId(
      client,
      meetingId: payload['meeting_id'] as String,
      preferredProfileId: payload['recorded_by'] as String,
    );
    await client.from('attendance_records').upsert({
      'id': payload['id'],
      'meeting_id': payload['meeting_id'],
      'student_id': payload['student_id'],
      'class_id_at_attendance': payload['class_id_at_attendance'],
      'checked_in_at': payload['checked_in_at'],
      'recorded_by': recordedBy,
      'client_operation_id': operation.operationId,
    }, onConflict: 'meeting_id,student_id');
  }
}
