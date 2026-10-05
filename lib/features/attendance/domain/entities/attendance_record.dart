class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.meetingId,
    required this.studentId,
    required this.classIdAtAttendance,
    required this.checkedInAt,
    required this.recordedBy,
    required this.clientOperationId,
    required this.syncState,
  });
  final String id;
  final String meetingId;
  final String studentId;
  final String classIdAtAttendance;
  final DateTime checkedInAt;
  final String recordedBy;
  final String clientOperationId;
  final String syncState;
}
