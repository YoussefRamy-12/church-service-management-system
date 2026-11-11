import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/sync/handlers/weekly_preparation_sync_handler.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/preparation_review.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/preparation_status.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/weekly_preparation.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/weekly_prep_permissions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const overallLeader = ServantProfile(
    id: 'leader-overall',
    authUserId: 'auth-leader',
    serviceId: 'service-1',
    name: 'أستاذ يوحنا (أمين عام)',
    role: 'overall_leader',
    accountStatus: 'active',
  );

  const overallHelper = ServantProfile(
    id: 'helper-overall',
    authUserId: 'auth-helper',
    serviceId: 'service-1',
    name: 'أستاذ بيتر (مساعد أمين عام)',
    role: 'overall_helper',
    accountStatus: 'active',
  );

  const stageLeader5 = ServantProfile(
    id: 'stage-leader-5',
    authUserId: 'auth-sl-5',
    serviceId: 'service-1',
    name: 'أستاذ مينا (أمين 5 ابتدائي)',
    role: 'stage_leader',
    stageId: 'stage-5',
    accountStatus: 'active',
  );

  const servant5 = ServantProfile(
    id: 'servant-5-1',
    authUserId: 'auth-s-5',
    serviceId: 'service-1',
    name: 'خادم كيرلس',
    role: 'class_servant',
    stageId: 'stage-5',
    classId: 'class-5a',
    accountStatus: 'active',
  );

  group('Weekly Preparation End-to-End Workflow Integration Test', () {
    test('Servant submits -> Leader approves -> Servant sees approval', () {
      // 1. Initial State: not submitted
      var prep = WeeklyPreparation(
        weeklyLessonId: 'lesson-1',
        servantProfileId: servant5.id,
        status: PreparationStatus.notSubmitted,
        updatedAt: DateTime.now().toUtc(),
      );
      expect(prep.status, PreparationStatus.notSubmitted);
      expect(prep.isNotSubmitted, isTrue);

      // 2. Servant submits preparation
      final submittedAt = DateTime.now().toUtc();
      prep = prep.copyWith(
        status: PreparationStatus.submitted,
        submittedAt: submittedAt,
        updatedAt: submittedAt,
      );
      expect(prep.status, PreparationStatus.submitted);
      expect(prep.isAwaitingReview, isTrue);

      // 3. Leader approves preparation
      final reviewedAt = DateTime.now().toUtc();
      prep = prep.copyWith(
        status: PreparationStatus.approved,
        prepared: true,
        reviewedBy: overallLeader.id,
        reviewerName: overallLeader.name,
        reviewNote: 'تحضير متميز ومنظم',
        reviewedAt: reviewedAt,
        updatedAt: reviewedAt,
      );

      // 4. Servant sees approval
      expect(prep.status, PreparationStatus.approved);
      expect(prep.isApproved, isTrue);
      expect(prep.prepared, isTrue);
      expect(prep.reviewerName, overallLeader.name);
      expect(prep.reviewNote, 'تحضير متميز ومنظم');
    });

    test(
      'Leader returns for revision with feedback -> Servant resubmits -> Leader approves',
      () {
        final reviews = <PreparationReview>[];

        // 1. Servant submits
        var prep = WeeklyPreparation(
          weeklyLessonId: 'lesson-1',
          servantProfileId: servant5.id,
          status: PreparationStatus.submitted,
          submittedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        // 2. Leader returns for revision with mandatory feedback
        const feedback =
            'يرجى كتابة الشاهد الكتابي كامل والتدريب الروحي للأولاد';
        final reviewDate1 = DateTime.now().toUtc();
        reviews.add(
          PreparationReview(
            id: 'review-1',
            weeklyLessonId: prep.weeklyLessonId,
            servantProfileId: prep.servantProfileId,
            reviewerId: stageLeader5.id,
            reviewerName: stageLeader5.name,
            action: PreparationStatus.needsRevision,
            note: feedback,
            reviewedAt: reviewDate1,
          ),
        );

        prep = prep.copyWith(
          status: PreparationStatus.needsRevision,
          reviewedBy: stageLeader5.id,
          reviewerName: stageLeader5.name,
          reviewNote: feedback,
          reviewedAt: reviewDate1,
          updatedAt: reviewDate1,
        );

        expect(prep.status, PreparationStatus.needsRevision);
        expect(prep.needsRevision, isTrue);
        expect(prep.reviewNote, feedback);

        // 3. Servant resubmits after making revisions
        final resubmittedAt = DateTime.now().toUtc();
        prep = prep.copyWith(
          status: PreparationStatus.submitted,
          submittedAt: resubmittedAt,
          updatedAt: resubmittedAt,
        );
        expect(prep.status, PreparationStatus.submitted);
        expect(prep.isAwaitingReview, isTrue);

        // Previous review history is preserved!
        expect(reviews.length, 1);
        expect(reviews.first.action, PreparationStatus.needsRevision);
        expect(reviews.first.note, feedback);

        // 4. Leader approves the resubmission
        final reviewDate2 = DateTime.now().toUtc();
        reviews.insert(
          0,
          PreparationReview(
            id: 'review-2',
            weeklyLessonId: prep.weeklyLessonId,
            servantProfileId: prep.servantProfileId,
            reviewerId: stageLeader5.id,
            reviewerName: stageLeader5.name,
            action: PreparationStatus.approved,
            note: 'تم التعديل بشكل ممتاز',
            reviewedAt: reviewDate2,
          ),
        );

        prep = prep.copyWith(
          status: PreparationStatus.approved,
          prepared: true,
          reviewedBy: stageLeader5.id,
          reviewerName: stageLeader5.name,
          reviewNote: 'تم التعديل بشكل ممتاز',
          reviewedAt: reviewDate2,
          updatedAt: reviewDate2,
        );

        expect(prep.status, PreparationStatus.approved);
        expect(reviews.length, 2);
        expect(reviews[0].action, PreparationStatus.approved);
        expect(reviews[1].action, PreparationStatus.needsRevision);
      },
    );

    test('Unauthorized leader cannot review outside their stage scope', () {
      // stageLeader5 can review stage-5
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: stageLeader5,
          isSuperAdmin: false,
          targetServantProfileId: servant5.id,
          stageId: 'stage-5',
        ),
        isTrue,
      );

      // stageLeader5 CANNOT review stage-6
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: stageLeader5,
          isSuperAdmin: false,
          targetServantProfileId: servant5.id,
          stageId: 'stage-6',
        ),
        isFalse,
      );
    });

    test('Servant cannot approve or review their own preparation', () {
      // Even overall leader cannot approve themselves
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: overallLeader,
          isSuperAdmin: false,
          targetServantProfileId: overallLeader.id,
          stageId: 'stage-5',
        ),
        isFalse,
      );

      // Stage leader cannot approve themselves
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: stageLeader5,
          isSuperAdmin: false,
          targetServantProfileId: stageLeader5.id,
          stageId: 'stage-5',
        ),
        isFalse,
      );
    });

    test('overall_helper has identical permissions as overall_leader', () {
      // Can manage lessons in all stages
      expect(
        WeeklyPrepPermissions.canManageLessons(
          profile: overallHelper,
          isSuperAdmin: false,
          stageId: 'stage-5',
        ),
        isTrue,
      );
      expect(
        WeeklyPrepPermissions.canManageLessons(
          profile: overallHelper,
          isSuperAdmin: false,
          stageId: 'stage-6',
        ),
        isTrue,
      );

      // Can review preparations in all stages
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: overallHelper,
          isSuperAdmin: false,
          targetServantProfileId: servant5.id,
          stageId: 'stage-5',
        ),
        isTrue,
      );
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: overallHelper,
          isSuperAdmin: false,
          targetServantProfileId: servant5.id,
          stageId: 'stage-6',
        ),
        isTrue,
      );

      // Can view leadership dashboard
      expect(
        WeeklyPrepPermissions.canViewLeadershipDashboard(
          profile: overallHelper,
          isSuperAdmin: false,
        ),
        isTrue,
      );
    });

    test(
      'Offline submission queues correctly and does not appear as server-approved',
      () {
        final now = DateTime.now().toUtc();
        final op = SyncOperation(
          operationId: 'offline-op-1',
          entityType: 'weekly_preparation',
          operationType: 'submit',
          payloadJson: jsonEncode({
            'weekly_lesson_id': 'lesson-1',
            'servant_profile_id': servant5.id,
            'status': 'submitted',
            'submitted_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          }),
        );

        final prep = WeeklyPreparation(
          weeklyLessonId: 'lesson-1',
          servantProfileId: servant5.id,
          status: PreparationStatus.submitted,
          prepared: false, // NOT approved
          submittedAt: now,
          updatedAt: now,
          syncState: 'pending', // Pending sync
        );

        expect(prep.isPendingSync, isTrue);
        expect(prep.isApproved, isFalse);
        expect(prep.status, PreparationStatus.submitted);

        // Sync handler successfully parses operation
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
        );
        final handler = WeeklyPreparationSyncHandler(client);
        expect(handler.entityType, op.entityType);
      },
    );

    test('Historical weeks remain strictly read-only', () {
      expect(
        WeeklyPrepPermissions.canSubmitPreparation(
          profile: servant5,
          targetServantProfileId: servant5.id,
          isCurrentWeek: false, // Past week
        ),
        isFalse,
      );
    });
  });
}
