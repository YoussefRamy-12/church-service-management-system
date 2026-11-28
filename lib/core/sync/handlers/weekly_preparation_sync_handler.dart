import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';

/// Sync handler for 'weekly_preparation' offline submissions.
class WeeklyPreparationSyncHandler implements EntitySyncHandler {
  const WeeklyPreparationSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'weekly_preparation';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    final lessonId = payload['weekly_lesson_id'] as String;
    final servantProfileId = payload['servant_profile_id'] as String;
    final status = payload['status'] as String? ?? 'submitted';
    final submittedAt = payload['submitted_at'] as String?;
    final updatedAt =
        payload['updated_at'] as String? ??
        DateTime.now().toUtc().toIso8601String();

    await client.from('weekly_lesson_preparations').upsert({
      'weekly_lesson_id': lessonId,
      'servant_profile_id': servantProfileId,
      'status': status,
      'prepared': status == 'approved',
      'submitted_at': submittedAt,
      'updated_at': updatedAt,
    }, onConflict: 'weekly_lesson_id,servant_profile_id');
  }
}
