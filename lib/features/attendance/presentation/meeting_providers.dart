import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/local_meeting_repository.dart';
import '../data/meeting_repository.dart';
import '../data/online_meeting_repository.dart';
import '../domain/repositories/meeting_repository.dart';

final localMeetingRepositoryProvider = Provider<LocalMeetingRepository>(
  (ref) => LocalMeetingRepository(ref.watch(appDatabaseProvider)),
);

final meetingRepositoryProvider = Provider<MeetingRepository>((ref) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return OnlineMeetingRepository(ref.watch(supabaseClientProvider));
  }
  return OfflineFirstMeetingRepository(
    ref.watch(localMeetingRepositoryProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(syncQueueRepositoryProvider),
    ref.watch(connectivityServiceProvider),
  );
});
