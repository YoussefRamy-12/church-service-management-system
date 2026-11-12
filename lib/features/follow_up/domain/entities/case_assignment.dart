import 'package:flutter/foundation.dart';

@immutable
class CaseAssignment {
  const CaseAssignment({
    required this.id,
    required this.caseId,
    required this.servantId,
    required this.assignedBy,
    required this.assignedAt,
    required this.clientOperationId,
    this.assignmentStatus = 'active',
    this.removedAt,
    this.servantName,
    this.servantRole,
    this.assignedByName,
  });

  final String id;
  final String caseId;
  final String servantId;
  final String assignedBy;
  final DateTime assignedAt;
  final String assignmentStatus;
  final DateTime? removedAt;
  final String clientOperationId;

  // Display metadata
  final String? servantName;
  final String? servantRole;
  final String? assignedByName;

  bool get isActive => assignmentStatus == 'active';

  CaseAssignment copyWith({
    String? id,
    String? caseId,
    String? servantId,
    String? assignedBy,
    DateTime? assignedAt,
    String? assignmentStatus,
    DateTime? removedAt,
    String? clientOperationId,
    String? servantName,
    String? servantRole,
    String? assignedByName,
  }) {
    return CaseAssignment(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      servantId: servantId ?? this.servantId,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      removedAt: removedAt ?? this.removedAt,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      servantName: servantName ?? this.servantName,
      servantRole: servantRole ?? this.servantRole,
      assignedByName: assignedByName ?? this.assignedByName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseAssignment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

