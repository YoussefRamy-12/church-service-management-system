class ServiceReport {
  const ServiceReport({
    required this.students,
    required this.meetings,
    required this.expectedAttendance,
    required this.present,
    required this.early,
    this.before = 0,
    required this.normal,
    required this.followUps,
    this.details = const {},
  });

  final int students;
  final int meetings;
  final int expectedAttendance;
  final int present;
  final int early;
  final int before;
  final int normal;
  final int followUps;
  final Map<String, List<String>> details;

  double get attendancePercentage =>
      expectedAttendance == 0 ? 0 : present * 100 / expectedAttendance;
}
