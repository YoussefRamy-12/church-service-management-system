import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/follow_up/data/local_follow_up_case_repository.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/activity_type.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_priority.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_status.dart';

void main() {
  late AppDatabase db;
  late LocalFollowUpCaseRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalFollowUpCaseRepository(db);
  });

  tearDown(() async => db.close());

  test('Creates follow-up case with initial assignment and activity', () async {
    final created = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'متابعة غياب أسبوعين',
      description: 'غياب بدون إذن',
      priority: CasePriority.high,
      createdBy: 'servant-1',
      initialServantIds: ['servant-2', 'servant-3'],
    );

    expect(created.id, isNotEmpty);
    expect(created.title, 'متابعة غياب أسبوعين');
    expect(created.status, CaseStatus.assigned);
    expect(created.priority, CasePriority.high);

    // Verify assignments
    final assignments = await repo.watchAssignmentsForCase(created.id).first;
    expect(assignments, hasLength(2));
    expect(assignments.map((a) => a.servantId), containsAll(['servant-2', 'servant-3']));
    expect(assignments.every((a) => a.isActive), isTrue);

    // Verify initial activity was logged
    final activities = await repo.watchActivitiesForCase(created.id).first;
    expect(activities, hasLength(1));
    expect(activities.first.description, contains('تم فتح حالة المتابعة'));
  });

  test('Scoped query isolates cases by class', () async {
    await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'حالة فصل 5أ',
      priority: CasePriority.medium,
      createdBy: 'servant-1',
    );
    await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-2',
      classId: 'class-5b',
      title: 'حالة فصل 5ب',
      priority: CasePriority.medium,
      createdBy: 'servant-2',
    );

    // Query with class-5a scope
    final cases5a = await repo
        .watchCasesForScope(serviceId: 'service-1', classIds: {'class-5a'})
        .first;
    expect(cases5a, hasLength(1));
    expect(cases5a.first.title, 'حالة فصل 5أ');

    // Query with class-5b scope
    final cases5b = await repo
        .watchCasesForScope(serviceId: 'service-1', classIds: {'class-5b'})
        .first;
    expect(cases5b, hasLength(1));
    expect(cases5b.first.title, 'حالة فصل 5ب');

    // Overall query (null classIds) sees both
    final allCases = await repo
        .watchCasesForScope(serviceId: 'service-1', classIds: null)
        .first;
    expect(allCases, hasLength(2));
  });

  test('Multiple servant assignment and removal preserves history', () async {
    final c = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'حالة متابعة',
      priority: CasePriority.medium,
      createdBy: 'servant-1',
    );

    // Assign servants
    await repo.assignServants(
      caseId: c.id,
      servantIds: ['servant-A', 'servant-B'],
      assignedBy: 'leader-1',
    );

    var assignments = await repo.watchAssignmentsForCase(c.id).first;
    expect(assignments.where((a) => a.isActive), hasLength(2));

    // Remove servant A
    final assignmentA = assignments.firstWhere((a) => a.servantId == 'servant-A');
    await repo.removeAssignment(
      assignmentId: assignmentA.id,
      caseId: c.id,
      removedBy: 'leader-1',
    );

    assignments = await repo.watchAssignmentsForCase(c.id).first;
    // History is preserved: total is 2, active is 1
    expect(assignments, hasLength(2));
    expect(assignments.where((a) => a.isActive), hasLength(1));
    expect(assignments.firstWhere((a) => a.servantId == 'servant-A').isActive, isFalse);

    // Activities log records the assignment removal
    final activities = await repo.watchActivitiesForCase(c.id).first;
    expect(activities.any((act) => act.description.contains('إلغاء تكليف')), isTrue);
  });

  test('Status update generates traceable activity and updates timestamps', () async {
    final c = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'حالة للمتابعة',
      priority: CasePriority.medium,
      createdBy: 'servant-1',
    );

    final resolved = await repo.updateCaseStatus(
      caseId: c.id,
      newStatus: CaseStatus.resolved,
      actorId: 'leader-1',
      actorRole: 'class_leader',
      note: 'تم التواصل وعاد التلميذ للحضور',
    );

    expect(resolved.status, CaseStatus.resolved);
    expect(resolved.resolvedAt, isNotNull);

    // Check activity log
    final activities = await repo.watchActivitiesForCase(c.id).first;
    final statusAct = activities.firstWhere(
      (a) => a.activityType == ActivityType.statusChange,
    );
    expect(statusAct.description, contains('تم التواصل وعاد التلميذ'));
    expect(statusAct.createdBy, 'leader-1');
  });

  test('Recording an activity automatically advances open case to in_progress', () async {
    final c = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'متابعة جديدة',
      priority: CasePriority.low,
      createdBy: 'servant-1',
    );

    expect(c.status, CaseStatus.open);

    // Record visit activity
    await repo.recordActivity(
      caseId: c.id,
      activityType: ActivityType.visit,
      description: 'تمت زيارة منزل التلميذ ولقاء والدته',
      createdBy: 'servant-2',
      activityDate: '2026-11-10',
    );

    final updated = await repo.getCaseById(c.id);
    expect(updated?.status, CaseStatus.inProgress);

    final activities = await repo.watchActivitiesForCase(c.id).first;
    final visitAct = activities.firstWhere((a) => a.activityType == ActivityType.visit);
    expect(visitAct.description, 'تمت زيارة منزل التلميذ ولقاء والدته');
    expect(visitAct.createdBy, 'servant-2');
  });
  test('case and activity streams emit immediately after each mutation', () async {
    final cases = StreamIterator(
      repo.watchCasesForScope(serviceId: 'service-1'),
    );
    final activities = StreamIterator(
      repo.watchActivitiesForStudent('student-1'),
    );
    final scopeActivities = StreamIterator(
      repo.watchActivitiesForScope(serviceId: 'service-1'),
    );

    addTearDown(cases.cancel);
    addTearDown(activities.cancel);
    addTearDown(scopeActivities.cancel);

    expect(await cases.moveNext(), isTrue);
    expect(cases.current, isEmpty);
    expect(await activities.moveNext(), isTrue);
    expect(activities.current, isEmpty);
    expect(await scopeActivities.moveNext(), isTrue);
    expect(scopeActivities.current, isEmpty);

    final created = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'متابعة فورية',
      priority: CasePriority.medium,
      createdBy: 'servant-1',
    );

    expect(await cases.moveNext(), isTrue);
    expect(cases.current.map((item) => item.id), contains(created.id));
    expect(await activities.moveNext(), isTrue);
    expect(
      activities.current.any(
        (activity) => activity.description.contains('تم فتح حالة المتابعة'),
      ),
      isTrue,
    );
    expect(await scopeActivities.moveNext(), isTrue);
    expect(scopeActivities.current, hasLength(1));

    await repo.updateCaseStatus(
      caseId: created.id,
      newStatus: CaseStatus.inProgress,
      actorId: 'servant-1',
      actorRole: 'class_servant',
    );

    expect(await cases.moveNext(), isTrue);
    expect(cases.current.single.status, CaseStatus.inProgress);
    expect(await activities.moveNext(), isTrue);
    expect(
      activities.current.any(
        (activity) => activity.activityType == ActivityType.statusChange,
      ),
      isTrue,
    );
    expect(await scopeActivities.moveNext(), isTrue);
    expect(
      scopeActivities.current.any(
        (activity) => activity.activityType == ActivityType.statusChange,
      ),
      isTrue,
    );

    await repo.recordActivity(
      caseId: created.id,
      activityType: ActivityType.call,
      description: 'تم التواصل مع ولي الأمر',
      createdBy: 'servant-1',
      activityDate: '2026-11-11',
    );

    expect(await activities.moveNext(), isTrue);
    expect(
      activities.current.any(
        (activity) => activity.description == 'تم التواصل مع ولي الأمر',
      ),
      isTrue,
    );
    expect(await scopeActivities.moveNext(), isTrue);
    expect(
      scopeActivities.current.any(
        (activity) => activity.description == 'تم التواصل مع ولي الأمر',
      ),
      isTrue,
    );
  });

}

