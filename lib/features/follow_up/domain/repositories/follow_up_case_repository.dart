import '../entities/activity_type.dart';
import '../entities/case_assignment.dart';
import '../entities/case_priority.dart';
import '../entities/case_status.dart';
import '../entities/follow_up_activity.dart';
import '../entities/follow_up_case.dart';

abstract interface class FollowUpCaseRepository {
  // Cases
  Stream<List<FollowUpCase>> watchCasesForScope({
    required String serviceId,
    Set<String>? classIds,
    String? studentId,
  });

  Future<FollowUpCase?> getCaseById(String caseId);

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
  });

  Future<FollowUpCase> updateCaseStatus({
    required String caseId,
    required CaseStatus newStatus,
    required String actorId,
    required String actorRole,
    String? note,
  });

  Future<FollowUpCase> updateCasePriority({
    required String caseId,
    required CasePriority newPriority,
  });

  Future<FollowUpCase> updateCaseDetails({
    required String caseId,
    required String title,
    String? description,
  });

  // Assignments
  Stream<List<CaseAssignment>> watchAssignmentsForCase(String caseId);

  Future<void> assignServants({
    required String caseId,
    required List<String> servantIds,
    required String assignedBy,
  });

  Future<void> removeAssignment({
    required String assignmentId,
    required String caseId,
    required String removedBy,
  });

  // Activities
  Stream<List<FollowUpActivity>> watchActivitiesForCase(String caseId);

  Stream<List<FollowUpActivity>> watchActivitiesForScope({
    required String serviceId,
    Set<String>? classIds,
    int limit = 50,
  });

  Stream<List<FollowUpActivity>> watchActivitiesForStudent(String studentId);

  Future<FollowUpActivity> recordActivity({
    required String caseId,
    required ActivityType activityType,
    required String description,
    required String createdBy,
    required String activityDate,
  });
}

