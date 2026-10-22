import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/local_servant_repository.dart';
import '../data/offline_first_servant_repository.dart';
import '../data/online_servant_repository.dart';
import '../data/supabase_servant_repository.dart';
import '../domain/repositories/servant_repository.dart';

final localServantRepositoryProvider = Provider<LocalServantRepository>(
  (ref) => LocalServantRepository(ref.watch(appDatabaseProvider)),
);

final remoteServantRepositoryProvider = Provider<SupabaseServantRepository>(
  (ref) => SupabaseServantRepository(ref.watch(supabaseClientProvider)),
);

final servantRepositoryProvider = Provider<ServantRepository>(
  (ref) {
    final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
    if (!offlineEnabled) {
      return OnlineServantRepository(ref.watch(remoteServantRepositoryProvider));
    }
    return OfflineFirstServantRepository(
      local: ref.watch(localServantRepositoryProvider),
      remote: ref.watch(remoteServantRepositoryProvider),
      queue: ref.watch(syncQueueRepositoryProvider),
    );
  },
);
