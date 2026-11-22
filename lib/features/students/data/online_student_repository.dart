import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';
import '../domain/repositories/student_repository.dart';

/// Online-only repository for student data operations directly against Supabase.
///
/// Bypasses local Drift/SQLite caching and mutation queues.
class OnlineStudentRepository implements StudentRepository {
  const OnlineStudentRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) async* {
    final service = await _client.from('classes')
        .select('service_id').eq('id', classId).maybeSingle();
    if (service == null) {
      yield [];
      return;
    }
    final rows = await _client.rpc(
      'get_service_student_directory',
      params: {'p_service_id': service['service_id']},
    );
    yield (rows as List)
        .map((row) => _fromMembershipRow(Map<String, dynamic>.from(row as Map)))
        .where((student) =>
            (student.membershipStatus == 'active' || student.membershipStatus == 'pending') &&
            (student.currentClassId == classId || student.proposedClassId == classId))
        .toList();
  }

  @override
  Stream<List<Student>> watchStudentsForService(String serviceId) async* {
    final rows = await _client.rpc(
      'get_service_student_directory',
      params: {'p_service_id': serviceId},
    );
    yield (rows as List)
        .map((row) => _fromMembershipRow(Map<String, dynamic>.from(row as Map)))
        .where((student) => student.membershipStatus == 'active' || student.membershipStatus == 'pending')
        .toList();
  }

  @override
  Future<void> refreshStudents(String classId) async {
    await watchStudentsForClass(classId).first;
  }

  @override
  Future<void> refreshStudentsForService(String serviceId) async {
    await watchStudentsForService(serviceId).first;
  }

  @override
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    String? membershipId,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    bool? isDeacon,
    DateTime? enrollmentAt,
    String? photoPath,
    String? notes,
    SensitiveStudentData? sensitiveData,
  }) async {
    final id = membershipId;
    if (id == null) throw StateError('Student membership is required for editing.');
    await _client.rpc('update_service_student', params: {
      'p_membership_id': id,
      'p_name': name.trim(),
      'p_birth_date': birthDate?.toIso8601String().split('T').first,
      'p_phone': phone,
      'p_photo_path': photoPath,
      'p_school': school,
      'p_grade': grade,
      'p_is_deacon': isDeacon,
      'p_enrollment_date': enrollmentAt?.toIso8601String(),
      'p_notes': notes,
    });
    if (sensitiveData != null) {
      final map = sensitiveData.toMap();
      if (map.values.any((v) => v != null && v.toString().trim().isNotEmpty)) {
        await _safeUpsertSensitiveData(studentId, map);
      }
    }
    return _fetchMembership(id);
  }

  @override
  Future<Student> approvePending(String studentId, {String? membershipId}) async {
    final id = membershipId;
    if (id == null) throw StateError('Student membership is required for approval.');
    await _client.rpc('approve_service_student', params: {'p_membership_id': id});
    return _fetchMembership(id);
  }

  @override
  Future<void> deleteStudent(String studentId, {String? membershipId}) async {
    final id = membershipId;
    if (id == null) throw StateError('Student membership is required for archival.');
    await _client.rpc('archive_service_student', params: {'p_membership_id': id});
  }

  @override
  Future<Student> assignClass(
    String studentId,
    String classId, {
    String? membershipId,
  }) async {
    final id = membershipId;
    if (id == null) throw StateError('Student membership is required for class assignment.');
    await _client.rpc('assign_service_student_class', params: {
      'p_membership_id': id,
      'p_class_id': classId,
    });
    return _fetchMembership(id);
  }

  Future<Student> _fetchMembership(String membershipId) async {
    final membership = await _client.from('service_students')
        .select('service_id').eq('id', membershipId).single();
    final rows = await _client.rpc(
      'get_service_student_directory',
      params: {'p_service_id': membership['service_id']},
    );
    final match = (rows as List)
        .map((row) => _fromMembershipRow(Map<String, dynamic>.from(row as Map)))
        .where((student) => student.membershipId == membershipId);
    return match.first;
  }


  @override
  Future<SensitiveStudentData?> getSensitiveData(String studentId) async {
    final row = await _client
        .from('student_sensitive_data')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
    if (row == null) return null;
    return SensitiveStudentData.fromMap(row, studentId: studentId);
  }

  Student _fromMembershipRow(Map<String, dynamic> row) {
    final status = row['membership_status'] as String;
    return Student(
      id: row['student_id'] as String,
      membershipId: row['membership_id'] as String,
      membershipStatus: status,
      serviceId: row['service_id'] as String,
      identityServiceId: row['identity_service_id'] as String?,
      name: row['student_name'] as String? ?? '',
      approvalStatus: status == 'pending' ? 'pending' : 'approved',
      currentClassId: row['class_id'] as String?,
      proposedClassId: row['proposed_class_id'] as String?,
      birthDate: _date(row['birth_date']),
      phone: row['phone'] as String?,
      school: row['school'] as String?,
      grade: row['grade'] as String?,
      isDeacon: row['is_deacon'] as bool? ?? false,
      enrollmentAt: _date(row['enrollment_date']),
      photoPath: row['photo_path'] as String?,
      notes: row['membership_notes'] as String?,
    );
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Future<void> _safeUpsertSensitiveData(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    final payload = <String, dynamic>{
      'student_id': studentId,
      ...data,
    };

    while (payload.length > 1) {
      try {
        await _client.from('student_sensitive_data').upsert(
              payload,
              onConflict: 'student_id',
            );
        return;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' ||
            e.message.contains('Could not find the column')) {
          final match = RegExp(r"column '([^']+)'").firstMatch(e.message);
          if (match != null) {
            final missingCol = match.group(1);
            if (missingCol != null && payload.containsKey(missingCol)) {
              payload.remove(missingCol);
              continue;
            }
          }
        }
        rethrow;
      }
    }
  }
}
