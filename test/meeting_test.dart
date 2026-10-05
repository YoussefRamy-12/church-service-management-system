import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/features/attendance/domain/entities/meeting.dart';

void main() {
  test('Meeting preserves its core attendance session data', () {
    final meeting = Meeting(
      id: 'meeting-1',
      serviceId: 'service-1',
      meetingDate: DateTime(2026, 10, 5),
      startTime: '15:00:00',
    );

    expect(meeting.id, 'meeting-1');
    expect(meeting.serviceId, 'service-1');
    expect(meeting.meetingDate, DateTime(2026, 10, 5));
    expect(meeting.startTime, '15:00:00');
  });
}
