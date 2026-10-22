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
          ),
        )
        .toList();
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
