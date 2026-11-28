import 'package:flutter/foundation.dart';
import 'activity_type.dart';

@immutable
class FollowUpActivity {
  const FollowUpActivity({
    required this.id,
    required this.caseId,
    required this.activityType,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.activityDate,
    required this.clientOperationId,
    this.authorName,
    this.authorRole,
    this.studentName,
    this.caseTitle,
  });

  final String id;
  final String caseId;
  final ActivityType activityType;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String activityDate;
  final String clientOperationId;

  // Display metadata
  final String? authorName;
  final String? authorRole;
  final String? studentName;
  final String? caseTitle;

  FollowUpActivity copyWith({
    String? id,
    String? caseId,
    ActivityType? activityType,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    String? activityDate,
    String? clientOperationId,
    String? authorName,
    String? authorRole,
    String? studentName,
    String? caseTitle,
  }) {
    return FollowUpActivity(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      activityDate: activityDate ?? this.activityDate,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      studentName: studentName ?? this.studentName,
      caseTitle: caseTitle ?? this.caseTitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpActivity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

