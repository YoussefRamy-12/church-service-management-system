import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/local_follow_up_repository.dart';
import '../data/offline_first_follow_up_repository.dart';
import '../data/online_follow_up_repository.dart';
import '../domain/repositories/follow_up_repository.dart';

final localFollowUpRepositoryProvider = Provider<LocalFollowUpRepository>((
  ref,
) {
  return LocalFollowUpRepository(ref.watch(appDatabaseProvider));
});

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return OnlineFollowUpRepository(ref.watch(supabaseClientProvider));
  }
  return OfflineFirstFollowUpRepository(
    local: ref.watch(localFollowUpRepositoryProvider),
    queue: ref.watch(syncQueueRepositoryProvider),
  );
});
