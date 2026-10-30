import 'package:flutter/foundation.dart';

@immutable
class FollowUpRecord {
  const FollowUpRecord({
    required this.id,
    required this.studentId,
    required this.createdBy,
    required this.followUpDate,
    required this.contactStatus,
    required this.clientOperationId,
    this.contactMethod,
    this.absenceReason,
    this.studentResponse,
    this.parentResponse,
    this.actionRequired,
    this.notes,
    this.anotherFollowUpNeeded = false,
    this.nextFollowUpDate,
    this.assignedTo,
    this.isRequest = false,
    this.requestStatus = 'open',
  });

  final String id;
  final String studentId;
  final String createdBy;
  final String followUpDate;
  final String contactStatus;
  final String clientOperationId;
  final String? contactMethod;
  final String? absenceReason;
  final String? studentResponse;
  final String? parentResponse;
  final String? actionRequired;
  final String? notes;
  final bool anotherFollowUpNeeded;
  final String? nextFollowUpDate;
  final String? assignedTo;
  final bool isRequest;
  final String requestStatus;

  FollowUpRecord copyWith({
    String? id,
    String? studentId,
    String? createdBy,
    String? followUpDate,
    String? contactStatus,
    String? clientOperationId,
    String? contactMethod,
    String? absenceReason,
    String? studentResponse,
    String? parentResponse,
    String? actionRequired,
    String? notes,
    bool? anotherFollowUpNeeded,
    String? nextFollowUpDate,
    String? assignedTo,
    bool? isRequest,
    String? requestStatus,
  }) {
    return FollowUpRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      createdBy: createdBy ?? this.createdBy,
      followUpDate: followUpDate ?? this.followUpDate,
      contactStatus: contactStatus ?? this.contactStatus,
      clientOperationId: clientOperationId ?? this.clientOperationId,
      contactMethod: contactMethod ?? this.contactMethod,
      absenceReason: absenceReason ?? this.absenceReason,
      studentResponse: studentResponse ?? this.studentResponse,
      parentResponse: parentResponse ?? this.parentResponse,
      actionRequired: actionRequired ?? this.actionRequired,
      notes: notes ?? this.notes,
      anotherFollowUpNeeded:
          anotherFollowUpNeeded ?? this.anotherFollowUpNeeded,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      assignedTo: assignedTo ?? this.assignedTo,
      isRequest: isRequest ?? this.isRequest,
      requestStatus: requestStatus ?? this.requestStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clientOperationId == other.clientOperationId;

  @override
  int get hashCode => id.hashCode ^ clientOperationId.hashCode;
}
