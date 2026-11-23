import 'package:flutter/foundation.dart';
import 'analytics_models.dart';

@immutable
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
    // Enhanced analytics fields with sensible defaults
    this.previousPeriodAttendanceRate,
    this.meetingHistory = const [],
    this.repeatedAbsences = const [],
    this.classComparisons = const [],
    this.servantWorkloads = const [],
    this.actionableInsights = const [],
    this.followUpAnalytics,
    this.studentAnalytics,
    this.scopedStageName,
    this.scopedClassName,
  });

  // Base legacy properties preserved for backward compatibility
  final int students;
  final int meetings;
  final int expectedAttendance;
  final int present;
  final int early;
  final int before;
  final int normal;
  final int followUps;
  final Map<String, List<String>> details;

  // Enhanced analytics properties
  final double? previousPeriodAttendanceRate;
  final List<MeetingAttendanceItem> meetingHistory;
  final List<RepeatedAbsenceRecord> repeatedAbsences;
  final List<ClassComparisonMetric> classComparisons;
  final List<ServantWorkloadMetric> servantWorkloads;
  final List<ActionableInsight> actionableInsights;
  final FollowUpAnalytics? followUpAnalytics;
  final StudentAnalytics? studentAnalytics;
  final String? scopedStageName;
  final String? scopedClassName;

  // Centralized analytical metric getters
  double get attendancePercentage =>
      expectedAttendance == 0 ? 0.0 : (present * 100.0) / expectedAttendance;

  double get absencePercentage => 100.0 - attendancePercentage;

  double get earlyRate =>
      present == 0 ? 0.0 : ((early + before) * 100.0) / present;

  double get normalRate => present == 0 ? 0.0 : (normal * 100.0) / present;

  double? get attendanceChange => previousPeriodAttendanceRate == null
      ? null
      : attendancePercentage - previousPeriodAttendanceRate!;

  int get absentCount =>
      expectedAttendance >= present ? expectedAttendance - present : 0;
}
