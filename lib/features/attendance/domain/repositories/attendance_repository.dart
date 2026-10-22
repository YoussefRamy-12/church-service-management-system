import '../entities/attendance_record.dart';

abstract interface class AttendanceRepository {
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId);
  Stream<List<AttendanceRecord>> watchForStudent(String studentId);
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  });
  Future<AttendanceRecord> updateCheckedInAt({
    required String attendanceId,
    required DateTime checkedInAt,
  });
  Future<void> refreshAttendanceForMeeting(String meetingId);
}
