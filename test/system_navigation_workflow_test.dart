import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:church_service_management_system/app/app_shell.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';

class _NoopTransport implements SyncTransport {
  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {}
}

void main() {
  late AppDatabase db;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase.forTesting();
    engine = SyncEngine(
      queue: SyncQueueRepository(db),
      transport: _NoopTransport(),
      connectivityChecker: () async => [ConnectivityResult.wifi],
    );
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  const profile = ServantProfile(
    id: 'servant-1',
    authUserId: 'auth-1',
    serviceId: 'service-1',
    name: 'Peter',
    role: 'overall_leader',
    accountStatus: 'active',
  );

  GoRouter buildRouter() => GoRouter(
        initialLocation: '/service/service-1/dashboard',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const Text('LOGIN')),
          ShellRoute(
            builder: (context, state, child) => AppShell(
              serviceId: 'service-1',
              child: child,
            ),
            routes: [
              for (final segment in [
                'dashboard',
                'students',
                'attendance',
                'follow-up',
                'reports',
                'servants',
                'export',
                'settings',
              ])
                GoRoute(
                  path: '/service/service-1/$segment',
                  builder: (_, _) => Scaffold(
                    body: Center(child: Text('SCREEN:$segment')),
                  ),
                ),
            ],
          ),
        ],
      );

  Widget buildSubject(GoRouter router) => ProviderScope(
        overrides: [
          currentServantProfileProvider.overrideWith((ref) async => profile),
          syncEngineProvider.overrideWithValue(engine),
          syncQueueRepositoryProvider.overrideWithValue(
            SyncQueueRepository(db),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('ar'),
          routerConfig: router,
        ),
      );

  testWidgets(
    'desktop shell navigates through every management workflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final router = buildRouter();

      await tester.pumpWidget(buildSubject(router));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Peter'), findsOneWidget);
      expect(find.byKey(const Key('nav_dashboard')), findsOneWidget);

      const workflows = <String, String>{
        'nav_students': 'SCREEN:students',
        'nav_attendance': 'SCREEN:attendance',
        'nav_follow-up': 'SCREEN:follow-up',
        'nav_reports': 'SCREEN:reports',
        'nav_servants': 'SCREEN:servants',
        'nav_export': 'SCREEN:export',
        'nav_settings': 'SCREEN:settings',
        'nav_dashboard': 'SCREEN:dashboard',
      };

      for (final entry in workflows.entries) {
        await tester.tap(find.byKey(Key(entry.key)));
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
      }

      await tester.tap(find.byKey(const Key('nav_logout')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/login');
      expect(find.text('LOGIN'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      router.dispose();
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'mobile shell opens navigation and reaches attendance workflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final router = buildRouter();

      await tester.pumpWidget(buildSubject(router));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav_menu')), findsOneWidget);
      expect(find.byKey(const Key('nav_status')), findsNothing);

      await tester.tap(find.byKey(const Key('nav_menu')));
      await tester.pumpAndSettle();

      expect(find.text('التنقل'), findsOneWidget);
      expect(find.text('الحضور'), findsOneWidget);

      await tester.tap(find.text('الحضور'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/service/service-1/attendance');
      expect(find.text('SCREEN:attendance'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      router.dispose();
      await tester.pump();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
