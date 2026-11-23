import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../data/local_report_repository.dart';
import '../data/offline_first_report_repository.dart';
import '../data/online_report_repository.dart';
import '../data/report_export_service.dart';
import '../data/supabase_report_repository.dart';
import '../domain/report_filter.dart';
import '../domain/report_repository.dart';
import '../domain/service_report.dart';

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

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return const ReportExportService();
});

/// Authorized scope of reports for current logged-in user.
class ReportUserScope {
  const ReportUserScope({
    required this.role,
    required this.isServiceWide,
    required this.stageId,
    required this.classId,
    required this.accessibleClassIds,
    required this.accessibleStageIds,
  });

  final String role;
  final bool isServiceWide;
  final String? stageId;
  final String? classId;
  final Set<String>? accessibleClassIds; // null means unrestricted across service
  final Set<String>? accessibleStageIds;
}

final reportUserScopeProvider =
    FutureProvider.family<ReportUserScope, String>((ref, serviceId) async {
  final profile = await ref.watch(currentServantProfileProvider.future);
  final isSuperAdmin = ref.watch(isSuperAdminProvider);

  if (isSuperAdmin ||
      profile?.role == 'overall_leader' ||
      profile?.role == 'overall_helper') {
    return const ReportUserScope(
      role: 'overall_leader',
      isServiceWide: true,
      stageId: null,
      classId: null,
      accessibleClassIds: null,
      accessibleStageIds: null,
    );
  }

  final serviceRepo = ref.read(serviceRepositoryProvider);
  final stages = await serviceRepo.getStages(serviceId);

  if (profile?.role == 'stage_leader') {
    final stId = profile?.stageId;
    if (stId != null) {
      final classes = await serviceRepo.getClasses(stId);
      return ReportUserScope(
        role: 'stage_leader',
        isServiceWide: false,
        stageId: stId,
        classId: null,
        accessibleClassIds: classes.map((c) => c.id).toSet(),
        accessibleStageIds: {stId},
      );
    }
  }

  if (profile?.role == 'class_leader' || profile?.role == 'class_servant') {
    final cId = profile?.classId;
    String? stId;
    if (cId != null) {
      for (final s in stages) {
        final classes = await serviceRepo.getClasses(s.id);
        if (classes.any((c) => c.id == cId)) {
          stId = s.id;
          break;
        }
      }
    }
    return ReportUserScope(
      role: profile?.role ?? 'class_servant',
      isServiceWide: false,
      stageId: stId,
      classId: cId,
      accessibleClassIds: cId != null ? {cId} : {},
      accessibleStageIds: stId != null ? {stId} : {},
    );
  }

  return const ReportUserScope(
    role: 'guest',
    isServiceWide: false,
    stageId: null,
    classId: null,
    accessibleClassIds: {},
    accessibleStageIds: {},
  );
});

/// State controller for active report filters.
class ReportFilterNotifier extends Notifier<ReportFilter> {
  @override
  ReportFilter build() {
    return _defaultFilter();
  }

  static ReportFilter _defaultFilter() {
    final now = DateTime.now();
    // Default to last 4 weeks or current month
    final start = DateTime(now.year, now.month, 1);
    return ReportFilter(
      start: start,
      end: now,
      preset: ReportPeriodPreset.currentMonth,
    );
  }

  void setPreset(ReportPeriodPreset preset) {
    final now = DateTime.now();
    DateTime newStart;
    DateTime newEnd = now;

    switch (preset) {
      case ReportPeriodPreset.lastMeeting:
        // Find most recent Friday
        var d = now;
        while (d.weekday != DateTime.friday) {
          d = d.subtract(const Duration(days: 1));
        }
        newStart = DateTime(d.year, d.month, d.day);
        newEnd = DateTime(d.year, d.month, d.day, 23, 59, 59);
        break;
      case ReportPeriodPreset.currentMonth:
        newStart = DateTime(now.year, now.month, 1);
        break;
      case ReportPeriodPreset.currentTerm:
        // Service term: October 1 to current
        final termYear = now.month < 9 ? now.year - 1 : now.year;
        newStart = DateTime(termYear, 10, 1);
        break;
      case ReportPeriodPreset.serviceYear:
        // Service year starts Sept 1
        final serviceYear = now.month < 9 ? now.year - 1 : now.year;
        newStart = DateTime(serviceYear, 9, 1);
        break;
      case ReportPeriodPreset.custom:
        newStart = state.start;
        newEnd = state.end;
        break;
    }

    state = state.copyWith(
      start: newStart,
      end: newEnd,
      preset: preset,
    );
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      start: start,
      end: end,
      preset: ReportPeriodPreset.custom,
    );
  }

  void setStage(String? stageId) {
    state = state.copyWith(stageId: stageId, classId: null);
  }

  void setClass(String? classId) {
    state = state.copyWith(classId: classId);
  }

  void setStudent(String? studentId) {
    state = state.copyWith(studentId: studentId);
  }

  void toggleComparison(bool value) {
    state = state.copyWith(compareWithPrevious: value);
  }

  void reset() {
    state = _defaultFilter();
  }
}

final reportFilterProvider =
    NotifierProvider<ReportFilterNotifier, ReportFilter>(
  ReportFilterNotifier.new,
);

/// Fetches the analytics report scoped to the user's permissions and active filter.
final reportsAnalyticsProvider =
    FutureProvider.family<ServiceReport, String>((ref, serviceId) async {
  final filter = ref.watch(reportFilterProvider);
  final scope = await ref.watch(reportUserScopeProvider(serviceId).future);
  final repository = ref.watch(reportRepositoryProvider);

  // Enforce role-based scoping
  Set<String>? effectiveClassIds;
  if (scope.isServiceWide) {
    if (filter.classId != null) {
      effectiveClassIds = {filter.classId!};
    }
  } else if (scope.accessibleClassIds != null) {
    if (filter.classId != null && scope.accessibleClassIds!.contains(filter.classId)) {
      effectiveClassIds = {filter.classId!};
    } else {
      effectiveClassIds = scope.accessibleClassIds;
    }
  } else {
    effectiveClassIds = {};
  }

  return repository.fetch(
    serviceId: serviceId,
    start: filter.start,
    end: filter.end,
    classIds: effectiveClassIds,
    stageId: scope.isServiceWide ? filter.stageId : scope.stageId,
    studentId: filter.studentId,
    compareWithPrevious: filter.compareWithPrevious,
  );
});
