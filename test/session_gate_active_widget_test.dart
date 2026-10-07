import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';

import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/domain/entities/session_identity.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/auth/presentation/session_gate.dart';

class _NoopTransport implements SyncTransport {
  @override
  Future<void> apply(SyncOperation operation, Map<String, dynamic> payload) async {}
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

  testWidgets('session gate redirects an active servant to the service dashboard',
      (tester) async {
    const profile = ServantProfile(
      id: 'servant-1',
      authUserId: 'auth-1',
      serviceId: 'service-1',
      name: 'Peter',
      role: 'class_leader',
      accountStatus: 'active',
      classId: 'class-1',
    );

    final router = GoRouter(
      initialLocation: '/session',
      routes: [
        GoRoute(
          path: '/session',
          builder: (context, state) => const SessionGate(),
        ),
        GoRoute(
          path: '/service/:serviceId/dashboard',
          builder: (context, state) => const Scaffold(
            body: Column(
              children: [
                Text('مرحبًا Peter'),
                Text('أمين الفصل'),
              ],
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionIdentityProvider.overrideWith(
            (ref) async => const ServantIdentity(profile),
          ),
          syncEngineProvider.overrideWithValue(engine),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/service/service-1/dashboard');
    expect(find.text('مرحبًا Peter'), findsOneWidget);
    expect(find.text('أمين الفصل'), findsOneWidget);

    router.dispose();
  });
}
