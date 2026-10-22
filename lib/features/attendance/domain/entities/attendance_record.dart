import 'package:flutter/foundation.dart';

@immutable
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

  AttendanceRecord copyWith({
    String? id,
    String? meetingId,
    String? studentId,
    String? classIdAtAttendance,
    DateTime? checkedInAt,
    String? recordedBy,
    String? clientOperationId,
    String? syncState,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      studentId: studentId ?? this.studentId,
      classIdAtAttendance: classIdAtAttendance ?? this.classIdAtAttendance,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      recordedBy: recordedBy ?? this.recordedBy,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      syncState: syncState ?? this.syncState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          meetingId == other.meetingId &&
          studentId == other.studentId;

  @override
  int get hashCode => id.hashCode ^ meetingId.hashCode ^ studentId.hashCode;
}
