import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/features/reports/domain/service_report.dart';

void main() {
  test('attendance percentage is derived safely', () {
    const report = ServiceReport(
      students: 10,
      meetings: 4,
      expectedAttendance: 40,
      present: 30,
      early: 12,
      normal: 18,
      followUps: 7,
    );

    expect(report.attendancePercentage, 75);
  });

  test('zero expected attendance does not divide by zero', () {
    const report = ServiceReport(
      students: 0,
      meetings: 0,
      expectedAttendance: 0,
      present: 0,
      early: 0,
      normal: 0,
      followUps: 0,
    );

    expect(report.attendancePercentage, 0);
  });
}
