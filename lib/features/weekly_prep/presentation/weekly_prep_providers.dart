import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../data/supabase_weekly_preparation_repository.dart';
import '../data/weekly_lesson_repository.dart';
import '../domain/preparation_review.dart';
import '../domain/preparation_status.dart';
import '../domain/repositories/weekly_preparation_repository.dart';
import '../domain/weekly_lesson.dart';
import '../domain/weekly_preparation.dart';

final weeklyLessonRepositoryProvider = Provider<WeeklyLessonRepository>(
  (ref) => WeeklyLessonRepository(ref.watch(supabaseClientProvider)),
);

final weeklyPreparationRepositoryProvider =
    Provider<WeeklyPreparationRepository>(
      (ref) => SupabaseWeeklyPreparationRepository(
        ref.watch(supabaseClientProvider),
        queue: ref.watch(syncQueueRepositoryProvider),
      ),
    );

/// Emits when weekly preparations or weekly lessons change in Supabase or locally.
final weeklyPrepChangesStreamProvider =
    StreamProvider.family<void, String>((ref, serviceId) {
      final repo = ref.watch(weeklyPreparationRepositoryProvider);
      return repo.watchChanges(serviceId: serviceId);
    });

final weeklyLessonsProvider = FutureProvider.family<List<WeeklyLesson>, String>(
  (ref, serviceId) {
    return ref.watch(weeklyLessonRepositoryProvider).list(serviceId);
  },
);

typedef ServantPrepKey = ({String lessonId, String servantProfileId});

final servantPreparationProvider =
    FutureProvider.family<WeeklyPreparation, ServantPrepKey>((ref, key) {
      return ref
          .watch(weeklyPreparationRepositoryProvider)
          .getPreparation(
            lessonId: key.lessonId,
            servantProfileId: key.servantProfileId,
          );
    });

final preparationReviewHistoryProvider =
    FutureProvider.family<List<PreparationReview>, ServantPrepKey>((ref, key) {
      return ref
          .watch(weeklyPreparationRepositoryProvider)
          .getReviewHistory(
            lessonId: key.lessonId,
            servantProfileId: key.servantProfileId,
          );
    });

class DashboardFilter {
  const DashboardFilter({
    required this.serviceId,
    this.stageId,
    this.classId,
    this.weekStart,
    this.statusFilter,
  });

  final String serviceId;
  final String? stageId;
  final String? classId;
  final DateTime? weekStart;
  final PreparationStatus? statusFilter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardFilter &&
          runtimeType == other.runtimeType &&
          serviceId == other.serviceId &&
          stageId == other.stageId &&
          classId == other.classId &&
          weekStart == other.weekStart &&
          statusFilter == other.statusFilter;

  @override
  int get hashCode =>
      serviceId.hashCode ^
      stageId.hashCode ^
      classId.hashCode ^
      weekStart.hashCode ^
      statusFilter.hashCode;
}

final dashboardPreparationsProvider =
    FutureProvider.family<List<WeeklyPreparation>, DashboardFilter>((
      ref,
      filter,
    ) {
      return ref
          .watch(weeklyPreparationRepositoryProvider)
          .listPreparationsForDashboard(
            serviceId: filter.serviceId,
            stageId: filter.stageId,
            classId: filter.classId,
            weekStart: filter.weekStart,
            statusFilter: filter.statusFilter,
          );
    });

final dashboardStatusCountsProvider =
    FutureProvider.family<Map<PreparationStatus, int>, DashboardFilter>((
      ref,
      filter,
    ) {
      return ref
          .watch(weeklyPreparationRepositoryProvider)
          .getStatusCounts(
            serviceId: filter.serviceId,
            stageId: filter.stageId,
            weekStart: filter.weekStart,
          );
    });
