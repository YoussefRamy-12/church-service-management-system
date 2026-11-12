import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/preparation_review.dart';
import '../domain/preparation_status.dart';
import '../domain/repositories/weekly_preparation_repository.dart';
import '../domain/weekly_preparation.dart';

class SupabaseWeeklyPreparationRepository
    implements WeeklyPreparationRepository {
  SupabaseWeeklyPreparationRepository(
    this._client, {
    SyncQueueRepository? queue,
  }) : _queue = queue;

  final SupabaseClient _client;
  final SyncQueueRepository? _queue;
  RealtimeChannel? _realtimeChannel;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  @override
  Stream<void> watchChanges({required String serviceId}) {
    if (_realtimeChannel == null) {
      try {
        _realtimeChannel = _client
            .channel('public:weekly_prep:$serviceId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'weekly_lesson_preparations',
              callback: (_) => _changesController.add(null),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'weekly_lessons',
              callback: (_) => _changesController.add(null),
            )
            .subscribe();
      } catch (_) {
        // Graceful fallback for mock clients or offline sockets
      }
    }
    return _changesController.stream;
  }

  Future<WeeklyPreparation?> _queuedPreparation({
    required String lessonId,
    required String servantProfileId,
  }) async {
    final queue = _queue;
    if (queue == null) return null;

    final operations = await queue.pending();
    for (final operation in operations.reversed) {
      if (operation.entityType != 'weekly_preparation') continue;
      final payload = queue.decode(operation.payloadJson);
      if (payload['weekly_lesson_id'] != lessonId ||
          payload['servant_profile_id'] != servantProfileId) {
        continue;
      }
      return WeeklyPreparation(
        weeklyLessonId: lessonId,
        servantProfileId: servantProfileId,
        status: PreparationStatus.fromString(
          payload['status'] as String?,
        ),
        prepared: false,
        submittedAt: payload['submitted_at'] != null
            ? DateTime.parse(payload['submitted_at'] as String)
            : null,
        updatedAt: payload['updated_at'] != null
            ? DateTime.parse(payload['updated_at'] as String)
            : DateTime.now().toUtc(),
        syncState: 'pending',
      );
    }
    return null;
  }

  @override
  Future<WeeklyPreparation> getPreparation({
    required String lessonId,
    required String servantProfileId,
  }) async {
    try {
      final row = await _client
          .from('weekly_lesson_preparations')
          .select('*, reviewer:servant_profiles!reviewed_by(name)')
          .eq('weekly_lesson_id', lessonId)
          .eq('servant_profile_id', servantProfileId)
          .maybeSingle();

      // A durable queued mutation takes precedence until the sync engine applies it.
      final queued = await _queuedPreparation(
        lessonId: lessonId,
        servantProfileId: servantProfileId,
      );
      if (queued != null) return queued;

      if (row == null) {
        return WeeklyPreparation(
          weeklyLessonId: lessonId,
          servantProfileId: servantProfileId,
          status: PreparationStatus.notSubmitted,
          prepared: false,
          updatedAt: DateTime.now().toUtc(),
          syncState: 'synced',
        );
      }

      final reviewerMap = row['reviewer'] as Map<String, dynamic>?;
      final reviewerName = reviewerMap?['name'] as String?;

      return WeeklyPreparation(
        weeklyLessonId: row['weekly_lesson_id'] as String,
        servantProfileId: row['servant_profile_id'] as String,
        status: PreparationStatus.fromString(row['status'] as String?),
        prepared: row['prepared'] as bool? ?? false,
        submittedAt: row['submitted_at'] != null
            ? DateTime.parse(row['submitted_at'] as String)
            : null,
        reviewedAt: row['reviewed_at'] != null
            ? DateTime.parse(row['reviewed_at'] as String)
            : null,
        reviewedBy: row['reviewed_by'] as String?,
        reviewerName: reviewerName,
        reviewNote: row['review_note'] as String?,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        syncState: 'synced',
      );
    } catch (_) {
      final queued = await _queuedPreparation(
        lessonId: lessonId,
        servantProfileId: servantProfileId,
      );
      if (queued != null) return queued;
      rethrow;
    }
  }

  @override
  Future<WeeklyPreparation> submitPreparation({
    required String lessonId,
    required String servantProfileId,
  }) async {
    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();

    try {
      await _client.from('weekly_lesson_preparations').upsert({
        'weekly_lesson_id': lessonId,
        'servant_profile_id': servantProfileId,
        'status': PreparationStatus.submitted.value,
        'prepared': false,
        'submitted_at': nowIso,
        'updated_at': nowIso,
      }, onConflict: 'weekly_lesson_id,servant_profile_id');

      _changesController.add(null);
      return WeeklyPreparation(
        weeklyLessonId: lessonId,
        servantProfileId: servantProfileId,
        status: PreparationStatus.submitted,
        prepared: false,
        submittedAt: now,
        updatedAt: now,
        syncState: 'synced',
      );
    } catch (error) {
      if (error is PostgrestException) rethrow;
      if (_queue != null) {
        final opId = const Uuid().v4();
        await _queue.enqueue(
          SyncOperation(
            operationId: opId,
            entityType: 'weekly_preparation',
            operationType: 'submit',
            payloadJson: jsonEncode({
              'weekly_lesson_id': lessonId,
              'servant_profile_id': servantProfileId,
              'status': PreparationStatus.submitted.value,
              'submitted_at': nowIso,
              'updated_at': nowIso,
            }),
          ),
        );
        _changesController.add(null);
        return WeeklyPreparation(
          weeklyLessonId: lessonId,
          servantProfileId: servantProfileId,
          status: PreparationStatus.submitted,
          prepared: false,
          submittedAt: now,
          updatedAt: now,
          syncState: 'pending',
        );
      }
      rethrow;
    }
  }

  @override
  Future<WeeklyPreparation> resubmitPreparation({
    required String lessonId,
    required String servantProfileId,
  }) async {
    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();

    try {
      await _client
          .from('weekly_lesson_preparations')
          .update({
            'status': PreparationStatus.submitted.value,
            'prepared': false,
            'submitted_at': nowIso,
            'updated_at': nowIso,
          })
          .eq('weekly_lesson_id', lessonId)
          .eq('servant_profile_id', servantProfileId);

      _changesController.add(null);
      return WeeklyPreparation(
        weeklyLessonId: lessonId,
        servantProfileId: servantProfileId,
        status: PreparationStatus.submitted,
        prepared: false,
        submittedAt: now,
        updatedAt: now,
        syncState: 'synced',
      );
    } catch (error) {
      if (error is PostgrestException) rethrow;
      if (_queue != null) {
        final opId = const Uuid().v4();
        await _queue.enqueue(
          SyncOperation(
            operationId: opId,
            entityType: 'weekly_preparation',
            operationType: 'resubmit',
            payloadJson: jsonEncode({
              'weekly_lesson_id': lessonId,
              'servant_profile_id': servantProfileId,
              'status': PreparationStatus.submitted.value,
              'submitted_at': nowIso,
              'updated_at': nowIso,
            }),
          ),
        );
        _changesController.add(null);
        return WeeklyPreparation(
          weeklyLessonId: lessonId,
          servantProfileId: servantProfileId,
          status: PreparationStatus.submitted,
          prepared: false,
          submittedAt: now,
          updatedAt: now,
          syncState: 'pending',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> reviewPreparation({
    required String lessonId,
    required String servantProfileId,
    required PreparationStatus action,
    String? note,
  }) async {
    if (action != PreparationStatus.approved &&
        action != PreparationStatus.needsRevision) {
      throw ArgumentError('الإجراء غير صالح للمراجعة.');
    }
    if (action == PreparationStatus.needsRevision &&
        (note == null || note.trim().isEmpty)) {
      throw ArgumentError('ملاحظات التعديل إلزامية عند طلب إعادة التحضير.');
    }

    await _client.rpc(
      'review_weekly_preparation',
      params: {
        'p_lesson_id': lessonId,
        'p_servant_profile_id': servantProfileId,
        'p_action': action.value,
        'p_note': note?.trim(),
      },
    );
    _changesController.add(null);
  }

  @override
  Future<List<PreparationReview>> getReviewHistory({
    required String lessonId,
    required String servantProfileId,
  }) async {
    final rows = await _client
        .from('weekly_lesson_preparation_reviews')
        .select('*, reviewer:servant_profiles!reviewer_id(name)')
        .eq('weekly_lesson_id', lessonId)
        .eq('servant_profile_id', servantProfileId)
        .order('reviewed_at', ascending: false);

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      final reviewer = map['reviewer'] as Map<String, dynamic>?;
      return PreparationReview(
        id: map['id'] as String,
        weeklyLessonId: map['weekly_lesson_id'] as String,
        servantProfileId: map['servant_profile_id'] as String,
        reviewerId: map['reviewer_id'] as String,
        reviewerName: reviewer?['name'] as String?,
        action: PreparationStatus.fromString(map['action'] as String?),
        note: map['note'] as String?,
        reviewedAt: DateTime.parse(map['reviewed_at'] as String),
      );
    }).toList();
  }

  @override
  Future<List<WeeklyPreparation>> listPreparationsForDashboard({
    required String serviceId,
    String? stageId,
    String? classId,
    DateTime? weekStart,
    PreparationStatus? statusFilter,
  }) async {
    // 1. Fetch active servants in service scope
    var servantQuery = _client
        .from('servant_profiles')
        .select('id, name, stage_id, class_id, role, account_status')
        .eq('service_id', serviceId)
        .eq('account_status', 'active');

    if (stageId != null) {
      servantQuery = servantQuery.eq('stage_id', stageId);
    }
    if (classId != null) {
      servantQuery = servantQuery.eq('class_id', classId);
    }

    final servantRows = await servantQuery.order('name');
    final servants = (servantRows as List).cast<Map<String, dynamic>>();

    // 2. Fetch stages and classes for display names
    final stagesRows = await _client
        .from('stages')
        .select('id, name')
        .eq('service_id', serviceId);
    final stageNameMap = {
      for (final s in (stagesRows as List))
        s['id'] as String: s['name'] as String,
    };

    final classesRows = await _client.from('classes').select('id, name');
    final classNameMap = {
      for (final c in (classesRows as List))
        c['id'] as String: c['name'] as String,
    };

    // 3. Find lessons matching criteria
    var lessonQuery = _client
        .from('weekly_lessons')
        .select('id, stage_id, week_start')
        .eq('service_id', serviceId);

    if (stageId != null) {
      lessonQuery = lessonQuery.eq('stage_id', stageId);
    }
    if (weekStart != null) {
      final dateStr =
          '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      lessonQuery = lessonQuery.eq('week_start', dateStr);
    }

    final lessonRows = await lessonQuery;
    final lessonList = (lessonRows as List).cast<Map<String, dynamic>>();
    if (lessonList.isEmpty) return [];

    final lessonIds = lessonList.map((l) => l['id'] as String).toList();

    // 4. Fetch existing preparation records for these lessons
    final prepRows = await _client
        .from('weekly_lesson_preparations')
        .select('*, reviewer:servant_profiles!reviewed_by(name)')
        .filter('weekly_lesson_id', 'in', lessonIds);

    final prepList = (prepRows as List).cast<Map<String, dynamic>>();
    final prepMap = <String, Map<String, dynamic>>{};
    for (final p in prepList) {
      final key = '${p['weekly_lesson_id']}_${p['servant_profile_id']}';
      prepMap[key] = p;
    }

    // 5. Merge servants with preparations for each lesson in their stage
    final results = <WeeklyPreparation>[];
    for (final lesson in lessonList) {
      final lId = lesson['id'] as String;
      final lStageId = lesson['stage_id'] as String;

      for (final servant in servants) {
        final sId = servant['id'] as String;
        final sStageId = servant['stage_id'] as String?;
        final sClassId = servant['class_id'] as String?;

        // Include servant if they belong to this lesson's stage or if servant's stage is null (overall)
        if (sStageId != null && sStageId != lStageId) continue;

        final key = '${lId}_$sId';
        final prep = prepMap[key];
        final reviewer = prep?['reviewer'] as Map<String, dynamic>?;

        final status = PreparationStatus.fromString(prep?['status'] as String?);

        // Apply status filter if set
        if (statusFilter != null && status != statusFilter) continue;

        results.add(
          WeeklyPreparation(
            weeklyLessonId: lId,
            servantProfileId: sId,
            servantName: servant['name'] as String?,
            stageName: sStageId != null ? stageNameMap[sStageId] : null,
            className: sClassId != null ? classNameMap[sClassId] : null,
            status: status,
            prepared: prep?['prepared'] as bool? ?? false,
            submittedAt: prep?['submitted_at'] != null
                ? DateTime.parse(prep!['submitted_at'] as String)
                : null,
            reviewedAt: prep?['reviewed_at'] != null
                ? DateTime.parse(prep!['reviewed_at'] as String)
                : null,
            reviewedBy: prep?['reviewed_by'] as String?,
            reviewerName: reviewer?['name'] as String?,
            reviewNote: prep?['review_note'] as String?,
            updatedAt: prep != null
                ? DateTime.parse(prep['updated_at'] as String)
                : DateTime.now().toUtc(),
            syncState: 'synced',
          ),
        );
      }
    }

    return results;
  }

  @override
  Future<Map<PreparationStatus, int>> getStatusCounts({
    required String serviceId,
    String? stageId,
    DateTime? weekStart,
  }) async {
    final all = await listPreparationsForDashboard(
      serviceId: serviceId,
      stageId: stageId,
      weekStart: weekStart,
    );

    final counts = <PreparationStatus, int>{
      PreparationStatus.notSubmitted: 0,
      PreparationStatus.submitted: 0,
      PreparationStatus.approved: 0,
      PreparationStatus.needsRevision: 0,
    };

    for (final p in all) {
      counts[p.status] = (counts[p.status] ?? 0) + 1;
    }

    return counts;
  }
}
