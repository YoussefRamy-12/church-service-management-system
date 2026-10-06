import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../data/local_student_repository.dart';
import '../data/offline_first_student_repository.dart';
import '../data/supabase_student_repository.dart';

final localStudentRepositoryProvider = Provider<LocalStudentRepository>((ref) {
  return LocalStudentRepository(ref.watch(appDatabaseProvider));
});

final remoteStudentRepositoryProvider =
    Provider<SupabaseStudentRepository>((ref) {
  return SupabaseStudentRepository(ref.watch(supabaseClientProvider));
});

final studentRepositoryProvider =
    Provider<OfflineFirstStudentRepository>((ref) {
  return OfflineFirstStudentRepository(
    local: ref.watch(localStudentRepositoryProvider),
    remote: ref.watch(remoteStudentRepositoryProvider),
    queue: SyncQueueRepository(ref.watch(appDatabaseProvider)),
  );
});
