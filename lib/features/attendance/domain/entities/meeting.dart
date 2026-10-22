import 'package:flutter/foundation.dart';

@immutable
class Meeting {
  const Meeting({
    required this.id,
    required this.serviceId,
    required this.meetingDate,
    required this.startTime,
  });

  final String id;
  final String serviceId;
  final DateTime meetingDate;
  final String startTime;

  Meeting copyWith({
    String? id,
    String? serviceId,
    DateTime? meetingDate,
    String? startTime,
  }) {
    return Meeting(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      meetingDate: meetingDate ?? this.meetingDate,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meeting &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceId == other.serviceId;

  @override
  int get hashCode => id.hashCode ^ serviceId.hashCode;
}
