import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/connectivity_service_impl.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/attendance_record.dart';
import '../domain/repositories/attendance_repository.dart';
import 'local_attendance_repository.dart';

class OfflineFirstAttendanceRepository implements AttendanceRepository {
  OfflineFirstAttendanceRepository({
    required this.local,
    required this.queue,
    this.client,
    ConnectivityService? connectivity,
  }) : _connectivity = connectivity ?? ConnectivityServiceImpl();

  final LocalAttendanceRepository local;
  final SyncQueueRepository queue;
  final SupabaseClient? client;
  final ConnectivityService _connectivity;

  @override
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId) =>
      local.watchForMeeting(meetingId);

  @override
  Stream<List<AttendanceRecord>> watchForStudent(String studentId) =>
      local.watchForStudent(studentId);

  @override
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  }) async {
    final record = await local.checkIn(
      meetingId: meetingId,
      studentId: studentId,
      classIdAtAttendance: classIdAtAttendance,
      recordedBy: recordedBy,
      checkedInAt: checkedInAt,
    );
    await _publishOrQueue(record);
    return record;
  }

  @override
  Future<AttendanceRecord> updateCheckedInAt({
    required String attendanceId,
    required DateTime checkedInAt,
  }) async {
    final record = await local.updateCheckedInAt(
      attendanceId: attendanceId,
      checkedInAt: checkedInAt,
    );
    await _publishOrQueue(record);
    return record;
  }

  Future<void> _enqueue(AttendanceRecord record) {
    return queue.enqueue(
      SyncOperation(
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
      ),
    );
  }

  Future<void> _publishOrQueue(AttendanceRecord record) async {
    if (client == null) {
      await _enqueue(record);
      return;
    }
    final isOnline = await _connectivity.isOnline;
    if (isOnline) {
      await client!.from('attendance_records').upsert({
        'id': record.id,
        'meeting_id': record.meetingId,
        'student_id': record.studentId,
        'class_id_at_attendance': record.classIdAtAttendance,
        'checked_in_at': record.checkedInAt.toIso8601String(),
        'recorded_by': record.recordedBy,
        'client_operation_id': record.clientOperationId,
      }, onConflict: 'meeting_id,student_id');
      await local.markSynced(record.id);
      return;
    }
    await _enqueue(record);
  }

  @override
  Future<void> refreshAttendanceForMeeting(String meetingId) async {
    if (client == null) return;
    final isOnline = await _connectivity.isOnline;
    if (!isOnline) return;
    try {
      final rows = await client!
          .from('attendance_records')
          .select()
          .eq('meeting_id', meetingId);
      for (final row in rows) {
        final record = AttendanceRecord(
          id: row['id'] as String,
          meetingId: row['meeting_id'] as String,
          studentId: row['student_id'] as String,
          classIdAtAttendance: row['class_id_at_attendance'] as String,
          checkedInAt: DateTime.parse(row['checked_in_at'] as String),
          recordedBy: row['recorded_by'] as String,
          clientOperationId: (row['client_operation_id'] as String?) ?? '',
          syncState: 'synced',
        );
        await local.cacheRecord(record);
      }
    } catch (_) {
      // Offline fallback — local cache is still usable.
    }
  }
}
