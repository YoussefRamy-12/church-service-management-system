import 'package:flutter/foundation.dart';

/// Supported reporting period presets.
enum ReportPeriodPreset {
  lastMeeting,
  currentMonth,
  currentTerm,
  serviceYear,
  custom,
}

/// Filter criteria for reports and analytics.
@immutable
class ReportFilter {
  const ReportFilter({
    required this.start,
    required this.end,
    this.preset = ReportPeriodPreset.lastMeeting,
    this.stageId,
    this.classId,
    this.studentId,
    this.compareWithPrevious = true,
  });

  final DateTime start;
  final DateTime end;
  final ReportPeriodPreset preset;
  final String? stageId;
  final String? classId;
  final String? studentId;
  final bool compareWithPrevious;

  ReportFilter copyWith({
    DateTime? start,
    DateTime? end,
    ReportPeriodPreset? preset,
    String? stageId,
    String? classId,
    String? studentId,
    bool? compareWithPrevious,
  }) {
    return ReportFilter(
      start: start ?? this.start,
      end: end ?? this.end,
      preset: preset ?? this.preset,
      stageId: stageId ?? this.stageId,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      compareWithPrevious: compareWithPrevious ?? this.compareWithPrevious,
    );
  }

  /// Calculates the previous equivalent date range for fair comparisons.
  (DateTime, DateTime) get previousEquivalentPeriod {
    final duration = end.difference(start);
    final days = duration.inDays <= 0 ? 7 : duration.inDays + 1;
    final prevEnd = start.subtract(const Duration(days: 1));
    final prevStart = prevEnd.subtract(Duration(days: days - 1));
    return (prevStart, prevEnd);
  }
}

