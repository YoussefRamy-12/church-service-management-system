/// Friday-to-Thursday period in local calendar-date semantics.
class WeeklyPeriod {
  const WeeklyPeriod({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  String get id => '${_key(start)}_${_key(end)}';
  String get label => '${_key(start)} – ${_key(end)}';

  static WeeklyPeriod containing(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    // DateTime.weekday: Monday=1 ... Friday=5.
    final daysSinceFriday = (localDate.weekday - DateTime.friday) % 7;
    final start = localDate.subtract(Duration(days: daysSinceFriday));
    return WeeklyPeriod(start: start, end: start.add(const Duration(days: 6)));
  }

  static WeeklyPeriod offset(DateTime date, int weeks) {
    return containing(date).shift(weeks);
  }

  WeeklyPeriod shift(int weeks) {
    final shifted = start.add(Duration(days: weeks * 7));
    return WeeklyPeriod(
      start: shifted,
      end: shifted.add(const Duration(days: 6)),
    );
  }

  static String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
