import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/local_service_repository.dart';
import '../data/offline_first_service_repository.dart';
import '../data/online_service_repository.dart';
import '../data/supabase_service_repository.dart';
import '../domain/repositories/service_repository.dart';

final localServiceRepositoryProvider = Provider<LocalServiceRepository>((ref) {
  return LocalServiceRepository(ref.watch(appDatabaseProvider));
});

final remoteServiceRepositoryProvider = Provider<SupabaseServiceRepository>((
  ref,
) {
  return SupabaseServiceRepository(ref.watch(supabaseClientProvider));
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return OnlineServiceRepository(
      remote: ref.watch(remoteServiceRepositoryProvider),
      client: ref.watch(supabaseClientProvider),
    );
  }
  return OfflineFirstServiceRepository(
    local: ref.watch(localServiceRepositoryProvider),
    remote: ref.watch(remoteServiceRepositoryProvider),
    queue: ref.watch(syncQueueRepositoryProvider),
  );
});
