import 'dart:convert';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/activity_type.dart';
import '../domain/entities/case_assignment.dart';
import '../domain/entities/case_priority.dart';
import '../domain/entities/case_status.dart';
import '../domain/entities/follow_up_activity.dart';
import '../domain/entities/follow_up_case.dart';
import '../domain/repositories/follow_up_case_repository.dart';
import 'local_follow_up_case_repository.dart';

class OfflineFirstFollowUpCaseRepository implements FollowUpCaseRepository {
  OfflineFirstFollowUpCaseRepository({
    required this.local,
    required this.queue,
  });

  final LocalFollowUpCaseRepository local;
  final SyncQueueRepository queue;

  @override
  Stream<List<FollowUpCase>> watchCasesForScope({
    required String serviceId,
    Set<String>? classIds,
    String? studentId,
  }) =>
      local.watchCasesForScope(
        serviceId: serviceId,
        classIds: classIds,
        studentId: studentId,
      );

  @override
  Future<FollowUpCase?> getCaseById(String caseId) => local.getCaseById(caseId);

  @override
  Future<FollowUpCase> createCase({
    required String serviceId,
    required String studentId,
    required String classId,
    required String title,
    String? description,
    required CasePriority priority,
    required String createdBy,
    String caseType = 'general',
    List<String> initialServantIds = const [],
  }) async {
    final newCase = await local.createCase(
      serviceId: serviceId,
      studentId: studentId,
      classId: classId,
      title: title,
      description: description,
      priority: priority,
      createdBy: createdBy,
      caseType: caseType,
      initialServantIds: initialServantIds,
    );

    // Enqueue case creation
    await queue.enqueue(
      SyncOperation(
        operationId: newCase.clientOperationId,
        entityType: 'follow_up_case',
        operationType: 'insert',
        payloadJson: jsonEncode({
          'id': newCase.id,
          'service_id': newCase.serviceId,
          'student_id': newCase.studentId,
          'class_id': newCase.classId,
          'title': newCase.title,
          'description': newCase.description,
          'priority': newCase.priority.value,
          'status': newCase.status.value,
          'case_type': newCase.caseType,
          'created_by': newCase.createdBy,
          'created_at': newCase.createdAt.toUtc().toIso8601String(),
          'updated_at': newCase.updatedAt.toUtc().toIso8601String(),
          'client_operation_id': newCase.clientOperationId,
        }),
      ),
    );

    return newCase;
  }

  @override
  Future<FollowUpCase> updateCaseStatus({
    required String caseId,
    required CaseStatus newStatus,
    required String actorId,
    required String actorRole,
    String? note,
  }) async {
    final updatedCase = await local.updateCaseStatus(
      caseId: caseId,
      newStatus: newStatus,
      actorId: actorId,
      actorRole: actorRole,
      note: note,
    );

    await queue.enqueue(
      SyncOperation(
        operationId: updatedCase.clientOperationId,
        entityType: 'follow_up_case',
        operationType: 'update',
        payloadJson: jsonEncode({
          'id': updatedCase.id,
          'status': updatedCase.status.value,
          'updated_at': updatedCase.updatedAt.toUtc().toIso8601String(),
          'resolved_at': updatedCase.resolvedAt?.toUtc().toIso8601String(),
          'closed_at': updatedCase.closedAt?.toUtc().toIso8601String(),
        }),
      ),
    );

    return updatedCase;
  }

  @override
  Future<FollowUpCase> updateCasePriority({
    required String caseId,
    required CasePriority newPriority,
  }) async {
    final updatedCase = await local.updateCasePriority(
      caseId: caseId,
      newPriority: newPriority,
    );

    await queue.enqueue(
      SyncOperation(
        operationId: updatedCase.clientOperationId,
        entityType: 'follow_up_case',
        operationType: 'update',
        payloadJson: jsonEncode({
          'id': updatedCase.id,
          'priority': updatedCase.priority.value,
          'updated_at': updatedCase.updatedAt.toUtc().toIso8601String(),
        }),
      ),
    );

    return updatedCase;
  }

