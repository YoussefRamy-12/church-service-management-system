import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/student.dart';

class SupabaseStudentRepository {
  SupabaseStudentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Student>> fetchStudentsForService(String serviceId) async {
    final rows = await _client.rpc(
      'get_service_student_directory',
      params: {'p_service_id': serviceId},
    );
    return (rows as List)
        .map((row) => _fromMembershipRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<Student>> fetchStudentsForClass(String classId) async {
    final stages = await _client
        .from('classes')
        .select('service_id')
        .eq('id', classId)
        .maybeSingle();
    if (stages == null) return [];
    final rows = await _client.rpc(
      'get_service_student_directory',
      params: {'p_service_id': stages['service_id']},
    );
    return (rows as List)
        .map((row) => _fromMembershipRow(Map<String, dynamic>.from(row as Map)))
        .where((student) =>
            student.currentClassId == classId ||
            student.proposedClassId == classId)
        .toList();
  }

  Stream<List<Student>> watchStudentsForClass(String classId) async* {
    yield await fetchStudentsForClass(classId);
  }

  Stream<List<Student>> watchStudentsForService(String serviceId) async* {
    yield await fetchStudentsForService(serviceId);
  }

  Future<Map<String, dynamic>?> fetchSensitiveData(String studentId) async {
    try {
      final row = await _client
          .from('student_sensitive_data')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();
      return row;
    } catch (_) {
      return null;
    }
  }

  Student _fromMembershipRow(Map<String, dynamic> row) {
    final status = row['membership_status'] as String;
    return Student(
      id: row['student_id'] as String,
      membershipId: row['membership_id'] as String,
      membershipStatus: status,
      serviceId: row['service_id'] as String,
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

  DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
