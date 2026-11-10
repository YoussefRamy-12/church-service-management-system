import 'package:flutter/foundation.dart';
import 'case_priority.dart';
import 'case_status.dart';

@immutable
class FollowUpCase {
  const FollowUpCase({
    required this.id,
    required this.serviceId,
    required this.studentId,
    required this.classId,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.clientOperationId,
    this.description,
    this.caseType = 'general',
    this.resolvedAt,
    this.closedAt,
    this.studentName,
    this.className,
    this.creatorName,
    this.assignedServantCount = 0,
    this.assignedServantNames = const [],
    this.latestActivityDate,
    this.latestActivityAuthorName,
  });

  final String id;
  final String serviceId;
  final String studentId;
  final String classId;
  final String title;
  final String? description;
  final CasePriority priority;
  final CaseStatus status;
  final String caseType;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String clientOperationId;

  // Joined/Display Metadata (optional)
  final String? studentName;
  final String? className;
  final String? creatorName;
  final int assignedServantCount;
  final List<String> assignedServantNames;
  final String? latestActivityDate;
  final String? latestActivityAuthorName;

  bool get isActive => status.isActive;
  bool get isClosed => status == CaseStatus.closed;
  bool get isResolved => status == CaseStatus.resolved;

  FollowUpCase copyWith({
    String? id,
    String? serviceId,
    String? studentId,
    String? classId,
    String? title,
    String? description,
    CasePriority? priority,
    CaseStatus? status,
    String? caseType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    String? clientOperationId,
    String? studentName,
    String? className,
    String? creatorName,
    int? assignedServantCount,
    List<String>? assignedServantNames,
    String? latestActivityDate,
    String? latestActivityAuthorName,
  }) {
    return FollowUpCase(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      caseType: caseType ?? this.caseType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      creatorName: creatorName ?? this.creatorName,
      assignedServantCount: assignedServantCount ?? this.assignedServantCount,
      assignedServantNames: assignedServantNames ?? this.assignedServantNames,
      latestActivityDate: latestActivityDate ?? this.latestActivityDate,
      latestActivityAuthorName: latestActivityAuthorName ?? this.latestActivityAuthorName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpCase &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode ^ updatedAt.hashCode;
}

