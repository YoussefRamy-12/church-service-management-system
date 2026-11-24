import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:church_service_management_system/app/theme.dart';

import 'package:church_service_management_system/core/config/config_provider.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/core/sync/sync_center_page.dart';

class _NoopTransport implements SyncTransport {
  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {}
}

void main() {
  late AppDatabase database;
  late SyncQueueRepository queue;
  late SyncEngine engine;

  setUp(() {
    database = AppDatabase.forTesting();
    queue = SyncQueueRepository(database);
    engine = SyncEngine(
      queue: queue,
      transport: _NoopTransport(),
      connectivityChecker: () async => [ConnectivityResult.wifi],
    );
  });

  tearDown(() async {
    engine.dispose();
    await database.close();
  });

  Widget buildSubject() => ProviderScope(
        overrides: [
          syncQueueRepositoryProvider.overrideWithValue(queue),
          syncEngineProvider.overrideWithValue(engine),
          offlineSyncEnabledProvider.overrideWithValue(true),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const SyncCenterPage()),
      );

  testWidgets('sync center matches the empty-state golden', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSubject());
    await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('كل شيء متزامن'), findsOneWidget);
    await expectLater(
      find.byType(SyncCenterPage),
      matchesGoldenFile('goldens/sync_center_empty.png'),
    );
  }, tags: ['golden']);

  testWidgets('sync center shows the synchronized empty state', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('كل شيء متزامن'), findsOneWidget);
    expect(find.text('لا توجد تغييرات معلقة أو تعارضات. بيانات هذا الجهاز متزامنة.'), findsOneWidget);
  });

  testWidgets('sync center summarizes conflicts and links to review', (tester) async {
    const operation = SyncOperation(
      operationId: 'conflict-1',
      entityType: 'student',
      operationType: 'update',
      payloadJson: '{"id":"student-1"}',
    );
    await queue.enqueue(operation);
    await queue.markConflict(operation.operationId);

    await tester.pumpWidget(buildSubject());
    await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('تعارضات تحتاج مراجعة (1)'), findsOneWidget);
    expect(find.text('مراجعة التعارضات (1)'), findsOneWidget);
  });
}
