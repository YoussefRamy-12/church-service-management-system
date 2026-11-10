import '../domain/report_repository.dart';
import '../domain/service_report.dart';
import 'local_report_repository.dart';
import 'supabase_report_repository.dart';

class OfflineFirstReportRepository implements ReportRepository {
  OfflineFirstReportRepository({required this.local, required this.remote});

  final LocalReportRepository local;
  final SupabaseReportRepository remote;

  @override
  Future<ServiceReport> fetch({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    Set<String>? classIds,
    String? stageId,
    String? studentId,
    bool compareWithPrevious = true,
  }) async {
    try {
      return await remote.fetch(
        serviceId: serviceId,
        start: start,
        end: end,
        classIds: classIds,
        stageId: stageId,
        studentId: studentId,
        compareWithPrevious: compareWithPrevious,
      );
    } catch (_) {
      return local.fetch(
        serviceId: serviceId,
        start: start,
        end: end,
        classIds: classIds,
        stageId: stageId,
        studentId: studentId,
        compareWithPrevious: compareWithPrevious,
      );
    }
  }
}
