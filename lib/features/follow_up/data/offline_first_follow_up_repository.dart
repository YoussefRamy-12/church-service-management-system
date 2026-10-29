import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/follow_up_record.dart';
import '../domain/repositories/follow_up_repository.dart';
import 'local_follow_up_repository.dart';

class OfflineFirstFollowUpRepository implements FollowUpRepository {
  OfflineFirstFollowUpRepository({required this.local, required this.queue, required this.client});

  final LocalFollowUpRepository local;
  final SyncQueueRepository queue;
  final SupabaseClient client;

  @override
  Stream<List<FollowUpRecord>> watchForStudent(String id) =>
      local.watchForStudent(id);

  @override
  Stream<List<FollowUpRecord>> watchAssignedTo(String id) => local.watchAssignedTo(id);

  @override
  Future<void> refreshAssignedTo(String servantProfileId) async {
    final rows = await client.from('follow_up_records').select()
        .eq('is_request', true).eq('assigned_to', servantProfileId)
        .order('follow_up_date', ascending: true);
    final requests = rows.map((raw) {
      final r = Map<String, dynamic>.from(raw as Map);
      return FollowUpRecord(
        id: r['id'] as String,
        studentId: r['student_id'] as String,
        createdBy: r['created_by'] as String,
        followUpDate: r['follow_up_date'] as String,
        contactStatus: r['contact_status'] as String,
        contactMethod: r['contact_method'] as String?,
        absenceReason: r['absence_reason'] as String?,
        studentResponse: r['student_response'] as String?,
        parentResponse: r['parent_response'] as String?,
        actionRequired: r['action_required'] as String?,
        notes: r['notes'] as String?,
        anotherFollowUpNeeded: (r['another_follow_up_needed'] as bool?) ?? false,
        nextFollowUpDate: r['next_follow_up_date'] as String?,
        clientOperationId: (r['client_operation_id'] as String?) ?? '',
        assignedTo: r['assigned_to'] as String?,
        isRequest: (r['is_request'] as bool?) ?? false,
        requestStatus: (r['request_status'] as String?) ?? 'open',
      );
    }).toList();
    await local.cacheRequests(requests);
  }

  @override
  Future<FollowUpRecord> createRequest({
    required String studentId,
    required String createdBy,
    required String assignedTo,
    required String dueDate,
    required String actionRequired,
    String? notes,
  }) async {
    final record = await local.createRequest(
      studentId: studentId, createdBy: createdBy, assignedTo: assignedTo,
      dueDate: dueDate, actionRequired: actionRequired, notes: notes,
    );
    await queue.enqueue(SyncOperation(
      operationId: record.clientOperationId,
      entityType: 'follow_up', operationType: 'insert',
      payloadJson: jsonEncode({
        'id': record.id, 'student_id': record.studentId, 'created_by': record.createdBy,
        'assigned_to': record.assignedTo, 'follow_up_date': record.followUpDate,
        'contact_status': record.contactStatus, 'action_required': record.actionRequired,
        'notes': record.notes, 'is_request': true, 'request_status': record.requestStatus,
        'client_operation_id': record.clientOperationId,
      }),
    ));
    return record;
  }

  @override
  Future<void> updateRequestStatus({required String requestId, required String status}) async {
    await local.updateRequestStatus(requestId: requestId, status: status);
    await queue.enqueue(SyncOperation(
      operationId: const Uuid().v4(), entityType: 'follow_up', operationType: 'update',
      payloadJson: jsonEncode({'id': requestId, 'is_request': true, 'request_status': status}),
    ));
  }

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
          'assigned_to': record.assignedTo,
          'is_request': record.isRequest,
          'request_status': record.requestStatus,
          'client_operation_id': record.clientOperationId,
          'assigned_to': record.assignedTo,
          'is_request': record.isRequest,
          'request_status': record.requestStatus,
        }),
      ),
    );
    return record;
  }
}
