import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/config_provider.dart';
import '../database/database_provider.dart';
import '../network/connectivity_provider.dart';
import '../network/supabase_client_provider.dart';
import 'sync_engine.dart';
import 'sync_queue_repository.dart';
import 'sync_status.dart';

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>(
  (ref) => SyncQueueRepository(
    ref.watch(appDatabaseProvider),
    enabled: ref.watch(offlineSyncEnabledProvider),
  ),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    queue: ref.watch(syncQueueRepositoryProvider),
    client: ref.watch(supabaseClientProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    enabled: ref.watch(offlineSyncEnabledProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.onStatusChanged;
});
