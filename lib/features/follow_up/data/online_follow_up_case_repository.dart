import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/activity_type.dart';
import '../domain/entities/case_assignment.dart';
import '../domain/entities/case_priority.dart';
import '../domain/entities/case_status.dart';
import '../domain/entities/follow_up_activity.dart';
import '../domain/entities/follow_up_case.dart';
import '../domain/repositories/follow_up_case_repository.dart';

class OnlineFollowUpCaseRepository implements FollowUpCaseRepository {
  OnlineFollowUpCaseRepository(this._client);

  final SupabaseClient _client;
  static const Uuid _uuid = Uuid();

  @override
  Stream<List<FollowUpCase>> watchCasesForScope({
    required String serviceId,
    Set<String>? classIds,
    String? studentId,
  }) async* {
    var query = _client.from('follow_up_cases').select().eq('service_id', serviceId);

    if (classIds != null) {
      if (classIds.isEmpty) {
        yield const [];
        return;
      }
      query = query.inFilter('class_id', classIds.toList());
    }
    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final rows = await query.order('updated_at', ascending: false);

    yield (rows as List)
        .map((r) => _mapCase(Map<String, dynamic>.from(r)))
        .toList();
  }

  @override
  Future<FollowUpCase?> getCaseById(String caseId) async {
    final row = await _client
        .from('follow_up_cases')
        .select()
        .eq('id', caseId)
        .maybeSingle();

    if (row == null) return null;
    return _mapCase(Map<String, dynamic>.from(row));
  }

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
    final id = _uuid.v4();
    final clientOpId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final initialStatus = initialServantIds.isNotEmpty
        ? CaseStatus.assigned
        : CaseStatus.open;

    final casePayload = {
      'id': id,
      'service_id': serviceId,
      'student_id': studentId,
      'class_id': classId,
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': initialStatus.value,
      'case_type': caseType,
      'created_by': createdBy,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'client_operation_id': clientOpId,
    };

    await _client.from('follow_up_cases').insert(casePayload);

    for (final servantId in initialServantIds) {
      final assignPayload = {
        'id': _uuid.v4(),
        'case_id': id,
        'servant_id': servantId,
        'assigned_by': createdBy,
        'assigned_at': now.toIso8601String(),
        'assignment_status': 'active',
        'client_operation_id': _uuid.v4(),
      };
      await _client.from('follow_up_case_assignments').insert(assignPayload);
    }

    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final actPayload = {
      'id': _uuid.v4(),
      'case_id': id,
      'activity_type': ActivityType.note.value,
      'description': 'تم فتح حالة المتابعة: $title',
      'created_by': createdBy,
      'created_at': now.toIso8601String(),
      'activity_date': dateStr,
      'client_operation_id': _uuid.v4(),
    };
    await _client.from('follow_up_activities').insert(actPayload);

