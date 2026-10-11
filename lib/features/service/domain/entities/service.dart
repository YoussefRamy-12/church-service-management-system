class Service {
  const Service({
    required this.id,
    required this.name,
    required this.churchName,
    required this.meetingStartTime,
    this.meetingFrequency = 'weekly',
    this.meetingWeekday = 5,
    this.meetingMonthDay = 1,
  });

  final String id;
  final String name;
  final String churchName;
  final String meetingStartTime;
  final String meetingFrequency;
  final int meetingWeekday;
  final int meetingMonthDay;
}
