import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/follow_up_record.dart';
import '../domain/repositories/follow_up_repository.dart';

/// Online-only implementation of [FollowUpRepository].
///
/// Communicates directly with Supabase, bypassing local Drift database and
/// sync mutation queue.
class OnlineFollowUpRepository implements FollowUpRepository {
  const OnlineFollowUpRepository(this._client);

  final SupabaseClient _client;
  static const Uuid _uuid = Uuid();

  @override
  Stream<List<FollowUpRecord>> watchForStudent(String id) async* {
    final rows = await _client
        .from('follow_up_records')
        .select()
        .eq('student_id', id)
        .eq('is_request', false)
        .order('follow_up_date', ascending: true);

    yield rows
        .map(
          (r) => FollowUpRecord(
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
            anotherFollowUpNeeded:
                (r['another_follow_up_needed'] as bool?) ?? false,
            nextFollowUpDate: r['next_follow_up_date'] as String?,
            clientOperationId: (r['client_operation_id'] as String?) ?? '',
            assignedTo: r['assigned_to'] as String?,
            isRequest: (r['is_request'] as bool?) ?? false,
            requestStatus: (r['request_status'] as String?) ?? 'open',
          ),
        )
        .toList();
  }

  @override
  Future<void> refreshAssignedTo(String servantProfileId) async {
    await _client.from('follow_up_records').select('id')
        .eq('is_request', true).eq('assigned_to', servantProfileId).limit(1);
  }

  @override
  Stream<List<FollowUpRecord>> watchAssignedTo(String servantProfileId) async* {
    final rows = await _client.from('follow_up_records').select()
        .eq('is_request', true).eq('assigned_to', servantProfileId)
        .order('follow_up_date', ascending: true);
    yield rows.map((row) => _mapRecord(row)).toList();
  }

  FollowUpRecord _mapRecord(Map<String, dynamic> r) => FollowUpRecord(
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

  @override
  Future<FollowUpRecord> createRequest({
    required String studentId,
    required String createdBy,
    required String assignedTo,
    required String dueDate,
    required String actionRequired,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final clientOpId = _uuid.v4();
    final payload = <String, dynamic>{
      'id': id, 'student_id': studentId, 'created_by': createdBy,
      'assigned_to': assignedTo, 'follow_up_date': dueDate,
      'contact_status': 'not_contacted', 'action_required': actionRequired,
      'notes': notes, 'is_request': true, 'request_status': 'open',
      'client_operation_id': clientOpId,
    };
    await _client.from('follow_up_records').insert(payload);
    return FollowUpRecord(
      id: id, studentId: studentId, createdBy: createdBy,
      assignedTo: assignedTo, followUpDate: dueDate,
      contactStatus: 'not_contacted', actionRequired: actionRequired,
      notes: notes, isRequest: true, requestStatus: 'open',
      clientOperationId: clientOpId,
    );
  }

  @override
  Future<void> updateRequestStatus({required String requestId, required String status}) async {
    await _client.from('follow_up_records').update({'request_status': status})
        .eq('id', requestId).eq('is_request', true);
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
    final id = _uuid.v4();
    final clientOpId = _uuid.v4();

    final payload = <String, dynamic>{
      'id': id,
      'student_id': studentId,
      'created_by': createdBy,
      'follow_up_date': followUpDate,
      'contact_status': contactStatus,
      'contact_method': contactMethod,
      'absence_reason': absenceReason,
      'student_response': studentResponse,
      'parent_response': parentResponse,
      'action_required': actionRequired,
      'notes': notes,
      'another_follow_up_needed': anotherFollowUpNeeded,
      'next_follow_up_date': nextFollowUpDate,
      'client_operation_id': clientOpId,
    };

    await _client.from('follow_up_records').insert(payload);

    return FollowUpRecord(
      id: id,
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
      clientOperationId: clientOpId,
    );
  }
}
