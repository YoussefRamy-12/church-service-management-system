import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/attendance_record.dart';
import '../domain/repositories/attendance_repository.dart';
import 'attendance_profile_resolver.dart';

/// Online-only implementation of [AttendanceRepository].
///
/// Communicates directly with Supabase, bypassing local Drift database and
/// sync mutation queue.
class OnlineAttendanceRepository implements AttendanceRepository {
  const OnlineAttendanceRepository(this._client);

  final SupabaseClient _client;
  static const Uuid _uuid = Uuid();

  @override
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId) async* {
    final rows = await _client
        .from('attendance_records')
        .select()
        .eq('meeting_id', meetingId);
    yield rows.map(_fromRow).toList();
  }

  @override
  Stream<List<AttendanceRecord>> watchForStudent(String studentId) async* {
    final rows = await _client
        .from('attendance_records')
        .select()
        .eq('student_id', studentId);
    yield rows.map(_fromRow).toList();
  }

  @override
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  }) async {
    final id = _uuid.v4();
    final clientOpId = _uuid.v4();
    // The FK and insert policy both require the active profile for this
    // meeting's service, rather than an auth user id or stale profile id.
    final effectiveRecordedBy = await resolveAttendanceRecorderProfileId(
      _client,
      meetingId: meetingId,
      preferredProfileId: recordedBy,
    );

    await _client.from('attendance_records').upsert({
      'id': id,
      'meeting_id': meetingId,
      'student_id': studentId,
      'class_id_at_attendance': classIdAtAttendance,
      'checked_in_at': checkedInAt.toIso8601String(),
      'recorded_by': effectiveRecordedBy,
      'client_operation_id': clientOpId,
    }, onConflict: 'meeting_id,student_id');

    return AttendanceRecord(
      id: id,
      meetingId: meetingId,
      studentId: studentId,
      classIdAtAttendance: classIdAtAttendance,
      checkedInAt: checkedInAt,
      recordedBy: effectiveRecordedBy,
      clientOperationId: clientOpId,
      syncState: 'synced',
    );
  }

  @override
  Future<AttendanceRecord> updateCheckedInAt({
    required String attendanceId,
    required DateTime checkedInAt,
  }) async {
    final rows = await _client
        .from('attendance_records')
        .update({'checked_in_at': checkedInAt.toIso8601String()})
        .eq('id', attendanceId)
        .select();

    if (rows.isEmpty) {
      throw StateError('Attendance record update was rejected by server.');
    }

    return _fromRow(rows.first);
  }

  @override
  Future<void> refreshAttendanceForMeeting(String meetingId) async {
    await _client
        .from('attendance_records')
        .select('id')
        .eq('meeting_id', meetingId)
        .limit(1);
  }

  AttendanceRecord _fromRow(Map<String, dynamic> row) => AttendanceRecord(
    id: row['id'] as String,
    meetingId: row['meeting_id'] as String,
    studentId: row['student_id'] as String,
    classIdAtAttendance: row['class_id_at_attendance'] as String,
    checkedInAt: DateTime.parse(row['checked_in_at'] as String),
    recordedBy: row['recorded_by'] as String,
    clientOperationId: (row['client_operation_id'] as String?) ?? '',
    syncState: 'synced',
  );
}
