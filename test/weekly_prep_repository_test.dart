import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/sync/handlers/weekly_preparation_sync_handler.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/features/weekly_prep/data/supabase_weekly_preparation_repository.dart';
import 'package:church_service_management_system/features/weekly_prep/domain/preparation_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseWeeklyPreparationRepository Unit & Validation', () {
    late SupabaseClient mockClient;

    setUp(() {
      mockClient = SupabaseClient('https://example.supabase.co', 'test-key');
    });

    test(
      'reviewPreparation validates action is approved or needsRevision',
      () async {
        final repo = SupabaseWeeklyPreparationRepository(mockClient);

        // notSubmitted is not a valid review action
        expect(
          () => repo.reviewPreparation(
            lessonId: 'lesson-1',
            servantProfileId: 'servant-1',
            action: PreparationStatus.notSubmitted,
          ),
          throwsA(isA<ArgumentError>()),
        );

        // submitted is not a valid review action
        expect(
          () => repo.reviewPreparation(
            lessonId: 'lesson-1',
            servantProfileId: 'servant-1',
            action: PreparationStatus.submitted,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'reviewPreparation requires non-empty feedback when returning for revision',
      () async {
        final repo = SupabaseWeeklyPreparationRepository(mockClient);

        // null note
        expect(
          () => repo.reviewPreparation(
            lessonId: 'lesson-1',
            servantProfileId: 'servant-1',
            action: PreparationStatus.needsRevision,
            note: null,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('ملاحظات التعديل إلزامية'),
            ),
          ),
        );

        // empty or whitespace note
        expect(
          () => repo.reviewPreparation(
            lessonId: 'lesson-1',
            servantProfileId: 'servant-1',
            action: PreparationStatus.needsRevision,
            note: '   ',
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('ملاحظات التعديل إلزامية'),
            ),
          ),
        );
      },
    );
  });

  group('WeeklyPreparationSyncHandler for Offline-First Architecture', () {
    test('handler entityType matches weekly_preparation', () {
      final client = SupabaseClient('https://example.supabase.co', 'test-key');
      final handler = WeeklyPreparationSyncHandler(client);
      expect(handler.entityType, 'weekly_preparation');
    });

    test('offline sync payload serialization and deserialization', () {
      final now = DateTime.utc(2026, 11, 11, 15, 0);
      final payload = {
        'weekly_lesson_id': 'lesson-uuid-1',
        'servant_profile_id': 'servant-uuid-2',
        'status': 'submitted',
        'submitted_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final operation = SyncOperation(
        operationId: 'op-1234',
        entityType: 'weekly_preparation',
        operationType: 'submit',
        payloadJson: jsonEncode(payload),
      );

      expect(operation.operationId, 'op-1234');
      expect(operation.entityType, 'weekly_preparation');

      final decoded = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      expect(decoded['weekly_lesson_id'], 'lesson-uuid-1');
      expect(decoded['servant_profile_id'], 'servant-uuid-2');
      expect(decoded['status'], 'submitted');
    });
  });
}
