import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/follow_up/data/local_follow_up_case_repository.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/activity_type.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_priority.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_status.dart';

void main() {
  late AppDatabase db;
  late LocalFollowUpCaseRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting();
    repo = LocalFollowUpCaseRepository(db);

    // Seed profiles for all 5 roles
    final now = DateTime.now();
    await db
        .into(db.cachedProfiles)
        .insert(
          CachedProfilesCompanion.insert(
            id: 'servant-5a-1',
            authUserId: 'auth-servant-5a-1',
            serviceId: 'service-primary',
            name: 'مينا كمال',
            role: 'class_servant',
            accountStatus: 'active',
            stageId: const Value('stage-5'),
            classId: const Value('class-5a'),
            cachedAt: now,
          ),
        );

    await db
        .into(db.cachedProfiles)
        .insert(
          CachedProfilesCompanion.insert(
            id: 'leader-5a',
            authUserId: 'auth-leader-5a',
            serviceId: 'service-primary',
            name: 'أستاذ فادي',
            role: 'class_leader',
            accountStatus: 'active',
            stageId: const Value('stage-5'),
            classId: const Value('class-5a'),
            cachedAt: now,
          ),
        );

    await db
        .into(db.cachedProfiles)
        .insert(
          CachedProfilesCompanion.insert(
            id: 'servant-5b-1',
            authUserId: 'auth-servant-5b-1',
            serviceId: 'service-primary',
            name: 'كيرلس رفعت',
            role: 'class_servant',
            accountStatus: 'active',
            stageId: const Value('stage-5'),
            classId: const Value('class-5b'),
            cachedAt: now,
          ),
        );

    await db
        .into(db.cachedProfiles)
        .insert(
          CachedProfilesCompanion.insert(
            id: 'stage-leader-5',
            authUserId: 'auth-stage-leader-5',
            serviceId: 'service-primary',
            name: 'د. جورج',
            role: 'stage_leader',
            accountStatus: 'active',
            stageId: const Value('stage-5'),
            cachedAt: now,
          ),
        );

    await db
        .into(db.cachedProfiles)
        .insert(
          CachedProfilesCompanion.insert(
            id: 'overall-leader-1',
            authUserId: 'auth-overall-1',
            serviceId: 'service-primary',
            name: 'م. يوسف',
            role: 'overall_leader',
            accountStatus: 'active',
            cachedAt: now,
          ),
        );
  });

  tearDown(() async => db.close());

  group('Complete Role Workflows', () {
    test(
      'Class servant workflow: can view class cases, record activity, but cannot resolve or assign',
      () async {
        // 1. Leader creates case in Class 5A
        final c = await repo.createCase(
          serviceId: 'service-primary',
          studentId: 'student-5a-mark',
          classId: 'class-5a',
          title: 'متابعة غياب مارك',
          priority: CasePriority.high,
          createdBy: 'leader-5a',
        );

        // 2. Class servant in 5A queries cases in their scope
        final servantScopeCases = await repo
            .watchCasesForScope(
              serviceId: 'service-primary',
              classIds: {'class-5a'},
            )
            .first;

        expect(servantScopeCases, hasLength(1));
        expect(servantScopeCases.first.id, c.id);

        // 3. Class servant records an activity
        final act = await repo.recordActivity(
          caseId: c.id,
          activityType: ActivityType.call,
          description:
              'تم الاتصال بوالد مارك، اعتذر عن الغياب بسبب امتحانات الشهر',
          createdBy: 'servant-5a-1',
          activityDate: '2026-11-10',
        );

        expect(act.createdBy, 'servant-5a-1');
        expect(act.authorName, 'مينا كمال');
        expect(act.authorRole, 'class_servant');

        // 4. Verify class servant permission restrictions
        final transitions = c.status.allowedTransitions(role: 'class_servant');
        expect(
          transitions.contains(CaseStatus.resolved),
          isFalse,
          reason: 'Servant cannot resolve case',
        );
        expect(
          transitions.contains(CaseStatus.closed),
          isFalse,
          reason: 'Servant cannot close case',
        );

        // 5. Servant in 5B cannot see 5A's cases or activities
        final otherClassCases = await repo
            .watchCasesForScope(
              serviceId: 'service-primary',
              classIds: {'class-5b'},
            )
            .first;
        expect(
          otherClassCases,
          isEmpty,
          reason: 'Class 5B servant cannot see 5A cases',
        );

        final otherClassActivities = await repo
            .watchActivitiesForScope(
              serviceId: 'service-primary',
              classIds: {'class-5b'},
            )
            .first;
        expect(
          otherClassActivities,
          isEmpty,
          reason: 'Class 5B servant cannot see 5A activities',
        );
      },
    );

    test(
      'Class leader workflow: assigns multiple servants, reassigns, monitors, resolves and reopens',
      () async {
        // 1. Class leader creates case
        final c = await repo.createCase(
          serviceId: 'service-primary',
          studentId: 'student-5a-john',
          classId: 'class-5a',
          title: 'متابعة يوحنا',
          priority: CasePriority.medium,
          createdBy: 'leader-5a',
        );

        // 2. Class leader assigns two servants to the same case
        await repo.assignServants(
          caseId: c.id,
          servantIds: ['servant-5a-1', 'leader-5a'],
          assignedBy: 'leader-5a',
        );

        var assignments = await repo.watchAssignmentsForCase(c.id).first;
        expect(assignments.where((a) => a.isActive), hasLength(2));
        expect(
          assignments.map((a) => a.servantName),
          containsAll(['مينا كمال', 'أستاذ فادي']),
        );

        // 3. Class leader reassigns (removes servant-5a-1)
        final assignmentToRemove = assignments.firstWhere(
          (a) => a.servantId == 'servant-5a-1',
        );
        await repo.removeAssignment(
          assignmentId: assignmentToRemove.id,
          caseId: c.id,
          removedBy: 'leader-5a',
        );

        assignments = await repo.watchAssignmentsForCase(c.id).first;
        // Historical assignment record is preserved but marked inactive
        expect(assignments, hasLength(2));
        expect(assignments.where((a) => a.isActive), hasLength(1));

        // 4. Class leader resolves case
        final resolved = await repo.updateCaseStatus(
          caseId: c.id,
          newStatus: CaseStatus.resolved,
          actorId: 'leader-5a',
          actorRole: 'class_leader',
          note: 'تم الافتقاد وحل المشكلة',
        );
        expect(resolved.status, CaseStatus.resolved);
        expect(resolved.isResolved, isTrue);

        // 5. Class leader reopens case
        final reopened = await repo.updateCaseStatus(
          caseId: c.id,
          newStatus: CaseStatus.open,
          actorId: 'leader-5a',
          actorRole: 'class_leader',
          note: 'إعادة فتح الحالة للمتابعة المستمرة',
        );
        expect(reopened.status, CaseStatus.open);

        // All previous activities remain intact in timeline
        final allActivities = await repo.watchActivitiesForCase(c.id).first;
        expect(allActivities.length, greaterThanOrEqualTo(4));
      },
    );

    test(
      'Stage leader workflow: sees all classes in stage, manages cases across stage',
      () async {
        // Create cases in 5A and 5B (both in stage-5)
        final c5a = await repo.createCase(
          serviceId: 'service-primary',
          studentId: 'student-5a-1',
          classId: 'class-5a',
          title: 'حالة 5أ',
          priority: CasePriority.high,
          createdBy: 'leader-5a',
        );

        final c5b = await repo.createCase(
          serviceId: 'service-primary',
          studentId: 'student-5b-1',
          classId: 'class-5b',
          title: 'حالة 5ب',
          priority: CasePriority.medium,
          createdBy: 'servant-5b-1',
        );

        // Stage leader for stage-5 sees both 5a and 5b
        final stageCases = await repo
            .watchCasesForScope(
              serviceId: 'service-primary',
              classIds: {'class-5a', 'class-5b'},
            )
            .first;

        expect(stageCases, hasLength(2));
        expect(stageCases.map((c) => c.id), containsAll([c5a.id, c5b.id]));

        // Stage leader assigns servant to 5B case
        await repo.assignServants(
          caseId: c5b.id,
          servantIds: ['servant-5b-1'],
          assignedBy: 'stage-leader-5',
        );

        final bAssignments = await repo.watchAssignmentsForCase(c5b.id).first;
        expect(bAssignments.single.servantName, 'كيرلس رفعت');
        expect(bAssignments.single.assignedByName, 'د. جورج');
      },
    );

    test(
      'Overall leader workflow: sees entire service, all classes and activities',
      () async {
        await repo.createCase(
          serviceId: 'service-primary',
          studentId: 'student-5a-1',
          classId: 'class-5a',
          title: 'حالة عامة 1',
          priority: CasePriority.urgent,
          createdBy: 'overall-leader-1',
        );

        await repo.createCase(
          serviceId: 'service-primary',
          studentId: 'student-6a-1',
          classId: 'class-6a',
          title: 'حالة عامة 2 في مرحلة أخرى',
          priority: CasePriority.low,
          createdBy: 'overall-leader-1',
        );

        // Overall leader (null classIds) queries entire service
        final allServiceCases = await repo
            .watchCasesForScope(serviceId: 'service-primary', classIds: null)
            .first;

        expect(allServiceCases, hasLength(2));
        expect(
          allServiceCases.every((c) => c.serviceId == 'service-primary'),
          isTrue,
        );
      },
    );

    test('Author attribution remains permanently immutable', () async {
      final c = await repo.createCase(
        serviceId: 'service-primary',
        studentId: 'student-1',
        classId: 'class-5a',
        title: 'حالة تدقيق المؤلف',
        priority: CasePriority.medium,
        createdBy: 'servant-5a-1',
      );

      final act = await repo.recordActivity(
        caseId: c.id,
        activityType: ActivityType.visit,
        description: 'زيارة منزلية بواسطة الخادم مينا كمال',
        createdBy: 'servant-5a-1',
        activityDate: '2026-11-01',
      );

      // Verify author
      final activities = await repo.watchActivitiesForCase(c.id).first;
      final retrieved = activities.firstWhere((a) => a.id == act.id);
      expect(retrieved.createdBy, 'servant-5a-1');
      expect(retrieved.authorName, 'مينا كمال');
      expect(retrieved.authorRole, 'class_servant');

      // Even if servant's role or status changes in profile later, original record has stable creator ID
      await (db.update(
        db.cachedProfiles,
      )..where((p) => p.id.equals('servant-5a-1'))).write(
        const CachedProfilesCompanion(
          role: Value('class_leader'),
          accountStatus: Value('inactive'),
        ),
      );

      final activitiesAfter = await repo.watchActivitiesForCase(c.id).first;
      final retrievedAfter = activitiesAfter.firstWhere((a) => a.id == act.id);
      expect(retrievedAfter.createdBy, 'servant-5a-1');
      expect(retrievedAfter.authorName, 'مينا كمال');
    });
  });
}
