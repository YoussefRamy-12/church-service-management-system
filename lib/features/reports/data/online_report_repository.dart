import '../domain/report_repository.dart';
import '../domain/service_report.dart';
import 'supabase_report_repository.dart';

/// Online-only implementation of [ReportRepository].
///
/// Fetches report analytics directly from Supabase via [SupabaseReportRepository].
/// Does not fall back to local Drift/SQLite cache on errors.
class OnlineReportRepository implements ReportRepository {
  const OnlineReportRepository(this._remote);

  final SupabaseReportRepository _remote;

  @override
  Future<ServiceReport> fetch({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    Set<String>? classIds,
    String? stageId,
    String? studentId,
    bool compareWithPrevious = true,
  }) {
    return _remote.fetch(
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
