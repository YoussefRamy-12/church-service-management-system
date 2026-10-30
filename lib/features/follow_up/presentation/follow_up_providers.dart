import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/online_follow_up_repository.dart';
import '../domain/repositories/follow_up_repository.dart';

/// Follow-up records and assignment requests use live Supabase data only.
final followUpRepositoryProvider = Provider<FollowUpRepository>(
  (ref) => OnlineFollowUpRepository(ref.watch(supabaseClientProvider)),
);
