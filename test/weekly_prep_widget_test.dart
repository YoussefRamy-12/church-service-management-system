import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/preparation_review.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/preparation_status.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/repositories/weekly_preparation_repository.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/weekly_lesson.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/weekly_preparation.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/leadership/widgets/preparation_metrics_row.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/servant/servant_prep_view.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/servant/widgets/preparation_history_sheet.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/servant/widgets/preparation_status_badge.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/servant/widgets/review_feedback_card.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/leadership/leadership_prep_dashboard.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/leadership/widgets/preparation_filter_bar.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/weekly_prep_view_switcher.dart';
import 'package:church_service_management_system/features/weekly_prep/presentation/weekly_prep_providers.dart';
import 'package:church_service_management_system/app/design/app_colors.dart';
import 'package:church_service_management_system/app/design/app_theme.dart';

/// Minimal in-memory fake that avoids opening a real Drift database.
/// Used to prevent the test runner from hanging in tearDownAll due to
/// undisposed Drift stream subscriptions.
class _FakeWeeklyPreparationRepository implements WeeklyPreparationRepository {
  final WeeklyPreparation Function(String lessonId, String servantProfileId)
  _getPrep;

  _FakeWeeklyPreparationRepository(this._getPrep);

  @override
  Future<WeeklyPreparation> getPreparation({
    required String lessonId,
    required String servantProfileId,
  }) async => _getPrep(lessonId, servantProfileId);

  @override
  Future<WeeklyPreparation> submitPreparation({
    required String lessonId,
    required String servantProfileId,
  }) => throw UnimplementedError();

  @override
  Future<WeeklyPreparation> resubmitPreparation({
    required String lessonId,
    required String servantProfileId,
  }) => throw UnimplementedError();

  @override
  Future<void> reviewPreparation({
    required String lessonId,
    required String servantProfileId,
    required PreparationStatus action,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<List<PreparationReview>> getReviewHistory({
    required String lessonId,
    required String servantProfileId,
  }) async => const [];

  @override
  Future<List<WeeklyPreparation>> listPreparationsForDashboard({
    required String serviceId,
    String? stageId,
    String? classId,
    DateTime? weekStart,
    PreparationStatus? statusFilter,
  }) async => const [];

  @override
  Future<Map<PreparationStatus, int>> getStatusCounts({
    required String serviceId,
    String? stageId,
    DateTime? weekStart,
  }) async => const {};

  @override
  Stream<void> watchChanges({required String serviceId}) =>
      const Stream.empty();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar', null);
  });
  const testServant = ServantProfile(
    id: 'servant-1',
    authUserId: 'auth-1',
    serviceId: 'service-1',
    name: 'أبانوب جرجس',
    role: 'class_servant',
    stageId: 'stage-5',
    classId: 'class-5a',
    accountStatus: 'active',
  );

  final testMonday = DateTime.utc(2026, 11, 9);
  final testLesson = WeeklyLesson(
    id: 'lesson-1',
    serviceId: 'service-1',
    stageId: 'stage-5',
    weekStart: testMonday,
    storagePath: 'service-1/stage-5/2026-11-09/lesson.pdf',
    fileName: 'درس داود وجليات.pdf',
    updatedAt: testMonday,
  );

