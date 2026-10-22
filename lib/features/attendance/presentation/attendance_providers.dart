import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/local_attendance_repository.dart';
import '../data/offline_first_attendance_repository.dart';
import '../data/online_attendance_repository.dart';
import '../domain/repositories/attendance_repository.dart';

final localAttendanceRepositoryProvider = Provider<LocalAttendanceRepository>(
  (ref) => LocalAttendanceRepository(ref.watch(appDatabaseProvider)),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return OnlineAttendanceRepository(ref.watch(supabaseClientProvider));
  }
  return OfflineFirstAttendanceRepository(
    local: ref.watch(localAttendanceRepositoryProvider),
    queue: ref.watch(syncQueueRepositoryProvider),
    client: ref.watch(supabaseClientProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});
