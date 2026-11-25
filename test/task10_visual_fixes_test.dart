import 'package:church_service_management_system/app/app_shell.dart';
import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/database/database_provider.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/utils/app_formatters.dart';
import 'package:church_service_management_system/features/attendance/presentation/qr_scan_page.dart';
import 'package:church_service_management_system/features/auth/domain/entities/session_identity.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_activity.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_case.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/follow_up_student_item.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_case_providers.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_hub_page.dart';
import 'package:church_service_management_system/features/reports/presentation/report_providers.dart';
import 'package:church_service_management_system/features/reports/presentation/reports_page.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'goldens/golden_test_helper.dart';

void main() {
  test('AppDateFormatter formats dates as dd/MM/yyyy', () {
    expect(AppDateFormatter.format(DateTime(2026, 11, 20)), '20/11/2026');
    expect(AppDateFormatter.formatString('2026-11-20'), '20/11/2026');
    expect(AppDateFormatter.formatString('20-11-2026'), '20/11/2026');
  });

  test('formatOpenCasesCount uses Arabic plural rules', () {
    expect(formatOpenCasesCount(1), 'حالة مفتوحة');
    expect(formatOpenCasesCount(2), 'حالتان');
    expect(formatOpenCasesCount(3), '3 حالات');
    expect(formatOpenCasesCount(10), '10 حالات');
  });

  testWidgets('QrScanPage shows Arabic permission copy and actions on error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: QrScanPage(
            students: [],
            presentStudentIds: {},
            initialCameraError:
                'يلزم السماح بالوصول إلى الكاميرا لمسح رمز الحضور.',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('يلزم السماح بالوصول إلى الكاميرا لمسح رمز الحضور.'),
      findsOneWidget,
    );
    expect(find.text('السماح بالكاميرا'), findsOneWidget);
    expect(find.text('إدخال يدوي'), findsOneWidget);
    expect(find.textContaining('Camera permission denied'), findsNothing);
  });

  testWidgets('QrScanPage hides approval status chip in attendance context', (
    tester,
  ) async {
    const student = Student(
      id: 's-1',
      serviceId: 'svc-1',
      name: 'مينا فايز',
      approvalStatus: 'approved',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: QrScanPage(
            students: [student],
            presentStudentIds: {},
            initialScannedStudent: student,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('مينا فايز'), findsOneWidget);
    expect(find.text('معتمد'), findsNothing);
    expect(find.text('بانتظار الاعتماد'), findsNothing);
  });

  testWidgets(
    'FollowUpHubPage FAB sits above mobile bottom navigation in AppShell',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final queue = GoldenFakeSyncQueueRepository(db);
      final engine = SyncEngine(
        queue: queue,
        transport: GoldenNoopTransport(),
        enabled: false,
      );
      addTearDown(engine.dispose);

      final router = GoRouter(
        initialLocation: '/service/$goldenServiceId/follow-up',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                AppShell(serviceId: goldenServiceId, child: child),
            routes: [
              GoRoute(
                path: '/service/$goldenServiceId/follow-up',
                builder: (_, _) =>
                    const FollowUpHubPage(serviceId: goldenServiceId),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            currentServantProfileProvider.overrideWith(
              (ref) async => goldenLeaderProfile,
            ),
            currentSessionIdentityProvider.overrideWith(
              (ref) async => const ServantIdentity(goldenLeaderProfile),
            ),
            syncQueueRepositoryProvider.overrideWithValue(queue),
            syncEngineProvider.overrideWithValue(engine),
            followUpStudentItemsProvider(
              goldenServiceId,
            ).overrideWith((ref) async => const <FollowUpStudentItem>[]),
            followUpCasesInScopeProvider(
              goldenServiceId,
            ).overrideWith((ref) => Stream.value(const <FollowUpCase>[])),
            followUpActivitiesInScopeProvider(
              goldenServiceId,
            ).overrideWith((ref) => Stream.value(const <FollowUpActivity>[])),
          ],
          child: MaterialApp.router(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fabRect = tester.getRect(find.byType(FloatingActionButton));
      final navRect = tester.getRect(find.byType(NavigationBar));
      expect(fabRect.bottom, lessThanOrEqualTo(navRect.top));
    },
  );

  testWidgets(
    'FollowUpHubPage renders at 390px with text scale 1.3 without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentServantProfileProvider.overrideWith(
              (ref) async => goldenLeaderProfile,
            ),
            currentSessionIdentityProvider.overrideWith(
              (ref) async => const ServantIdentity(goldenLeaderProfile),
            ),
            followUpStudentItemsProvider(
              goldenServiceId,
            ).overrideWith((ref) async => goldenFollowUpStudentItems),
            followUpCasesInScopeProvider(
              goldenServiceId,
            ).overrideWith((ref) => Stream.value(goldenFollowUpCases)),
            followUpActivitiesInScopeProvider(
              goldenServiceId,
            ).overrideWith((ref) => Stream.value(goldenFollowUpActivities)),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: FollowUpHubPage(serviceId: goldenServiceId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ReportsPage renders at 390px with text scale 1.3 without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serviceRepositoryProvider.overrideWithValue(
              GoldenFakeServiceRepository(),
            ),
            currentServantProfileProvider.overrideWith(
              (ref) async => goldenLeaderProfile,
            ),
            currentSessionIdentityProvider.overrideWith(
              (ref) async => const ServantIdentity(goldenLeaderProfile),
            ),
            reportUserScopeProvider(goldenServiceId).overrideWith(
              (ref) async => const ReportUserScope(
                role: 'overall_leader',
                isServiceWide: true,
                stageId: null,
                classId: null,
                accessibleClassIds: null,
                accessibleStageIds: null,
              ),
            ),
            reportsAnalyticsProvider(
              goldenServiceId,
            ).overrideWith((ref) async => goldenServiceReport),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: ReportsPage(serviceId: goldenServiceId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
