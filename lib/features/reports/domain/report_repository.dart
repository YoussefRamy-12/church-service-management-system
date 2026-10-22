import 'service_report.dart';

/// Domain contract for report fetching.
abstract interface class ReportRepository {
  Future<ServiceReport> fetch({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    Set<String>? classIds,
  });
}
