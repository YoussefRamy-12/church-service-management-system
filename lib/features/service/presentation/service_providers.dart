import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../data/local_service_repository.dart';
import '../data/offline_first_service_repository.dart';
import '../data/supabase_service_repository.dart';

final localServiceRepositoryProvider = Provider<LocalServiceRepository>((ref) {
  return LocalServiceRepository(ref.watch(appDatabaseProvider));
});

final remoteServiceRepositoryProvider =
    Provider<SupabaseServiceRepository>((ref) {
  return SupabaseServiceRepository(ref.watch(supabaseClientProvider));
});

final serviceRepositoryProvider =
    Provider<OfflineFirstServiceRepository>((ref) {
  return OfflineFirstServiceRepository(
    local: ref.watch(localServiceRepositoryProvider),
    remote: ref.watch(remoteServiceRepositoryProvider),
  );
});
