import 'package:supabase_flutter/supabase_flutter.dart';

import '../entity_sync_handler.dart';
import '../sync_operation.dart';

/// Sync handler for 'reporting_period' entities.
class ReportingPeriodSyncHandler implements EntitySyncHandler {
  const ReportingPeriodSyncHandler(this.client);

  final SupabaseClient client;

  @override
  String get entityType => 'reporting_period';

  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {
    if (operation.operationType == 'insert') {
      await client.from('reporting_periods').insert(payload);
      return;
    }

    throw UnsupportedError(
      'Unsupported reporting period operation: ${operation.operationType}',
    );
  }
}
