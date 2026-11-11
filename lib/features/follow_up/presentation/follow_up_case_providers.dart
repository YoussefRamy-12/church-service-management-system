import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/student_providers.dart';
import '../data/local_follow_up_case_repository.dart';
import '../data/offline_first_follow_up_case_repository.dart';
import '../data/online_follow_up_case_repository.dart';
import '../domain/entities/case_assignment.dart';
import '../domain/entities/follow_up_activity.dart';
import '../domain/entities/follow_up_case.dart';
import '../domain/entities/follow_up_student_item.dart';
import '../domain/repositories/follow_up_case_repository.dart';
import 'follow_up_scope.dart';

// --- Repositories ---

final localFollowUpCaseRepositoryProvider =
    Provider<LocalFollowUpCaseRepository>((ref) {
  return LocalFollowUpCaseRepository(ref.watch(appDatabaseProvider));
});

final onlineFollowUpCaseRepositoryProvider =
    Provider<OnlineFollowUpCaseRepository>((ref) {
  return OnlineFollowUpCaseRepository(ref.watch(supabaseClientProvider));
});

final followUpCaseRepositoryProvider = Provider<FollowUpCaseRepository>((ref) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return ref.watch(onlineFollowUpCaseRepositoryProvider);
  }
  return OfflineFirstFollowUpCaseRepository(
    local: ref.watch(localFollowUpCaseRepositoryProvider),
    queue: ref.watch(syncQueueRepositoryProvider),
  );
});

// --- Scope Provider ---

final followUpScopeProvider =
    FutureProvider.family<FollowUpScope, String>((ref, serviceId) async {
  final services = ref.watch(serviceRepositoryProvider);
  final profile = await ref.watch(currentServantProfileProvider.future);
  return resolveFollowUpClassScope(
    services: services,
    serviceId: serviceId,
    profile: profile,
  );
});

// --- Cases Stream in Scope ---

final followUpCasesInScopeProvider =
    StreamProvider.family<List<FollowUpCase>, String>((ref, serviceId) async* {
  final scopeAsync = await ref.watch(followUpScopeProvider(serviceId).future);
  final repo = ref.watch(followUpCaseRepositoryProvider);

  yield* repo.watchCasesForScope(
    serviceId: serviceId,
    classIds: scopeAsync.classIds,
  );
});

// --- Single Case Provider ---

final followUpCaseByIdProvider =
    FutureProvider.family<FollowUpCase?, String>((ref, caseId) async {
  final repo = ref.watch(followUpCaseRepositoryProvider);
  return repo.getCaseById(caseId);
});

// --- Case Assignments Stream ---

final caseAssignmentsProvider =
    StreamProvider.family<List<CaseAssignment>, String>((ref, caseId) {
  final repo = ref.watch(followUpCaseRepositoryProvider);
  return repo.watchAssignmentsForCase(caseId);
});

// --- Case Activities Stream ---

final caseActivitiesProvider =
    StreamProvider.family<List<FollowUpActivity>, String>((ref, caseId) {
  final repo = ref.watch(followUpCaseRepositoryProvider);
  return repo.watchActivitiesForCase(caseId);
});

// --- Activities Stream in Scope ---

final followUpActivitiesInScopeProvider =
    StreamProvider.family<List<FollowUpActivity>, String>((ref, serviceId) async* {
  final scopeAsync = await ref.watch(followUpScopeProvider(serviceId).future);
  final repo = ref.watch(followUpCaseRepositoryProvider);

  yield* repo.watchActivitiesForScope(
    serviceId: serviceId,
    classIds: scopeAsync.classIds,
  );
});

// --- Student Activities Stream ---

final studentActivitiesProvider =
    StreamProvider.family<List<FollowUpActivity>, String>((ref, studentId) {
  final repo = ref.watch(followUpCaseRepositoryProvider);
  return repo.watchActivitiesForStudent(studentId);
});

// --- Student Cases Stream ---

final studentCasesProvider =
    StreamProvider.family<List<FollowUpCase>, ({String serviceId, String studentId})>(
        (ref, params) {
  final repo = ref.watch(followUpCaseRepositoryProvider);
  return repo.watchCasesForScope(
    serviceId: params.serviceId,
    studentId: params.studentId,
  );
});

/// Invalidates every case-based follow-up view affected by a mutation.
///
/// Online repository streams are one-shot Supabase queries rather than
/// Realtime subscriptions, so explicit invalidation is required after writes.
/// Local Drift streams continue to update from their watched tables.
void invalidateFollowUpCaseData(
  WidgetRef ref, {
  required String serviceId,
  String? studentId,
  String? caseId,
}) {
  ref.invalidate(followUpCasesInScopeProvider(serviceId));
  ref.invalidate(followUpActivitiesInScopeProvider(serviceId));
  ref.invalidate(followUpStudentItemsProvider(serviceId));

  if (studentId != null) {
    ref.invalidate(
      studentCasesProvider((serviceId: serviceId, studentId: studentId)),
    );
    ref.invalidate(studentActivitiesProvider(studentId));
  }

  if (caseId != null) {
    ref.invalidate(followUpCaseByIdProvider(caseId));
    ref.invalidate(caseAssignmentsProvider(caseId));
    ref.invalidate(caseActivitiesProvider(caseId));
  }
}

// --- Aggregated Follow-up Student Items in Scope ---

