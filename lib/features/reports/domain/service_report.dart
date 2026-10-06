class ServiceReport {
  const ServiceReport({
    required this.students,
    required this.meetings,
    required this.expectedAttendance,
    required this.present,
    required this.early,
    required this.normal,
    required this.followUps,
  });

  final int students;
  final int meetings;
  final int expectedAttendance;
  final int present;
  final int early;
  final int normal;
  final int followUps;

  double get attendancePercentage =>
      expectedAttendance == 0 ? 0 : present * 100 / expectedAttendance;
}
