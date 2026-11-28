import '../preparation_review.dart';
import '../preparation_status.dart';
import '../weekly_preparation.dart';

abstract class WeeklyPreparationRepository {
  /// Fetch a single preparation record for a servant and lesson.
  /// If no record exists, returns a default [WeeklyPreparation] with [PreparationStatus.notSubmitted].
  Future<WeeklyPreparation> getPreparation({
    required String lessonId,
    required String servantProfileId,
  });

  /// Submit a preparation for review (not_submitted -> submitted).
  /// If offline, queues the submission in local sync queue with pending sync status.
  Future<WeeklyPreparation> submitPreparation({
    required String lessonId,
    required String servantProfileId,
  });

  /// Resubmit a preparation after revision (needs_revision -> submitted).
  /// Preserves previous review history and notes.
  /// If offline, queues the submission with pending sync status.
  Future<WeeklyPreparation> resubmitPreparation({
    required String lessonId,
    required String servantProfileId,
  });

  /// Review a preparation (submitted -> approved or needs_revision).
  /// Mandatory [note] required if action is [PreparationStatus.needsRevision].
  /// Requires online connectivity (server-side authorization & reviewer stamping).
  Future<void> reviewPreparation({
    required String lessonId,
    required String servantProfileId,
    required PreparationStatus action,
    String? note,
  });

  /// Get the review history trail for a servant and lesson.
  Future<List<PreparationReview>> getReviewHistory({
    required String lessonId,
    required String servantProfileId,
  });

  /// List preparations for leadership dashboard with stage/class/status filters.
  Future<List<WeeklyPreparation>> listPreparationsForDashboard({
    required String serviceId,
    String? stageId,
    String? classId,
    DateTime? weekStart,
    PreparationStatus? statusFilter,
  });

  /// Get aggregated counts per status for the metrics overview row.
  Future<Map<PreparationStatus, int>> getStatusCounts({
    required String serviceId,
    String? stageId,
    DateTime? weekStart,
  });

  /// Real-time stream that emits whenever weekly preparations change in Supabase or locally.
  Stream<void> watchChanges({required String serviceId});
}
