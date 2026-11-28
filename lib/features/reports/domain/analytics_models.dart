import 'package:flutter/foundation.dart';

/// Represents a student with consecutive missed meetings.
@immutable
class RepeatedAbsenceRecord {
  const RepeatedAbsenceRecord({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.consecutiveMissedMeetings,
    this.lastAttendedDate,
    this.phone,
  });

  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final int consecutiveMissedMeetings;
  final String? lastAttendedDate;
  final String? phone;
}

/// Comparative performance and attendance data for a single class.
@immutable
class ClassComparisonMetric {
  const ClassComparisonMetric({
    required this.classId,
    required this.className,
    required this.stageId,
    required this.stageName,
    required this.totalStudents,
    required this.expectedAttendance,
    required this.presentCount,
    required this.earlyCount,
    required this.normalCount,
    required this.repeatedAbsencesCount,
    required this.openCasesCount,
    required this.resolvedCasesCount,
  });

  final String classId;
  final String className;
  final String stageId;
  final String stageName;
  final int totalStudents;
  final int expectedAttendance;
  final int presentCount;
  final int earlyCount;
  final int normalCount;
  final int repeatedAbsencesCount;
  final int openCasesCount;
  final int resolvedCasesCount;

  double get attendanceRate => expectedAttendance == 0
      ? 0.0
      : (presentCount * 100.0) / expectedAttendance;

  double get absenceRate => 100.0 - attendanceRate;

  double get earlyRate =>
      presentCount == 0 ? 0.0 : (earlyCount * 100.0) / presentCount;

  double get followUpCompletionRate {
    final totalCases = openCasesCount + resolvedCasesCount;
    return totalCases == 0 ? 100.0 : (resolvedCasesCount * 100.0) / totalCases;
  }
}

/// Operational pastoral workload for a servant.
@immutable
class ServantWorkloadMetric {
  const ServantWorkloadMetric({
    required this.servantId,
    required this.servantName,
    required this.role,
    this.classId,
    this.className,
    required this.assignedCasesCount,
    required this.activeCasesCount,
    required this.completedActivitiesCount,
  });

  final String servantId;
  final String servantName;
  final String role;
  final String? classId;
  final String? className;
  final int assignedCasesCount;
  final int activeCasesCount;
  final int completedActivitiesCount;
}

/// Severity of an actionable insight.
enum InsightSeverity {
  warning, // تنبيه يستلزم تدخلاً
  critical, // تنبيه عاجل
  info, // مؤشر إيجابي أو ملحوظ
}

/// A deterministic insight requiring attention.
@immutable
class ActionableInsight {
  const ActionableInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.classId,
    this.studentId,
    this.targetTab = 'overview',
  });

  final String id;
  final String title;
  final String description;
  final InsightSeverity severity;
  final String? classId;
  final String? studentId;
  final String targetTab;
}

/// Attendance metrics for a single meeting in the period.
@immutable
class MeetingAttendanceItem {
  const MeetingAttendanceItem({
    required this.meetingId,
    required this.meetingDate,
    required this.meetingName,
    required this.startTime,
    required this.expectedCount,
    required this.presentCount,
    required this.earlyCount,
    required this.beforeCount,
    required this.normalCount,
  });

  final String meetingId;
  final String meetingDate;
  final String meetingName;
  final String startTime;
  final int expectedCount;
  final int presentCount;
  final int earlyCount;
  final int beforeCount;
  final int normalCount;

  double get attendanceRate =>
      expectedCount == 0 ? 0.0 : (presentCount * 100.0) / expectedCount;
}

/// Summary of pastoral follow-up cases and activity.
@immutable
class FollowUpAnalytics {
  const FollowUpAnalytics({
    required this.totalCases,
    required this.openCases,
    required this.assignedCases,
    required this.inProgressCases,
    required this.resolvedCases,
    required this.closedCases,
    required this.urgentOrHighPriorityCases,
    required this.totalActivities,
    required this.activityTypeCounts,
  });

  final int totalCases;
  final int openCases;
  final int assignedCases;
  final int inProgressCases;
  final int resolvedCases;
  final int closedCases;
  final int urgentOrHighPriorityCases;
  final int totalActivities;
  final Map<String, int> activityTypeCounts;

  int get pendingCases => openCases + assignedCases + inProgressCases;
  int get completedCases => resolvedCases + closedCases;

  double get completionRate =>
      totalCases == 0 ? 100.0 : (completedCases * 100.0) / totalCases;
}

/// Distribution of student attendance frequencies and roster status.
@immutable
class StudentAnalytics {
  const StudentAnalytics({
    required this.activeStudents,
    required this.pendingStudents,
    required this.attendanceTiers,
    required this.improvingCount,
    required this.decliningCount,
  });

  final int activeStudents;
  final int pendingStudents;
  final Map<String, int> attendanceTiers; // '90-100%', '75-89%', '50-74%', '<50%'
  final int improvingCount;
  final int decliningCount;
}

