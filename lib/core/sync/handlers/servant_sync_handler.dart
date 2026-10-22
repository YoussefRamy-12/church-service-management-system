import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_conflict_exception.dart';
import '../sync_operation.dart';

/// Sync handler for 'servant' entities.
class ServantSyncHandler implements EntitySyncHandler {
  const ServantSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'servant';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation.operationType == 'delete') {
      await client
          .from('servant_profiles')
          .delete()
          .eq('id', payload['id'] as String);
      return;
    }

    if (operation.operationType == 'update') {
      final rows = await client
          .from('servant_profiles')
          .update({
            'name': payload['name'],
            'phone': payload['phone'],
            'birth_date': payload['birth_date'],
            'work_study': payload['work_study'],
            'role': payload['role'],
            'stage_id': payload['stage_id'],
            'class_id': payload['class_id'],
            'account_status': payload['account_status'],
          })
          .eq('id', payload['id'] as String)
          .select('id');
      if (rows.isEmpty) {
        throw const SyncConflictException(
          'Servant update was rejected or is no longer accessible.',
        );
      }
      return;
    }

    throw UnsupportedError(
      'Unsupported servant operation: ${operation.operationType}',
    );
  }
}
