import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../data/local_meeting_repository.dart';
import '../data/meeting_repository.dart';

final localMeetingRepositoryProvider = Provider<LocalMeetingRepository>(
  (ref) => LocalMeetingRepository(ref.watch(appDatabaseProvider)),
);

final meetingRepositoryProvider = Provider<MeetingRepository>(
  (ref) => MeetingRepository(
    ref.watch(localMeetingRepositoryProvider),
    ref.watch(supabaseClientProvider),
    SyncQueueRepository(ref.watch(appDatabaseProvider)),
  ),
);
