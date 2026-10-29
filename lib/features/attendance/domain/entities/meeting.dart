import 'package:flutter/foundation.dart';

@immutable
class Meeting {
  const Meeting({
    required this.id,
    required this.serviceId,
    required this.meetingDate,
    required this.startTime,
    this.name = 'اجتماع الخدمة',
    this.scheduleId,
  });

  final String id;
  final String serviceId;
  final DateTime meetingDate;
  final String startTime;
  final String name;
  final String? scheduleId;

  Meeting copyWith({
    String? id,
    String? serviceId,
    DateTime? meetingDate,
    String? startTime,
    String? name,
    String? scheduleId,
  }) {
    return Meeting(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      meetingDate: meetingDate ?? this.meetingDate,
      startTime: startTime ?? this.startTime,
      name: name ?? this.name,
      scheduleId: scheduleId ?? this.scheduleId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meeting &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceId == other.serviceId &&
          name == other.name &&
          scheduleId == other.scheduleId;

  @override
  int get hashCode => id.hashCode ^ serviceId.hashCode ^ name.hashCode ^ (scheduleId?.hashCode ?? 0);
}
