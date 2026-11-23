import 'package:church_service_management_system/app/app_shell.dart';
import 'package:church_service_management_system/app/design/app_theme.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/domain/entities/session_identity.dart';
import 'package:church_service_management_system/features/auth/domain/entities/system_admin_profile.dart';
import 'package:church_service_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_case_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase database;
  late _FakeAuthRepository authRepository;

  setUp(() {
    database = AppDatabase.forTesting();
    authRepository = _FakeAuthRepository();
  });

  tearDown(() async {
    await database.close();
  });

  Future<GoRouter> pumpShell(
    WidgetTester tester, {
    required double width,
    required String location,
    String role = 'class_servant',
    bool systemAdmin = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);

    final profile = ServantProfile(
      id: 'servant-1',
      authUserId: 'user-1',
      serviceId: 'service-1',
      name: 'خادم الاختبار',
      role: role,
      accountStatus: 'active',
    );
    final SessionIdentity identity = systemAdmin
        ? const SuperAdminIdentity(
            SystemAdminProfile(
              id: 'admin-1',
              authUserId: 'user-1',
              status: 'active',
            ),
          )
        : ServantIdentity(profile);

    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/sync',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('sync route')),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('login route')),
          ),
        ),
        GoRoute(
          path: '/service/:serviceId',
          redirect: (context, state) => null,
          routes: [
            ShellRoute(
              builder: (context, state, child) => AppShell(
                serviceId: state.pathParameters['serviceId']!,
                child: Scaffold(body: child),
              ),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const Text('dashboard page'),
                ),
                GoRoute(
                  path: 'attendance',
                  builder: (context, state) => const Text('attendance page'),
                  routes: [
                    GoRoute(
                      path: 'session/:meetingId/:classId',
                      builder: (context, state) =>
                          const Text('attendance session'),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'students',
                  builder: (context, state) => const Text('students page'),
                ),
                GoRoute(
                  path: 'follow-up',
                  builder: (context, state) => const Text('follow-up page'),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const Text('settings page'),
                  routes: [
                    GoRoute(
                      path: 'structure',
                      builder: (context, state) =>
                          const Text('structure settings'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentServantProfileProvider.overrideWith((ref) async =>
              systemAdmin ? null : profile),
          currentSessionIdentityProvider.overrideWith((ref) async => identity),
          followUpStudentItemsProvider.overrideWith(
            (ref, serviceId) async => const [],
          ),
          syncQueueRepositoryProvider.overrideWithValue(
            SyncQueueRepository(database, enabled: false),
          ),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openMore(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('nav_tab_more')));
    await tester.pumpAndSettle();
  }

  group('responsive navigation layouts', () {
    testWidgets('390px uses bottom navigation', (tester) async {
      await pumpShell(
        tester,
        width: 390,
        location: '/service/service-1/dashboard',
      );

      expect(find.byKey(const Key('app_shell_bottom_navigation')), findsOneWidget);
      expect(find.byKey(const Key('app_shell_navigation_rail')), findsNothing);
      expect(find.byKey(const Key('app_shell_desktop_sidebar')), findsNothing);
    });

    testWidgets('800px uses a right-side NavigationRail', (tester) async {
      await pumpShell(
        tester,
        width: 800,
        location: '/service/service-1/dashboard',
      );

      expect(find.byKey(const Key('app_shell_navigation_rail')), findsOneWidget);
      expect(find.byKey(const Key('app_shell_bottom_navigation')), findsNothing);
      expect(find.byKey(const Key('app_shell_desktop_sidebar')), findsNothing);
      expect(
        tester.getRect(find.byKey(const Key('app_shell_navigation_rail'))).right,
        closeTo(800, 0.1),
      );
    });

    testWidgets('1280px keeps the 288px desktop sidebar', (tester) async {
      await pumpShell(
        tester,
        width: 1280,
        location: '/service/service-1/dashboard',
      );

      expect(find.byKey(const Key('app_shell_desktop_sidebar')), findsOneWidget);
      expect(find.byKey(const Key('app_shell_navigation_rail')), findsNothing);
      expect(find.byKey(const Key('app_shell_bottom_navigation')), findsNothing);
      final sidebar = tester.widget<Container>(
        find.byKey(const Key('app_shell_desktop_sidebar')),
      );
      expect(sidebar.constraints?.maxWidth, 288);
    });
  });

  group('nested route selection', () {
    testWidgets('attendance session keeps Attendance selected', (tester) async {
      await pumpShell(
        tester,
        width: 800,
        location: '/service/service-1/attendance/session/meeting-1/class-1',
      );

      final rail = tester.widget<NavigationRail>(
        find.byKey(const Key('app_shell_navigation_rail')),
      );
      expect(rail.selectedIndex, 1);
    });

    testWidgets('attendance session hides the mobile bottom bar', (tester) async {
      await pumpShell(
        tester,
        width: 390,
        location: '/service/service-1/attendance/session/meeting-1/class-1',
      );

      expect(find.byKey(const Key('app_shell_bottom_navigation')), findsNothing);
    });

    testWidgets('settings structure selects More', (tester) async {
      await pumpShell(
        tester,
        width: 800,
        location: '/service/service-1/settings/structure',
      );

      final rail = tester.widget<NavigationRail>(
        find.byKey(const Key('app_shell_navigation_rail')),
      );
      expect(rail.selectedIndex, 4);
    });
  });

  group('role-based More visibility', () {
    testWidgets('system admin sees management, settings and service switch',
        (tester) async {
      await pumpShell(
        tester,
        width: 390,
        location: '/service/service-1/dashboard',
        systemAdmin: true,
      );
      await openMore(tester);

      expect(find.byKey(const Key('nav_more_reports')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_servants')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_export')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_graduation')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_settings')), findsOneWidget);
      expect(find.byKey(const Key('nav_switch_service')), findsOneWidget);
    });

    testWidgets('overall leader sees management and service settings',
        (tester) async {
      await pumpShell(
        tester,
        width: 390,
        location: '/service/service-1/dashboard',
        role: 'overall_leader',
      );
      await openMore(tester);

      expect(find.byKey(const Key('nav_more_reports')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_servants')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_export')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_graduation')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_settings')), findsOneWidget);
      expect(find.byKey(const Key('nav_switch_service')), findsNothing);
    });

    testWidgets('class leader sees reports but not management settings',
        (tester) async {
      await pumpShell(
        tester,
        width: 390,
        location: '/service/service-1/dashboard',
        role: 'class_leader',
      );
      await openMore(tester);

      expect(find.byKey(const Key('nav_more_reports')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_servants')), findsNothing);
      expect(find.byKey(const Key('nav_more_export')), findsNothing);
      expect(find.byKey(const Key('nav_more_graduation')), findsNothing);
      expect(find.byKey(const Key('nav_more_settings')), findsNothing);
    });

    testWidgets('class servant sees only universally available More items',
        (tester) async {
      await pumpShell(
        tester,
        width: 390,
        location: '/service/service-1/dashboard',
        role: 'class_servant',
      );
      await openMore(tester);

      expect(find.byKey(const Key('nav_more_prep')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_spiritual-notebook')), findsOneWidget);
      expect(find.byKey(const Key('nav_more_reports')), findsNothing);
      expect(find.byKey(const Key('nav_more_servants')), findsNothing);
      expect(find.byKey(const Key('nav_more_settings')), findsNothing);
      expect(find.byKey(const Key('nav_more_my-settings')), findsOneWidget);
    });
  });

  testWidgets('top-bar SyncBadge opens the sync center', (tester) async {
    final router = await pumpShell(
      tester,
      width: 390,
      location: '/service/service-1/dashboard',
    );

    await tester.tap(find.text('تمت المزامنة'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/sync');
  });

  testWidgets('More sheet is grouped and Logout signs out', (tester) async {
    final router = await pumpShell(
      tester,
      width: 390,
      location: '/service/service-1/dashboard',
      systemAdmin: true,
    );
    await openMore(tester);

    expect(find.text('الخدمة'), findsOneWidget);
    expect(find.text('الإدارة'), findsOneWidget);
    expect(find.text('الحساب'), findsOneWidget);
    expect(find.byKey(const Key('nav_logout')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_logout')));
    await tester.pumpAndSettle();

    expect(authRepository.didSignOut, isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });
}

class _FakeAuthRepository implements AuthRepository {
  bool didSignOut = false;

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
