import 'package:intl/intl.dart';

/// Shared display formatters for dates and Arabic pluralized counts.
abstract final class AppDateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Formats a [DateTime] as `dd/MM/yyyy` for UI display.
  static String format(DateTime date) => _dateFormat.format(date.toLocal());

  /// Formats a [DateTime] as `dd/MM/yyyy HH:mm` for UI display.
  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime.toLocal());

  /// Parses an ISO/YYYY-MM-DD/DD-MM-YYYY string and formats as `dd/MM/yyyy`.
  /// Returns [fallback] (or the raw string) if parsing fails.
  static String formatString(String? raw, {String fallback = ''}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return format(iso);
    final dmyMatch = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(trimmed);
    if (dmyMatch != null) {
      final day = int.parse(dmyMatch.group(1)!);
      final month = int.parse(dmyMatch.group(2)!);
      final year = int.parse(dmyMatch.group(3)!);
      return format(DateTime(year, month, day));
    }
    return trimmed;
  }
}

/// Formats an open follow-up cases count using Arabic CLDR plural rules.
String formatOpenCasesCount(int count) => Intl.plural(
      count,
      locale: 'ar',
      zero: 'لا توجد حالات مفتوحة',
      one: 'حالة مفتوحة',
      two: 'حالتان',
      few: '$count حالات',
      many: '$count حالة',
      other: '$count حالة',
    );
