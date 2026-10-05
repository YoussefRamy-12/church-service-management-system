import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/local_attendance_repository.dart';
import '../data/offline_first_attendance_repository.dart';

final localAttendanceRepositoryProvider = Provider<LocalAttendanceRepository>(
  (ref) => LocalAttendanceRepository(ref.watch(appDatabaseProvider)),
);

final attendanceRepositoryProvider = Provider<OfflineFirstAttendanceRepository>(
  (ref) => OfflineFirstAttendanceRepository(
    local: ref.watch(localAttendanceRepositoryProvider),
    queue: ref.watch(syncQueueRepositoryProvider),
  ),
);
