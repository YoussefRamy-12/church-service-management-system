import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../data/local_servant_repository.dart';
import '../data/offline_first_servant_repository.dart';
import '../data/supabase_servant_repository.dart';

final localServantRepositoryProvider = Provider<LocalServantRepository>(
  (ref) => LocalServantRepository(ref.watch(appDatabaseProvider)),
);

final remoteServantRepositoryProvider = Provider<SupabaseServantRepository>(
  (ref) => SupabaseServantRepository(ref.watch(supabaseClientProvider)),
);

final servantRepositoryProvider = Provider<OfflineFirstServantRepository>(
  (ref) => OfflineFirstServantRepository(
    local: ref.watch(localServantRepositoryProvider),
    remote: ref.watch(remoteServantRepositoryProvider),
    queue: SyncQueueRepository(ref.watch(appDatabaseProvider)),
  ),
);
