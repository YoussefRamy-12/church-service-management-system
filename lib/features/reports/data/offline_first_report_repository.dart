import '../domain/service_report.dart';
import 'local_report_repository.dart';
import 'supabase_report_repository.dart';

class OfflineFirstReportRepository {
  OfflineFirstReportRepository({
    required this.local,
    required this.remote,
  });

  final LocalReportRepository local;
  final SupabaseReportRepository remote;

  Future<ServiceReport> fetch({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    Set<String>? classIds,
  }) async {
    try {
      return await remote.fetch(
        serviceId: serviceId,
        start: start,
        end: end,
        classIds: classIds,
      );
    } catch (_) {
      return local.fetch(
        serviceId: serviceId,
        start: start,
        end: end,
        classIds: classIds,
      );
    }
  }
}