  group('Servant UI Widget Tests', () {
    testWidgets('status badge renders correct text and colors for all states', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PreparationStatusBadge(status: PreparationStatus.notSubmitted),
                PreparationStatusBadge(status: PreparationStatus.submitted),
                PreparationStatusBadge(status: PreparationStatus.approved),
                PreparationStatusBadge(status: PreparationStatus.needsRevision),
                PreparationStatusBadge(
                  status: PreparationStatus.submitted,
                  isPendingSync: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('لم يتم الإرسال'), findsOneWidget);
      expect(find.text('بانتظار المراجعة'), findsOneWidget);
      expect(find.text('تم الاعتماد'), findsOneWidget);
      expect(find.text('يحتاج إلى تعديل'), findsOneWidget);
      expect(find.text('بانتظار المراجعة (بانتظار المزامنة)'), findsOneWidget);
      final cases = <(String, Color)>[
        ('لم يتم الإرسال', AppColors.light.notMarked.background),
        ('بانتظار المراجعة', AppColors.light.warning.background),
        ('تم الاعتماد', AppColors.light.present.background),
        ('يحتاج إلى تعديل', AppColors.light.absent.background),
      ];
      for (final item in cases) {
        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.text(item.$1),
                matching: find.byType(Container),
              )
              .first,
        );
        expect((container.decoration! as BoxDecoration).color, item.$2);
      }
    });

    testWidgets('view switch appears only for leadership roles', (
      tester,
    ) async {
      Future<void> showFor(ServantProfile profile) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyPrepViewSwitcher(
              profile: profile,
              isSuperAdmin: false,
              isServantView: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await showFor(testServant);
      expect(find.byType(SegmentedButton<bool>), findsNothing);
      await showFor(testServant.copyWith(role: 'stage_leader'));
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);
      expect(find.text('تحضيري'), findsOneWidget);
      expect(find.text('متابعة الخدام'), findsOneWidget);
    });

    testWidgets(
      'ReviewFeedbackCard displays leader note prominently when needsRevision',
      (tester) async {
        final prep = WeeklyPreparation(
          weeklyLessonId: 'lesson-1',
          servantProfileId: 'servant-1',
          status: PreparationStatus.needsRevision,
          reviewedBy: 'leader-1',
          reviewerName: 'أ. مينا مرقص',
          reviewNote: 'يرجى مراجعة الوسيلة الإيضاحية والهدف الروحي.',
          reviewedAt: DateTime.utc(2026, 11, 10, 14, 0),
          updatedAt: DateTime.utc(2026, 11, 10, 14, 0),
        );

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            home: Scaffold(body: ReviewFeedbackCard(preparation: prep)),
          ),
        );

        expect(
          find.text('ملاحظات القائد المراجع — مطلوب تعديل'),
          findsOneWidget,
        );
        expect(
          find.text('يرجى مراجعة الوسيلة الإيضاحية والهدف الروحي.'),
          findsOneWidget,
        );
        expect(find.text('المراجع: أ. مينا مرقص'), findsOneWidget);
      },
    );

    testWidgets(
      'PreparationHistorySheet displays multiple reviews chronologically',
      (tester) async {
        final reviews = [
          PreparationReview(
            id: 'r-2',
            weeklyLessonId: 'lesson-1',
            servantProfileId: 'servant-1',
            reviewerId: 'leader-1',
            reviewerName: 'أ. بيشوي',
            action: PreparationStatus.approved,
            note: 'ممتاز جداً تم التعديل بشكل رائع',
            reviewedAt: DateTime.utc(2026, 11, 11, 16, 0),
          ),
          PreparationReview(
            id: 'r-1',
            weeklyLessonId: 'lesson-1',
            servantProfileId: 'servant-1',
            reviewerId: 'leader-1',
            reviewerName: 'أ. بيشوي',
            action: PreparationStatus.needsRevision,
            note: 'مطلوب توضيح الآية والشاهد',
            reviewedAt: DateTime.utc(2026, 11, 10, 12, 0),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            home: Scaffold(
              body: PreparationHistorySheet(
                reviews: reviews,
                lessonFileName: 'درس التجربة على الجبل.pdf',
              ),
            ),
          ),
        );

        expect(find.text('سجل مراجعات التحضير'), findsOneWidget);
        expect(find.text('درس التجربة على الجبل.pdf'), findsOneWidget);
        expect(find.text('تم الاعتماد'), findsOneWidget);
        expect(find.text('طلب تعديل'), findsOneWidget);
        expect(find.text('ممتاز جداً تم التعديل بشكل رائع'), findsOneWidget);
        expect(find.text('مطلوب توضيح الآية والشاهد'), findsOneWidget);
      },
    );

    testWidgets('ServantPrepView shows submit button when not submitted', (
      tester,
    ) async {
      final prep = WeeklyPreparation(
        weeklyLessonId: testLesson.id,
        servantProfileId: testServant.id,
        status: PreparationStatus.notSubmitted,
        updatedAt: testMonday,
      );

      final fakeRepo = _FakeWeeklyPreparationRepository(
        (lessonId, servantProfileId) => prep,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyPreparationRepositoryProvider.overrideWithValue(fakeRepo),
            servantPreparationProvider((
              lessonId: testLesson.id,
              servantProfileId: testServant.id,
            )).overrideWith((ref) => Future.value(prep)),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            home: ServantPrepView(
              serviceId: 'service-1',
              profile: testServant,
              lessons: [testLesson],
              stages: const [
                Stage(
                  id: 'stage-5',
                  serviceId: 'service-1',
                  name: 'الصف الخامس الابتدائي',
                ),
              ],
              currentWeekMonday: testMonday,
              onRefresh: () async {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<bool>), findsNothing);
      expect(find.text('درس داود وجليات.pdf'), findsOneWidget);
      expect(find.text('إرسال التحضير'), findsOneWidget);
      expect(find.text('فتح الدرس (PDF)'), findsOneWidget);
      expect(find.text('تنزيل الملف'), findsOneWidget);
    });

    testWidgets(
      'ServantPrepView locks editing when submission is awaiting review',
      (tester) async {
        final prep = WeeklyPreparation(
          weeklyLessonId: testLesson.id,
          servantProfileId: testServant.id,
          status: PreparationStatus.submitted,
          submittedAt: DateTime.utc(2026, 11, 9, 12, 0),
          updatedAt: DateTime.utc(2026, 11, 9, 12, 0),
        );

        final fakeRepo = _FakeWeeklyPreparationRepository(
          (lessonId, servantProfileId) => prep,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              weeklyPreparationRepositoryProvider.overrideWithValue(fakeRepo),
              servantPreparationProvider((
                lessonId: testLesson.id,
                servantProfileId: testServant.id,
              )).overrideWith((ref) => Future.value(prep)),
            ],
            child: MaterialApp(
              locale: const Locale('ar'),
              home: ServantPrepView(
                serviceId: 'service-1',
                profile: testServant,
                lessons: [testLesson],
                stages: const [
                  Stage(
                    id: 'stage-5',
                    serviceId: 'service-1',
                    name: 'الصف الخامس الابتدائي',
                  ),
                ],
                currentWeekMonday: testMonday,
                onRefresh: () async {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('بانتظار المراجعة'), findsAtLeast(1));
        expect(
          find.text('تم تسليم التحضير وهو بانتظار مراجعة القائد.'),
          findsOneWidget,
        );
        // Submit button is NOT present when awaiting review
        expect(find.text('إرسال التحضير'), findsNothing);
      },
    );
  });

  group('Leadership Metrics Row Widget Test', () {
    testWidgets('PreparationMetricsRow displays counts accurately', (
      tester,
    ) async {
      const counts = {
        PreparationStatus.notSubmitted: 4,
        PreparationStatus.submitted: 2,
        PreparationStatus.approved: 8,
        PreparationStatus.needsRevision: 1,
      };

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          home: Scaffold(
            body: PreparationMetricsRow(counts: counts, totalServants: 15),
          ),
        ),
      );

      expect(find.text('إجمالي الخدام'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('بانتظار المراجعة'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('تم الاعتماد'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('يحتاج لتعديل'), findsNothing);
      expect(find.text('لم يتم الإرسال'), findsNothing);
    });
  });

  testWidgets('leadership status filters show the provided counts', (
    tester,
  ) async {
    PreparationStatus? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreparationFilterBar(
            stages: const [],
            selectedStage: null,
            onStageChanged: (_) {},
            selectedStatus: PreparationStatus.submitted,
            onStatusChanged: (value) => selected = value,
            weeks: [testMonday],
            selectedWeek: testMonday,
            onWeekChanged: (_) {},
            counts: const {
              PreparationStatus.submitted: 3,
              PreparationStatus.notSubmitted: 2,
              PreparationStatus.approved: 4,
              PreparationStatus.needsRevision: 1,
            },
          ),
        ),
      ),
    );
    expect(find.text('بانتظار المراجعة (3)'), findsOneWidget);
    expect(find.text('لم يسلم (2)'), findsOneWidget);
    expect(find.text('معتمد (4)'), findsOneWidget);
    expect(find.text('الكل (10)'), findsOneWidget);
    await tester.tap(find.text('معتمد (4)'));
    await tester.pump();
    expect(selected, PreparationStatus.approved);
  });

  testWidgets('both preparation views fit 360x640 at text scale 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prep = WeeklyPreparation(
      weeklyLessonId: testLesson.id,
      servantProfileId: testServant.id,
      status: PreparationStatus.notSubmitted,
      updatedAt: testMonday,
    );
    final fakeRepo = _FakeWeeklyPreparationRepository((_, _) => prep);
    Widget scaled(Widget child) => MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
      child: child,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyPreparationRepositoryProvider.overrideWithValue(fakeRepo),
          servantPreparationProvider((
            lessonId: testLesson.id,
            servantProfileId: testServant.id,
          )).overrideWith((ref) => Future.value(prep)),
        ],
        child: scaled(
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('ar'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: ServantPrepView(
              serviceId: 'service-1',
              profile: testServant,
              lessons: [testLesson],
              stages: const [
                Stage(
                  id: 'stage-5',
                  serviceId: 'service-1',
                  name: 'الصف الخامس الابتدائي',
                ),
              ],
              currentWeekMonday: testMonday,
              onRefresh: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyPreparationRepositoryProvider.overrideWithValue(fakeRepo),
          servantPreparationProvider((
            lessonId: testLesson.id,
            servantProfileId: testServant.id,
          )).overrideWith((ref) => Future.value(prep)),
        ],
        child: scaled(
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('ar'),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: LeadershipPrepDashboard(
              serviceId: 'service-1',
              currentLeader: testServant.copyWith(role: 'overall_leader'),
              stages: const [],
              weeks: [testMonday],
              lessons: const [],
              onRefresh: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