  @override
  Future<FollowUpCase> updateCaseDetails({
    required String caseId,
    required String title,
    String? description,
  }) async {
    final updatedCase = await local.updateCaseDetails(
      caseId: caseId,
      title: title,
      description: description,
    );

    await queue.enqueue(
      SyncOperation(
        operationId: updatedCase.clientOperationId,
        entityType: 'follow_up_case',
        operationType: 'update',
        payloadJson: jsonEncode({
          'id': updatedCase.id,
          'title': updatedCase.title,
          'description': updatedCase.description,
          'updated_at': updatedCase.updatedAt.toUtc().toIso8601String(),
        }),
      ),
    );

    return updatedCase;
  }

  @override
  Stream<List<CaseAssignment>> watchAssignmentsForCase(String caseId) =>
      local.watchAssignmentsForCase(caseId);

  @override
  Future<void> assignServants({
    required String caseId,
    required List<String> servantIds,
    required String assignedBy,
  }) async {
    await local.assignServants(
      caseId: caseId,
      servantIds: servantIds,
      assignedBy: assignedBy,
    );

    // Enqueue assignments for sync
    final assignments = await local.watchAssignmentsForCase(caseId).first;
    for (final a in assignments.where((item) => servantIds.contains(item.servantId) && item.isActive)) {
      await queue.enqueue(
        SyncOperation(
          operationId: a.clientOperationId,
          entityType: 'follow_up_case_assignment',
          operationType: 'insert',
          payloadJson: jsonEncode({
            'id': a.id,
            'case_id': a.caseId,
            'servant_id': a.servantId,
            'assigned_by': a.assignedBy,
            'assigned_at': a.assignedAt.toUtc().toIso8601String(),
            'assignment_status': a.assignmentStatus,
            'client_operation_id': a.clientOperationId,
          }),
        ),
      );
    }
  }

  @override
  Future<void> removeAssignment({
    required String assignmentId,
    required String caseId,
    required String removedBy,
  }) async {
    await local.removeAssignment(
      assignmentId: assignmentId,
      caseId: caseId,
      removedBy: removedBy,
    );

    await queue.enqueue(
      SyncOperation(
        operationId: assignmentId,
        entityType: 'follow_up_case_assignment',
        operationType: 'update',
        payloadJson: jsonEncode({
          'id': assignmentId,
          'assignment_status': 'removed',
          'removed_at': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
    );
  }

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForCase(String caseId) =>
      local.watchActivitiesForCase(caseId);

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForScope({
    required String serviceId,
    Set<String>? classIds,
    int limit = 50,
  }) =>
      local.watchActivitiesForScope(
        serviceId: serviceId,
        classIds: classIds,
        limit: limit,
      );

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForStudent(String studentId) =>
      local.watchActivitiesForStudent(studentId);

  @override
  Future<FollowUpActivity> recordActivity({
    required String caseId,
    required ActivityType activityType,
    required String description,
    required String createdBy,
    required String activityDate,
  }) async {
    final activity = await local.recordActivity(
      caseId: caseId,
      activityType: activityType,
      description: description,
      createdBy: createdBy,
      activityDate: activityDate,
    );

    await queue.enqueue(
      SyncOperation(
        operationId: activity.clientOperationId,
        entityType: 'follow_up_activity',
        operationType: 'insert',
        payloadJson: jsonEncode({
          'id': activity.id,
          'case_id': activity.caseId,
          'activity_type': activity.activityType.value,
          'description': activity.description,
          'created_by': activity.createdBy,
          'created_at': activity.createdAt.toUtc().toIso8601String(),
          'activity_date': activity.activityDate,
          'client_operation_id': activity.clientOperationId,
        }),
      ),
    );

    return activity;
  }
}

