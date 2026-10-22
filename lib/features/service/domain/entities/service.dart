import 'package:flutter/foundation.dart';

@immutable
class Service {
  const Service({
    required this.id,
    required this.name,
    required this.churchName,
    required this.meetingStartTime,
    this.meetingFrequency = 'weekly',
    this.meetingWeekday = 5,
    this.meetingMonthDay = 1,
    this.earlyAttendanceMinutes = 15,
  });

  final String id;
  final String name;
  final String churchName;
  final String meetingStartTime;
  final String meetingFrequency;
  final int meetingWeekday;
  final int meetingMonthDay;
  final int earlyAttendanceMinutes;

  Service copyWith({
    String? id,
    String? name,
    String? churchName,
    String? meetingStartTime,
    String? meetingFrequency,
    int? meetingWeekday,
    int? meetingMonthDay,
    int? earlyAttendanceMinutes,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      churchName: churchName ?? this.churchName,
      meetingStartTime: meetingStartTime ?? this.meetingStartTime,
      meetingFrequency: meetingFrequency ?? this.meetingFrequency,
      meetingWeekday: meetingWeekday ?? this.meetingWeekday,
      meetingMonthDay: meetingMonthDay ?? this.meetingMonthDay,
      earlyAttendanceMinutes:
          earlyAttendanceMinutes ?? this.earlyAttendanceMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
