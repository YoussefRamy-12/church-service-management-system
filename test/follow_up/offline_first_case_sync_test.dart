import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/follow_up/data/local_follow_up_case_repository.dart';
import 'package:church_service_management_system/features/follow_up/data/offline_first_follow_up_case_repository.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/activity_type.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_priority.dart';
import 'package:church_service_management_system/features/follow_up/domain/entities/case_status.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late OfflineFirstFollowUpCaseRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    repo = OfflineFirstFollowUpCaseRepository(
      local: LocalFollowUpCaseRepository(db),
      queue: queue,
    );
  });

  tearDown(() async => db.close());

  test('Case created offline is immediately available locally and queued for sync', () async {
    final created = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-100',
      classId: 'class-5a',
      title: 'متابعة أوفلاين',
      description: 'حالة مسجلة بدون اتصال إنترنت',
      priority: CasePriority.urgent,
      createdBy: 'servant-offline-1',
    );

    // 1. Immediately in local DB
    final localCase = await repo.getCaseById(created.id);
    expect(localCase, isNotNull);
    expect(localCase!.title, 'متابعة أوفلاين');
    expect(localCase.priority, CasePriority.urgent);
    expect(localCase.createdBy, 'servant-offline-1');

    // 2. Enqueued in sync queue
    final pending = await queue.pending();
    expect(pending, isNotEmpty);

    final caseOp = pending.firstWhere((op) => op.entityType == 'follow_up_case');
    expect(caseOp.operationType, 'insert');
    expect(caseOp.operationId, created.clientOperationId);

    final payload = jsonDecode(caseOp.payloadJson) as Map<String, dynamic>;
    expect(payload['id'], created.id);
    expect(payload['title'], 'متابعة أوفلاين');
    expect(payload['created_by'], 'servant-offline-1');
  });

  test('Activity created offline is immediately available and queued with author attribution', () async {
    final c = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'متابعة نشاط',
      priority: CasePriority.medium,
      createdBy: 'servant-1',
    );

    await db.delete(db.syncQueueEntries).go(); // Clear initial case queue items

    final activity = await repo.recordActivity(
      caseId: c.id,
      activityType: ActivityType.call,
      description: 'مكالمة هاتفية مع ولي الأمر تمت دون اتصال بالشبكة',
      createdBy: 'servant-author-42',
      activityDate: '2026-11-10',
    );

    // 1. Verified in local DB
    final activities = await repo.watchActivitiesForCase(c.id).first;
    expect(activities.any((a) => a.id == activity.id), isTrue);

    // 2. Enqueued in sync queue
    final pending = await queue.pending();
    expect(pending, hasLength(1));

    final actOp = pending.single;
    expect(actOp.entityType, 'follow_up_activity');
    expect(actOp.operationType, 'insert');

    final payload = jsonDecode(actOp.payloadJson) as Map<String, dynamic>;
    expect(payload['case_id'], c.id);
    expect(payload['activity_type'], 'call');
    expect(payload['created_by'], 'servant-author-42');
    expect(payload['activity_date'], '2026-11-10');
  });

  test('Status update offline is persisted and queued', () async {
    final c = await repo.createCase(
      serviceId: 'service-1',
      studentId: 'student-1',
      classId: 'class-5a',
      title: 'متابعة حالة',
      priority: CasePriority.medium,
      createdBy: 'servant-1',
    );

    await db.delete(db.syncQueueEntries).go();

    await repo.updateCaseStatus(
      caseId: c.id,
      newStatus: CaseStatus.waiting,
      actorId: 'servant-1',
      actorRole: 'class_servant',
      note: 'في انتظار رد التلميذ',
    );

    final localCase = await repo.getCaseById(c.id);
    expect(localCase?.status, CaseStatus.waiting);

    final pending = await queue.pending();
    final updateOp = pending.firstWhere((op) => op.entityType == 'follow_up_case' && op.operationType == 'update');
    final payload = jsonDecode(updateOp.payloadJson) as Map<String, dynamic>;
    expect(payload['status'], 'waiting');
  });
}