final followUpStudentItemsProvider =
    FutureProvider.family<List<FollowUpStudentItem>, String>((ref, serviceId) async {
  final scope = await ref.watch(followUpScopeProvider(serviceId).future);
  final services = ref.read(serviceRepositoryProvider);
  final studentRepo = ref.read(studentRepositoryProvider);
  final localStudents = ref.read(localStudentRepositoryProvider);
  final meetingsRepo = ref.read(meetingRepositoryProvider);
  final offlineEnabled = ref.read(offlineSyncEnabledProvider);
  final db = ref.read(appDatabaseProvider);
  final client = ref.read(supabaseClientProvider);

  // 1. Get Stages & Classes in scope
  try {
    await services.refreshStages(serviceId);
  } catch (_) {}
  final stages = (await services.getStages(serviceId))
      .where((s) => scope.stageIds == null || scope.stageIds!.contains(s.id))
      .toList();

  final classMap = <String, String>{};
  for (final stage in stages) {
    try {
      await services.refreshClasses(stage.id);
    } catch (_) {}
    final stageClasses = await services.getClasses(stage.id);
    for (final c in stageClasses) {
      if (scope.classIds == null || scope.classIds!.contains(c.id)) {
        classMap[c.id] = c.name;
      }
    }
  }

  // 2. Load all students across classes in scope
  final allStudents = <Student>[];
  for (final classId in classMap.keys) {
    try {
      await studentRepo.refreshStudents(classId);
    } catch (_) {}
    final list = offlineEnabled
        ? await localStudents.watchStudentsForClass(classId).first
        : await studentRepo.watchStudentsForClass(classId).first;
    allStudents.addAll(list);
  }

  final approvedStudents = allStudents
      .where((s) => s.isApproved && s.currentClassId != null)
      .toList();

  if (approvedStudents.isEmpty) {
    return const [];
  }

  // 3. Load completed meetings for absence calculations
  try {
    await meetingsRepo.refresh(serviceId);
  } catch (_) {}
  final allMeetings = await meetingsRepo.watchMeetings(serviceId).first;
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final completedMeetings = allMeetings
      .where((m) => !m.meetingDate.isAfter(todayDate))
      .toList()
    ..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));

  final meetingIds = completedMeetings.map((m) => m.id).toList();

  // 4. Load attendance records for approved students
  final attendedMeetingIdsByStudent = <String, Set<String>>{};
  if (meetingIds.isNotEmpty) {
    if (offlineEnabled) {
      final records = await (db.select(db.cachedAttendanceRecords)
            ..where((row) => row.meetingId.isIn(meetingIds))
            ..where((row) =>
                row.studentId.isIn(approvedStudents.map((s) => s.id).toList())))
          .get();
      for (final r in records) {
        attendedMeetingIdsByStudent
            .putIfAbsent(r.studentId, () => {})
            .add(r.meetingId);
      }
    } else {
      try {
        final remote = await client
            .from('attendance_records')
            .select('meeting_id, student_id')
            .inFilter('meeting_id', meetingIds)
            .inFilter('student_id', approvedStudents.map((s) => s.id).toList());
        for (final r in remote) {
          final sId = r['student_id'] as String;
          final mId = r['meeting_id'] as String;
          attendedMeetingIdsByStudent
              .putIfAbsent(sId, () => {})
              .add(mId);
        }
      } catch (_) {}
    }
  }

  // 5. Load cases for these students to calculate active/total cases & latest follow-up
  final caseRepo = ref.read(followUpCaseRepositoryProvider);
  final casesInScope = await caseRepo
      .watchCasesForScope(serviceId: serviceId, classIds: scope.classIds)
      .first;

  final casesByStudent = <String, List<FollowUpCase>>{};
  for (final c in casesInScope) {
    casesByStudent.putIfAbsent(c.studentId, () => []).add(c);
  }

  // 6. Build final items list
  final items = <FollowUpStudentItem>[];
  for (final student in approvedStudents) {
    final enrolledAt = student.enrollmentAt;
    final enrollmentDate = enrolledAt == null
        ? todayDate
        : DateTime(enrolledAt.year, enrolledAt.month, enrolledAt.day);

    final eligibleMeetings = completedMeetings
        .where((m) => !m.meetingDate.isBefore(enrollmentDate))
        .toList();

    final attendedSet = attendedMeetingIdsByStudent[student.id] ?? const {};
    final absenceCount = eligibleMeetings.where((m) => !attendedSet.contains(m.id)).length;

    final studentCases = casesByStudent[student.id] ?? const [];
    final activeCasesCount = studentCases.where((c) => c.isActive).length;

    // Latest follow-up info from cases or legacy follow_up_records
    String? latestDate;
    String? latestAuthor;
    if (studentCases.isNotEmpty) {
      final latestCase = studentCases.first;
      latestDate = latestCase.latestActivityDate ??
          "${latestCase.updatedAt.year}-${latestCase.updatedAt.month.toString().padLeft(2, '0')}-${latestCase.updatedAt.day.toString().padLeft(2, '0')}";
      latestAuthor = latestCase.latestActivityAuthorName ?? latestCase.creatorName;
    }

    final className = classMap[student.currentClassId] ?? 'فصل غير محدد';

    items.add(
      FollowUpStudentItem(
        student: student,
        className: className,
        absenceCount: absenceCount,
        totalEligibleMeetings: eligibleMeetings.length,
        activeCasesCount: activeCasesCount,
        totalCasesCount: studentCases.length,
        latestFollowUpDate: latestDate,
        latestFollowUpAuthor: latestAuthor,
      ),
    );
  }

  return items;
});
