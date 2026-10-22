import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../data/local_report_repository.dart';
import '../data/offline_first_report_repository.dart';
import '../data/online_report_repository.dart';
import '../data/supabase_report_repository.dart';
import '../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
  if (!offlineEnabled) {
    return OnlineReportRepository(
      SupabaseReportRepository(ref.watch(supabaseClientProvider)),
    );
  }
  return OfflineFirstReportRepository(
    local: LocalReportRepository(ref.watch(appDatabaseProvider)),
    remote: SupabaseReportRepository(ref.watch(supabaseClientProvider)),
  );
});
