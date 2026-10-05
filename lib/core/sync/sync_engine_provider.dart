import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import '../network/supabase_client_provider.dart';
import 'sync_engine.dart';
import 'sync_queue_repository.dart';

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) =>
    SyncQueueRepository(ref.watch(appDatabaseProvider)));

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    queue: ref.watch(syncQueueRepositoryProvider),
    client: ref.watch(supabaseClientProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});
