import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/attendance_record.dart';
import '../domain/repositories/attendance_repository.dart';
import 'local_attendance_repository.dart';

class OfflineFirstAttendanceRepository implements AttendanceRepository {
  OfflineFirstAttendanceRepository({required this.local, required this.queue});
  final LocalAttendanceRepository local;
  final SyncQueueRepository queue;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId) =>
      local.watchForMeeting(meetingId);

  @override
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  }) async {
    final record = await local.checkIn(
      meetingId: meetingId, studentId: studentId,
      classIdAtAttendance: classIdAtAttendance,
      recordedBy: recordedBy, checkedInAt: checkedInAt,
    );
    await queue.enqueue(SyncOperation(
      operationId: record.clientOperationId,
      entityType: 'attendance',
      operationType: 'upsert',
      payloadJson: jsonEncode({
        'id': record.id,
        'meeting_id': record.meetingId,
        'student_id': record.studentId,
        'class_id_at_attendance': record.classIdAtAttendance,
        'checked_in_at': record.checkedInAt.toIso8601String(),
        'recorded_by': record.recordedBy,
      }),
    ));
    return record;
  }
}
