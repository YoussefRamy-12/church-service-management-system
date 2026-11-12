import 'package:flutter/foundation.dart';
import '../../../students/domain/entities/student.dart';

@immutable
class FollowUpStudentItem {
  const FollowUpStudentItem({
    required this.student,
    required this.className,
    required this.absenceCount,
    required this.totalEligibleMeetings,
    required this.activeCasesCount,
    required this.totalCasesCount,
    this.latestFollowUpDate,
    this.latestFollowUpAuthor,
  });

  final Student student;
  final String className;
  final int absenceCount;
  final int totalEligibleMeetings;
  final int activeCasesCount;
  final int totalCasesCount;
  final String? latestFollowUpDate;
  final String? latestFollowUpAuthor;

  /// Student needs follow-up if they have an active case OR have 2 or more absences.
  bool get needsFollowUp => activeCasesCount > 0 || absenceCount >= 2;

  /// Student was previously followed up if they have any recorded follow-up date or case.
  bool get wasPreviouslyFollowedUp =>
      totalCasesCount > 0 || latestFollowUpDate != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpStudentItem &&
          runtimeType == other.runtimeType &&
          student.id == other.student.id &&
          absenceCount == other.absenceCount &&
          activeCasesCount == other.activeCasesCount;

  @override
  int get hashCode =>
      student.id.hashCode ^ absenceCount.hashCode ^ activeCasesCount.hashCode;
}
