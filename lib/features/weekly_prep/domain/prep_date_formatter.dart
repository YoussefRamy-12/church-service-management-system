import 'package:intl/intl.dart';

/// Formats UTC dates into Cairo local time (Africa/Cairo UTC+2)
/// and provides canonical week normalizers to prevent date duplication.
class PrepDateFormatter {
  const PrepDateFormatter._();

  /// Cairo is UTC+2 in standard time.
  static const Duration cairoOffset = Duration(hours: 2);

  /// Converts a UTC or local DateTime to Cairo time (+2 UTC offset).
  static DateTime toCairoTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return utc.add(cairoOffset);
  }

  /// Normalizes any DateTime to Monday 00:00:00.000Z UTC of that calendar week.
  /// Eliminates mismatches between local dates (from SQL `DATE` fields)
  /// and UTC dates (from `timestamptz` or `DateTime.now()`).
  static DateTime normalizeToMondayUtc(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final utcDay = DateTime.utc(y, m, d);
    return utcDay.subtract(Duration(days: utcDay.weekday - DateTime.monday));
  }

  /// Formats date and time: e.g. "11 نوفمبر 2026 - 8:30 م" (Cairo +2)
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final cairo = toCairoTime(dateTime);
    return DateFormat('d MMMM y - h:mm a', 'ar').format(cairo);
  }

  /// Formats date and time short: e.g. "11 نوفمبر - 8:30 م" (Cairo +2)
  static String formatShortDateTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final cairo = toCairoTime(dateTime);
    return DateFormat('d MMMM - h:mm a', 'ar').format(cairo);
  }

  /// Formats day and month short: e.g. "9/11" (Cairo +2)
  static String formatDayMonth(DateTime date) {
    return DateFormat('d/M', 'ar').format(date);
  }

  /// Formats week range in Cairo time: e.g. "أسبوع 9 نوفمبر – 15 نوفمبر"
  static String formatWeek(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 6));
    final fmt = DateFormat('d MMMM', 'ar');
    return 'أسبوع ${fmt.format(start)} – ${fmt.format(end)}';
  }

  /// Formats week range with year: e.g. "أسبوع 9 نوفمبر 2026 – 15 نوفمبر 2026"
  static String formatWeekWithYear(DateTime monday) {
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 6));
    final fmt = DateFormat('d MMMM y', 'ar');
    return 'أسبوع ${fmt.format(start)} – ${fmt.format(end)}';
  }
}
