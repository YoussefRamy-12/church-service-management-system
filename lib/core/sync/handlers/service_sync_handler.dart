import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_conflict_exception.dart';
import '../sync_operation.dart';

/// Sync handler for 'service' entities.
class ServiceSyncHandler implements EntitySyncHandler {
  const ServiceSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'service';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation.operationType == 'update') {
      final rows = await client
          .from('services')
          .update({
            'meeting_start_time': payload['meeting_start_time'],
            'meeting_frequency': payload['meeting_frequency'] ?? 'weekly',
            'meeting_weekday': payload['meeting_weekday'] ?? 5,
            'meeting_month_day': payload['meeting_month_day'] ?? 1,
          })
          .eq('id', payload['id'] as String)
          .select('id');
      if (rows.isEmpty) {
        throw const SyncConflictException(
          'Service settings update was rejected or is no longer accessible.',
        );
      }
      return;
    }

    throw UnsupportedError(
      'Unsupported service operation: ${operation.operationType}',
    );
  }
}
