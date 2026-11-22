import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';
import '../sync_conflict_exception.dart';
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
    final meetingId = payload['meeting_id'] as String;
    final studentId = payload['student_id'] as String;
    final meeting = await client
        .from('meetings')
        .select('service_id')
        .eq('id', meetingId)
        .single();
    final serviceId = payload['service_id'] as String? ??
        meeting['service_id'] as String;
    if (serviceId != meeting['service_id']) {
      throw const SyncConflictException(
        'Attendance meeting and service membership belong to different services.',
      );
    }

    var serviceStudentId = payload['service_student_id'] as String?;
    if (serviceStudentId == null) {
      // Compatibility for operations queued by older app versions.
      final membership = await client
          .from('service_students')
          .select('id')
          .eq('student_id', studentId)
          .eq('service_id', serviceId)
          .maybeSingle();
      serviceStudentId = membership?['id'] as String?;
    }
    if (serviceStudentId == null) {
      throw const SyncConflictException(
        'Attendance cannot sync because the service student membership no longer exists.',
      );
    }

    final recordedBy = await resolveAttendanceRecorderProfileId(
      client,
      meetingId: meetingId,
      preferredProfileId: payload['recorded_by'] as String,
    );
    await client.from('attendance_records').upsert({
      'id': payload['id'],
      'meeting_id': meetingId,
      'student_id': studentId,
      'service_id': serviceId,
      'service_student_id': serviceStudentId,
      'class_id_at_attendance': payload['class_id_at_attendance'],
      'checked_in_at': DateTime.parse(
        payload['checked_in_at'] as String,
      ).toUtc().toIso8601String(),
      'recorded_by': recordedBy,
      'client_operation_id': operation.operationId,
    }, onConflict: 'meeting_id,student_id');
  }
}