    return _mapCase(casePayload);
  }

  @override
  Future<FollowUpCase> updateCaseStatus({
    required String caseId,
    required CaseStatus newStatus,
    required String actorId,
    required String actorRole,
    String? note,
  }) async {
    final now = DateTime.now().toUtc();
    final updatePayload = <String, dynamic>{
      'status': newStatus.value,
      'updated_at': now.toIso8601String(),
    };

    if (newStatus == CaseStatus.resolved) {
      updatePayload['resolved_at'] = now.toIso8601String();
    } else if (newStatus == CaseStatus.closed) {
      updatePayload['closed_at'] = now.toIso8601String();
    }

    final updatedRow = await _client
        .from('follow_up_cases')
        .update(updatePayload)
        .eq('id', caseId)
        .select()
        .single();

    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final description = note?.trim().isNotEmpty == true
        ? 'تغيير الحالة إلى ${newStatus.arabicLabel}: ${note!.trim()}'
        : 'تم تغيير حالة المتابعة إلى "${newStatus.arabicLabel}"';

    await _client.from('follow_up_activities').insert({
      'id': _uuid.v4(),
      'case_id': caseId,
      'activity_type': ActivityType.statusChange.value,
      'description': description,
      'created_by': actorId,
      'created_at': now.toIso8601String(),
      'activity_date': dateStr,
      'client_operation_id': _uuid.v4(),
    });

    return _mapCase(Map<String, dynamic>.from(updatedRow));
  }

  @override
  Future<FollowUpCase> updateCasePriority({
    required String caseId,
    required CasePriority newPriority,
  }) async {
    final now = DateTime.now().toUtc();
    final updatedRow = await _client
        .from('follow_up_cases')
        .update({
          'priority': newPriority.value,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', caseId)
        .select()
        .single();

    return _mapCase(Map<String, dynamic>.from(updatedRow));
  }

  @override
  Future<FollowUpCase> updateCaseDetails({
    required String caseId,
    required String title,
    String? description,
  }) async {
    final now = DateTime.now().toUtc();
    final updatedRow = await _client
        .from('follow_up_cases')
        .update({
          'title': title,
          'description': description,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', caseId)
        .select()
        .single();

    return _mapCase(Map<String, dynamic>.from(updatedRow));
  }

  @override
  Stream<List<CaseAssignment>> watchAssignmentsForCase(String caseId) async* {
    final rows = await _client
        .from('follow_up_case_assignments')
        .select('*, servant:servant_profiles!servant_id(name, role), assigner:servant_profiles!assigned_by(name)')
        .eq('case_id', caseId)
        .order('assigned_at', ascending: false);

    yield (rows as List).map((r) {
      final servant = r['servant'] as Map<String, dynamic>?;
      final assigner = r['assigner'] as Map<String, dynamic>?;

      return CaseAssignment(
        id: r['id'] as String,
        caseId: r['case_id'] as String,
        servantId: r['servant_id'] as String,
        assignedBy: r['assigned_by'] as String,
        assignedAt: DateTime.parse(r['assigned_at'] as String),
        assignmentStatus: r['assignment_status'] as String? ?? 'active',
        removedAt: r['removed_at'] != null
            ? DateTime.parse(r['removed_at'] as String)
            : null,
        clientOperationId: r['client_operation_id'] as String? ?? '',
        servantName: servant?['name'] as String?,
        servantRole: servant?['role'] as String?,
        assignedByName: assigner?['name'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> assignServants({
    required String caseId,
    required List<String> servantIds,
    required String assignedBy,
  }) async {
    final now = DateTime.now().toUtc();
    for (final sId in servantIds) {
      await _client.from('follow_up_case_assignments').upsert({
        'id': _uuid.v4(),
        'case_id': caseId,
        'servant_id': sId,
        'assigned_by': assignedBy,
        'assigned_at': now.toIso8601String(),
        'assignment_status': 'active',
        'client_operation_id': _uuid.v4(),
      });
    }

    // Update status if open
    final c = await getCaseById(caseId);
    if (c != null && c.status == CaseStatus.open) {
      await _client.from('follow_up_cases').update({
        'status': CaseStatus.assigned.value,
        'updated_at': now.toIso8601String(),
      }).eq('id', caseId);
    }
  }

  @override
  Future<void> removeAssignment({
    required String assignmentId,
    required String caseId,
    required String removedBy,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('follow_up_case_assignments').update({
      'assignment_status': 'removed',
      'removed_at': now.toIso8601String(),
    }).eq('id', assignmentId);
  }

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForCase(String caseId) async* {
    final rows = await _client
        .from('follow_up_activities')
        .select('*, author:servant_profiles!created_by(name, role)')
        .eq('case_id', caseId)
        .order('created_at', ascending: false);

    yield (rows as List).map((r) => _mapActivity(Map<String, dynamic>.from(r))).toList();
  }

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForScope({
    required String serviceId,
    Set<String>? classIds,
    int limit = 50,
  }) async* {
    if (classIds != null && classIds.isEmpty) {
      yield const [];
      return;
    }

    var casesQuery = _client
        .from('follow_up_cases')
        .select('id, student:students(name), title')
        .eq('service_id', serviceId);
    if (classIds != null) {
      casesQuery = casesQuery.inFilter('class_id', classIds.toList());
    }
    final cases = await casesQuery;

    final caseIds = (cases as List).map((c) => c['id'] as String).toList();
    if (caseIds.isEmpty) {
      yield const [];
      return;
    }

    final caseMap = {
      for (final c in cases)
        c['id'] as String: {
          'title': c['title'] as String?,
          'student_name': (c['student'] as Map<String, dynamic>?)?['name'] as String?,
        }
    };

    final rows = await _client
        .from('follow_up_activities')
        .select('*, author:servant_profiles!created_by(name, role)')
        .inFilter('case_id', caseIds)
        .order('created_at', ascending: false)
        .limit(limit);

    yield (rows as List).map((r) {
      final item = Map<String, dynamic>.from(r);
      final meta = caseMap[item['case_id']];
      return _mapActivity(item, studentName: meta?['student_name'], caseTitle: meta?['title']);
    }).toList();
  }

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForStudent(String studentId) async* {
    final cases = await _client
        .from('follow_up_cases')
        .select('id, title')
        .eq('student_id', studentId);

    final caseIds = (cases as List).map((c) => c['id'] as String).toList();
    if (caseIds.isEmpty) {
      yield const [];
      return;
    }

    final rows = await _client
        .from('follow_up_activities')
        .select('*, author:servant_profiles!created_by(name, role)')
        .inFilter('case_id', caseIds)
        .order('created_at', ascending: false);

    yield (rows as List).map((r) => _mapActivity(Map<String, dynamic>.from(r))).toList();
  }

  @override
  Future<FollowUpActivity> recordActivity({
    required String caseId,
    required ActivityType activityType,
    required String description,
    required String createdBy,
    required String activityDate,
  }) async {
    final id = _uuid.v4();
    final clientOpId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final actPayload = {
      'id': id,
      'case_id': caseId,
      'activity_type': activityType.value,
      'description': description,
      'created_by': createdBy,
      'created_at': now.toIso8601String(),
      'activity_date': activityDate,
      'client_operation_id': clientOpId,
    };

    await _client.from('follow_up_activities').insert(actPayload);

    // If case was open or assigned, progress it
    final currentCase = await getCaseById(caseId);
    if (currentCase != null &&
        (currentCase.status == CaseStatus.open ||
            currentCase.status == CaseStatus.assigned)) {
      await _client.from('follow_up_cases').update({
        'status': CaseStatus.inProgress.value,
        'updated_at': now.toIso8601String(),
      }).eq('id', caseId);
    }

    return _mapActivity(actPayload);
  }

  FollowUpCase _mapCase(Map<String, dynamic> r) {
    return FollowUpCase(
      id: r['id'] as String,
      serviceId: r['service_id'] as String,
      studentId: r['student_id'] as String,
      classId: r['class_id'] as String,
      title: r['title'] as String,
      description: r['description'] as String?,
      priority: CasePriority.fromString(r['priority'] as String?),
      status: CaseStatus.fromString(r['status'] as String?),
      caseType: r['case_type'] as String? ?? 'general',
      createdBy: r['created_by'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
      resolvedAt: r['resolved_at'] != null ? DateTime.parse(r['resolved_at'] as String) : null,
      closedAt: r['closed_at'] != null ? DateTime.parse(r['closed_at'] as String) : null,
      clientOperationId: r['client_operation_id'] as String? ?? '',
    );
  }

  FollowUpActivity _mapActivity(
    Map<String, dynamic> r, {
    String? studentName,
    String? caseTitle,
  }) {
    final author = r['author'] as Map<String, dynamic>?;
    return FollowUpActivity(
      id: r['id'] as String,
      caseId: r['case_id'] as String,
      activityType: ActivityType.fromString(r['activity_type'] as String?),
      description: r['description'] as String,
      createdBy: r['created_by'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      activityDate: r['activity_date'] as String,
      clientOperationId: r['client_operation_id'] as String? ?? '',
      authorName: author?['name'] as String?,
      authorRole: author?['role'] as String?,
      studentName: studentName,
      caseTitle: caseTitle,
    );
  }
}

