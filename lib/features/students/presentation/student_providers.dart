import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/local_student_repository.dart';
import '../data/offline_first_student_registration.dart';
import '../data/offline_first_student_repository.dart';
import '../data/online_student_registration.dart';
import '../data/online_student_repository.dart';
import '../data/supabase_student_repository.dart';
import '../domain/repositories/student_repository.dart';
import '../services/excel_student_import_service.dart';
import '../services/student_qr_pdf_service.dart';

final localStudentRepositoryProvider = Provider<LocalStudentRepository>((ref) {
  return LocalStudentRepository(ref.watch(appDatabaseProvider));
});

final remoteStudentRepositoryProvider = Provider<SupabaseStudentRepository>((
  ref,
) {
  return SupabaseStudentRepository(ref.watch(supabaseClientProvider));
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return OnlineStudentRepository(ref.watch(supabaseClientProvider));
  }
  return OfflineFirstStudentRepository(
    local: ref.watch(localStudentRepositoryProvider),
    remote: ref.watch(remoteStudentRepositoryProvider),
    queue: ref.watch(syncQueueRepositoryProvider),
  );
});

final studentRegistrationProvider = Provider<StudentRegistration>((
  ref,
) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return OnlineStudentRegistration(ref.watch(supabaseClientProvider));
  }
  return OfflineFirstStudentRegistration(
    ref.watch(localStudentRepositoryProvider),
    ref.watch(syncQueueRepositoryProvider),
  );
});

final studentQrPdfServiceProvider = Provider<StudentQrPdfService>((ref) {
  return const StudentQrPdfService();
});

final excelStudentImportServiceProvider = Provider<ExcelStudentImportService>((
  ref,
) {
  return const ExcelStudentImportService();
});
