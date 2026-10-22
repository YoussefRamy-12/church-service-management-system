import 'dart:convert';

import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/follow_up_record.dart';
import '../domain/repositories/follow_up_repository.dart';
import 'local_follow_up_repository.dart';

class OfflineFirstFollowUpRepository implements FollowUpRepository {
  OfflineFirstFollowUpRepository({required this.local, required this.queue});

  final LocalFollowUpRepository local;
  final SyncQueueRepository queue;

  @override
  Stream<List<FollowUpRecord>> watchForStudent(String id) =>
      local.watchForStudent(id);

  @override
  Future<FollowUpRecord> create({
    required String studentId,
    required String createdBy,
    required String followUpDate,
    required String contactStatus,
    String? contactMethod,
    String? absenceReason,
    String? studentResponse,
    String? parentResponse,
    String? actionRequired,
    String? notes,
    bool anotherFollowUpNeeded = false,
    String? nextFollowUpDate,
  }) async {
    final record = await local.create(
      studentId: studentId,
      createdBy: createdBy,
      followUpDate: followUpDate,
      contactStatus: contactStatus,
      contactMethod: contactMethod,
      absenceReason: absenceReason,
      studentResponse: studentResponse,
      parentResponse: parentResponse,
      actionRequired: actionRequired,
      notes: notes,
      anotherFollowUpNeeded: anotherFollowUpNeeded,
      nextFollowUpDate: nextFollowUpDate,
    );
    await queue.enqueue(
      SyncOperation(
        operationId: record.clientOperationId,
        entityType: 'follow_up',
        operationType: 'insert',
        payloadJson: jsonEncode({
          'id': record.id,
          'student_id': record.studentId,
          'created_by': record.createdBy,
          'follow_up_date': record.followUpDate,
          'contact_status': record.contactStatus,
          'contact_method': record.contactMethod,
          'absence_reason': record.absenceReason,
          'student_response': record.studentResponse,
          'parent_response': record.parentResponse,
          'action_required': record.actionRequired,
          'notes': record.notes,
          'another_follow_up_needed': record.anotherFollowUpNeeded,
          'next_follow_up_date': record.nextFollowUpDate,
          'client_operation_id': record.clientOperationId,
        }),
      ),
    );
    return record;
  }
}
