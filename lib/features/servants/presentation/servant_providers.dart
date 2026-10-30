import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/online_servant_repository.dart';
import '../data/supabase_servant_repository.dart';
import '../domain/repositories/servant_repository.dart';

final remoteServantRepositoryProvider = Provider<SupabaseServantRepository>(
  (ref) => SupabaseServantRepository(ref.watch(supabaseClientProvider)),
);

/// Servant profiles are served directly from Supabase (online-only).
final servantRepositoryProvider = Provider<ServantRepository>(
  (ref) => OnlineServantRepository(ref.watch(remoteServantRepositoryProvider)),
);
