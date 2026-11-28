import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/prep_date_formatter.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/preparation_review.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/preparation_status.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/weekly_preparation.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/weekly_prep_permissions.dart';

void main() {
  group('PreparationStatus State Machine', () {
    test('parses from string correctly with fallback', () {
      expect(
        PreparationStatus.fromString('not_submitted'),
        PreparationStatus.notSubmitted,
      );
      expect(
        PreparationStatus.fromString('submitted'),
        PreparationStatus.submitted,
      );
      expect(
        PreparationStatus.fromString('approved'),
        PreparationStatus.approved,
      );
      expect(
        PreparationStatus.fromString('needs_revision'),
        PreparationStatus.needsRevision,
      );
      expect(
        PreparationStatus.fromString(null),
        PreparationStatus.notSubmitted,
      );
      expect(
        PreparationStatus.fromString('unknown_status'),
        PreparationStatus.notSubmitted,
      );
    });

    test('valid state transitions', () {
      // not_submitted can only transition to submitted
      expect(
        PreparationStatus.notSubmitted.canTransitionTo(
          PreparationStatus.submitted,
        ),
        isTrue,
      );
      expect(
        PreparationStatus.notSubmitted.canTransitionTo(
          PreparationStatus.approved,
        ),
        isFalse,
      );
      expect(
        PreparationStatus.notSubmitted.canTransitionTo(
          PreparationStatus.needsRevision,
        ),
        isFalse,
      );

      // submitted can transition to approved or needs_revision
      expect(
        PreparationStatus.submitted.canTransitionTo(PreparationStatus.approved),
        isTrue,
      );
      expect(
        PreparationStatus.submitted.canTransitionTo(
          PreparationStatus.needsRevision,
        ),
        isTrue,
      );
      expect(
        PreparationStatus.submitted.canTransitionTo(
          PreparationStatus.notSubmitted,
        ),
        isFalse,
      );

      // needs_revision can transition to submitted (resubmit)
      expect(
        PreparationStatus.needsRevision.canTransitionTo(
          PreparationStatus.submitted,
        ),
        isTrue,
      );
      expect(
        PreparationStatus.needsRevision.canTransitionTo(
          PreparationStatus.approved,
        ),
        isFalse,
      );

      // approved is terminal (no further transitions)
      expect(
        PreparationStatus.approved.canTransitionTo(PreparationStatus.submitted),
        isFalse,
      );
      expect(
        PreparationStatus.approved.canTransitionTo(
          PreparationStatus.needsRevision,
        ),
        isFalse,
      );
    });

    test('Arabic labels and icons are correctly defined', () {
      expect(PreparationStatus.notSubmitted.labelArabic, 'لم يتم الإرسال');
      expect(PreparationStatus.submitted.labelArabic, 'بانتظار المراجعة');
      expect(PreparationStatus.approved.labelArabic, 'تم الاعتماد');
      expect(PreparationStatus.needsRevision.labelArabic, 'يحتاج إلى تعديل');
    });
  });

  group('WeeklyPrepPermissions Rules', () {
    const overallLeader = ServantProfile(
      id: 'leader-1',
      authUserId: 'auth-leader-1',
      serviceId: 'service-1',
      name: 'Leader John',
      role: 'overall_leader',
      accountStatus: 'active',
    );

    const overallHelper = ServantProfile(
      id: 'helper-1',
      authUserId: 'auth-helper-1',
      serviceId: 'service-1',
      name: 'Helper Mark',
      role: 'overall_helper',
      accountStatus: 'active',
    );

    const stageLeader = ServantProfile(
      id: 'stage-leader-1',
      authUserId: 'auth-stage-1',
      serviceId: 'service-1',
      name: 'Stage Leader Peter',
      role: 'stage_leader',
      stageId: 'stage-5',
      accountStatus: 'active',
    );

    const classLeader = ServantProfile(
      id: 'class-leader-1',
      authUserId: 'auth-class-1',
      serviceId: 'service-1',
      name: 'Class Leader Paul',
      role: 'class_leader',
      stageId: 'stage-5',
      classId: 'class-5a',
      accountStatus: 'active',
    );

    const classServant = ServantProfile(
      id: 'servant-1',
      authUserId: 'auth-servant-1',
      serviceId: 'service-1',
      name: 'Servant Luke',
      role: 'class_servant',
      stageId: 'stage-5',
      classId: 'class-5a',
      accountStatus: 'active',
    );

    test(
      'overall_helper has identical management permissions as overall_leader',
      () {
        expect(
          WeeklyPrepPermissions.canManageLessons(
            profile: overallLeader,
            isSuperAdmin: false,
          ),
          isTrue,
        );
        expect(
          WeeklyPrepPermissions.canManageLessons(
            profile: overallHelper,
            isSuperAdmin: false,
          ),
          isTrue,
        );
        expect(
          WeeklyPrepPermissions.canViewLeadershipDashboard(
            profile: overallLeader,
            isSuperAdmin: false,
          ),
          isTrue,
        );
        expect(
          WeeklyPrepPermissions.canViewLeadershipDashboard(
            profile: overallHelper,
            isSuperAdmin: false,
          ),
          isTrue,
        );
      },
    );

    test('stage leader scope enforcement', () {
      expect(
        WeeklyPrepPermissions.canManageLessons(
          profile: stageLeader,
          isSuperAdmin: false,
          stageId: 'stage-5',
        ),
        isTrue,
      );
      expect(
        WeeklyPrepPermissions.canManageLessons(
          profile: stageLeader,
          isSuperAdmin: false,
          stageId: 'stage-6',
        ),
        isFalse,
      );
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: stageLeader,
          isSuperAdmin: false,
          targetServantProfileId: 'servant-1',
          stageId: 'stage-5',
        ),
        isTrue,
      );
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: stageLeader,
          isSuperAdmin: false,
          targetServantProfileId: 'servant-1',
          stageId: 'stage-6',
        ),
        isFalse,
      );
    });

    test('servant cannot approve or review their own preparation', () {
      // overall_leader cannot review own preparation
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: overallLeader,
          isSuperAdmin: false,
          targetServantProfileId: overallLeader.id,
          stageId: 'stage-5',
        ),
        isFalse,
      );

      // stage_leader cannot review own preparation
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: stageLeader,
          isSuperAdmin: false,
          targetServantProfileId: stageLeader.id,
          stageId: 'stage-5',
        ),
        isFalse,
      );
    });

    test('class servants and class leaders cannot review preparations', () {
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: classServant,
          isSuperAdmin: false,
          targetServantProfileId: 'servant-2',
          stageId: 'stage-5',
        ),
        isFalse,
      );
      expect(
        WeeklyPrepPermissions.canReviewPreparation(
          profile: classLeader,
          isSuperAdmin: false,
          targetServantProfileId: 'servant-2',
          stageId: 'stage-5',
        ),
        isFalse,
      );
    });

    test('submission is restricted to current week and own profile', () {
      expect(
        WeeklyPrepPermissions.canSubmitPreparation(
          profile: classServant,
          targetServantProfileId: classServant.id,
          isCurrentWeek: true,
        ),
        isTrue,
      );
      // Historical weeks are read-only
      expect(
        WeeklyPrepPermissions.canSubmitPreparation(
          profile: classServant,
          targetServantProfileId: classServant.id,
          isCurrentWeek: false,
        ),
        isFalse,
      );
      // Cannot submit on behalf of someone else
      expect(
        WeeklyPrepPermissions.canSubmitPreparation(
          profile: classServant,
          targetServantProfileId: 'other-servant',
          isCurrentWeek: true,
        ),
        isFalse,
      );
    });
  });

  group(
    'WeeklyPreparation and PreparationReview entity JSON serialization',
    () {
      test('WeeklyPreparation serialization preserves all audit fields', () {
        final now = DateTime.utc(2026, 11, 11, 10, 0);
        final prep = WeeklyPreparation(
          weeklyLessonId: 'lesson-1',
          servantProfileId: 'servant-1',
          servantName: 'Michael',
          stageName: 'خامسة ابتدائي',
          className: 'فصل 5/1',
          status: PreparationStatus.submitted,
          prepared: false,
          submittedAt: now,
          reviewedAt: null,
          reviewedBy: null,
          reviewerName: null,
          reviewNote: null,
          updatedAt: now,
          syncState: 'pending',
        );

        expect(prep.isPendingSync, isTrue);
        expect(prep.isAwaitingReview, isTrue);
        expect(prep.isApproved, isFalse);

        final json = prep.toJson();
        final fromJson = WeeklyPreparation.fromJson(json);

        expect(fromJson.weeklyLessonId, prep.weeklyLessonId);
        expect(fromJson.servantProfileId, prep.servantProfileId);
        expect(fromJson.status, PreparationStatus.submitted);
        expect(fromJson.syncState, 'pending');
        expect(fromJson.submittedAt, now);
      });

      test('PreparationReview preserves review history', () {
        final now = DateTime.utc(2026, 11, 11, 12, 30);
        final review = PreparationReview(
          id: 'review-1',
          weeklyLessonId: 'lesson-1',
          servantProfileId: 'servant-1',
          reviewerId: 'reviewer-1',
          reviewerName: 'Leader Peter',
          action: PreparationStatus.needsRevision,
          note: 'يرجى مراجعة الآية وحفظ الشاهد جيداً',
          reviewedAt: now,
        );

        final json = review.toJson();
        final fromJson = PreparationReview.fromJson(json);

        expect(fromJson.id, 'review-1');
        expect(fromJson.action, PreparationStatus.needsRevision);
        expect(fromJson.note, 'يرجى مراجعة الآية وحفظ الشاهد جيداً');
        expect(fromJson.reviewerName, 'Leader Peter');
        expect(fromJson.reviewedAt, now);
      });
    },
  );

  group('PrepDateFormatter Timezone & Week Normalization', () {
    test('toCairoTime converts UTC to Cairo (+2 hours)', () {
      final utc = DateTime.utc(2026, 11, 11, 18, 30); // 6:30 PM UTC
      final cairo = PrepDateFormatter.toCairoTime(utc);
      expect(cairo.hour, 20); // 8:30 PM Cairo
      expect(cairo.minute, 30);
      expect(cairo.day, 11);
    });

    test('normalizeToMondayUtc deduplicates local and UTC dates', () {
      final utcNow = DateTime.utc(2026, 11, 11, 14, 0); // Wednesday UTC
      final localDate = DateTime.parse(
        '2026-11-09',
      ); // Monday Local from SQL DATE

      final monday1 = PrepDateFormatter.normalizeToMondayUtc(utcNow);
      final monday2 = PrepDateFormatter.normalizeToMondayUtc(localDate);

      expect(monday1, monday2);
      expect(monday1.isUtc, isTrue);
      expect(monday2.isUtc, isTrue);

      final set = {monday1, monday2};
      expect(set.length, 1, reason: 'Duplicate weeks must be eliminated');
    });
  });
}
