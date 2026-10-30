import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:church_service_management_system/core/config/app_config.dart';
import 'package:church_service_management_system/core/config/config_provider.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/database/database_provider.dart';
import 'package:church_service_management_system/core/network/network_error_formatter.dart';
import 'package:church_service_management_system/core/network/supabase_client_provider.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_engine_provider.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/attendance/data/meeting_repository.dart';
import 'package:church_service_management_system/features/attendance/data/offline_first_attendance_repository.dart';
import 'package:church_service_management_system/features/attendance/data/online_attendance_repository.dart';
import 'package:church_service_management_system/features/attendance/data/online_meeting_repository.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_providers.dart';
import 'package:church_service_management_system/features/attendance/presentation/meeting_providers.dart';
import 'package:church_service_management_system/features/follow_up/data/offline_first_follow_up_repository.dart';
import 'package:church_service_management_system/features/follow_up/data/online_follow_up_repository.dart';
import 'package:church_service_management_system/features/follow_up/presentation/follow_up_providers.dart';
import 'package:church_service_management_system/features/reports/data/offline_first_report_repository.dart';
import 'package:church_service_management_system/features/reports/data/online_report_repository.dart';
import 'package:church_service_management_system/features/reports/presentation/report_providers.dart';
import 'package:church_service_management_system/features/servants/data/offline_first_servant_repository.dart';
import 'package:church_service_management_system/features/servants/data/online_servant_repository.dart';
import 'package:church_service_management_system/features/servants/presentation/servant_providers.dart';
import 'package:church_service_management_system/features/service/data/offline_first_service_repository.dart';
import 'package:church_service_management_system/features/service/data/online_service_repository.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:church_service_management_system/features/students/data/offline_first_student_registration.dart';
import 'package:church_service_management_system/features/students/data/offline_first_student_repository.dart';
import 'package:church_service_management_system/features/students/data/online_student_registration.dart';
import 'package:church_service_management_system/features/students/data/online_student_repository.dart';
import 'package:church_service_management_system/features/students/presentation/student_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Flag and Provider Defaults', () {
    test('AppConfig.offlineSyncEnabled defaults to false (online-only mode)', () {
      expect(AppConfig.offlineSyncEnabled, isFalse);
    });

    test('offlineSyncEnabledProvider defaults to AppConfig.offlineSyncEnabled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(offlineSyncEnabledProvider), isFalse);
    });
  });

  group('Repository Layer Switching', () {
    late AppDatabase db;
    late SupabaseClient supabase;

    setUp(() {
      db = AppDatabase.forTesting();
      supabase = SupabaseClient('https://test.supabase.co', 'test-anon-key');
    });

    tearDown(() async {
      await db.close();
    });

    test('When offlineSyncEnabled is false (default), providers resolve to Online repositories', () {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          supabaseClientProvider.overrideWithValue(supabase),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(offlineSyncEnabledProvider), isFalse);
      expect(container.read(studentRepositoryProvider), isA<OnlineStudentRepository>());
      expect(container.read(studentRegistrationProvider), isA<OnlineStudentRegistration>());
      expect(container.read(attendanceRepositoryProvider), isA<OnlineAttendanceRepository>());
      expect(container.read(meetingRepositoryProvider), isA<OnlineMeetingRepository>());
      expect(container.read(followUpRepositoryProvider), isA<OnlineFollowUpRepository>());
      expect(container.read(servantRepositoryProvider), isA<OnlineServantRepository>());
      expect(container.read(serviceRepositoryProvider), isA<OnlineServiceRepository>());
      expect(container.read(reportRepositoryProvider), isA<OnlineReportRepository>());
      expect(container.read(syncQueueRepositoryProvider).isEnabled, isFalse);
      expect(container.read(syncEngineProvider).isEnabled, isFalse);
    });

    test('When offlineSyncEnabled is true, providers seamlessly switch to Offline-First repositories', () {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          supabaseClientProvider.overrideWithValue(supabase),
          offlineSyncEnabledProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(offlineSyncEnabledProvider), isTrue);
      expect(container.read(studentRepositoryProvider), isA<OfflineFirstStudentRepository>());
      expect(container.read(studentRegistrationProvider), isA<OfflineFirstStudentRegistration>());
      expect(container.read(attendanceRepositoryProvider), isA<OnlineAttendanceRepository>());
      expect(container.read(meetingRepositoryProvider), isA<OnlineMeetingRepository>());
      expect(container.read(followUpRepositoryProvider), isA<OnlineFollowUpRepository>());
      expect(container.read(servantRepositoryProvider), isA<OnlineServantRepository>());
      expect(container.read(serviceRepositoryProvider), isA<OfflineFirstServiceRepository>());
      expect(container.read(reportRepositoryProvider), isA<OfflineFirstReportRepository>());
      expect(container.read(syncQueueRepositoryProvider).isEnabled, isTrue);
      expect(container.read(syncEngineProvider).isEnabled, isTrue);
    });
  });

  group('SyncQueueRepository Safety when Offline Sync is Disabled', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting();
    });

    tearDown(() async {
      await db.close();
    });

    test('enqueue throws StateError when disabled', () async {
      final disabledQueue = SyncQueueRepository(db, enabled: false);

      expect(
        () => disabledQueue.enqueue(
          const SyncOperation(
            operationId: 'op-1',
            entityType: 'student',
            operationType: 'insert',
            payloadJson: '{"id":"s-1"}',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('pending returns empty list without querying or mutating SQLite rows', () async {
      // First populate an item using an enabled queue (simulating frozen pre-existing items)
      final enabledQueue = SyncQueueRepository(db, enabled: true);
      await enabledQueue.enqueue(
        const SyncOperation(
          operationId: 'frozen-op-1',
          entityType: 'attendance',
          operationType: 'check_in',
          payloadJson: '{"student_id":"s-1"}',
        ),
      );

      // Now create a disabled queue
      final disabledQueue = SyncQueueRepository(db, enabled: false);
      final pendingWhenDisabled = await disabledQueue.pending();

      // Disabled queue must return empty and must not expose or delete items
      expect(pendingWhenDisabled, isEmpty);

      // Verify the row is still intact in SQLite by querying via enabled queue
      final pendingWhenRestored = await enabledQueue.pending();
      expect(pendingWhenRestored, hasLength(1));
      expect(pendingWhenRestored.first.operationId, 'frozen-op-1');
    });

    test('retryConflict does nothing when disabled', () async {
      final disabledQueue = SyncQueueRepository(db, enabled: false);
      // Calling retryConflict must not throw and must not do anything
      await disabledQueue.retryConflict('op-1');
      await disabledQueue.retryAllConflicts();
      await disabledQueue.retryMeetingConflicts();
    });
  });

  group('SyncEngine Safety when Offline Sync is Disabled', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting();
    });

    tearDown(() async {
      await db.close();
    });

    test('syncNow returns immediately when disabled without error', () async {
      final disabledQueue = SyncQueueRepository(db, enabled: false);
      final engine = SyncEngine(
        queue: disabledQueue,
        transport: _NoopTransport(),
        enabled: false,
      );

      // Should complete without attempting sync or throwing
      await engine.syncNow();
      expect(engine.enabled, isFalse);
    });
  });

  group('NetworkErrorFormatter', () {
    test('formats SocketException and network loss to Arabic message', () {
      const socketEx = SocketException('Failed host lookup: test.supabase.co');
      final formatted = NetworkErrorFormatter.format(socketEx);
      expect(formatted, contains('لا يوجد اتصال بالإنترنت'));
    });

    test('formats PostgreSQL permission error (42501) cleanly', () {
      const error = PostgrestException(
        message: 'new row violates row-level security policy for table students',
        code: '42501',
      );
      final formatted = NetworkErrorFormatter.format(error);
      expect(formatted, contains('ليس لديك الصلاحية'));
    });

    test('formats unique constraint error (23505) cleanly', () {
      const error = PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );
      final formatted = NetworkErrorFormatter.format(error);
      expect(formatted, contains('مسجلة بالفعل في النظام'));
    });

    test('formats foreign key constraint error (23503) cleanly', () {
      const error = PostgrestException(
        message: 'violates foreign key constraint',
        code: '23503',
      );
      final formatted = NetworkErrorFormatter.format(error);
      expect(formatted, contains('عدم تطابق البيانات المرتبطة'));
    });

    test('formats server 5xx error cleanly without revealing sensitive data', () {
      const error = PostgrestException(
        message: 'Internal Server Error at host: https://test.supabase.co',
        code: '500',
      );
      final formatted = NetworkErrorFormatter.format(error);
      expect(formatted, contains('الخادم غير متاح حاليًا'));
      expect(formatted, isNot(contains('test.supabase.co')));
    });
  });
}

class _NoopTransport implements SyncTransport {
  @override
  Future<void> apply(SyncOperation operation, Map<String, dynamic> payload) async {}
}
