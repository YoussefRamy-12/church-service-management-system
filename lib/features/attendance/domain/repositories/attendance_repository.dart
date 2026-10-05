import '../entities/attendance_record.dart';

abstract interface class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId);
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  });
}
