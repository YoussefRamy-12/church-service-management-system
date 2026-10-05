import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/student.dart';
import '../domain/repositories/student_repository.dart';

class SupabaseStudentRepository implements StudentRepository {
  SupabaseStudentRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) async* {
    final rows = await _client
        .from('students')
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, enrollment_at, approval_status, '
          'photo_path, notes',
        )
        .eq('current_class_id', classId)
        .order('name');

    yield rows.map(_fromRow).toList();
  }

  Future<List<Student>> fetchStudentsForClass(String classId) async {
    final rows = await _client
        .from('students')
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, enrollment_at, approval_status, '
          'photo_path, notes',
        )
        .eq('current_class_id', classId)
        .order('name');

    return rows.map(_fromRow).toList();
  }

  Student _fromRow(Map<String, dynamic> row) => Student(
        id: row['id'] as String,
        serviceId: row['service_id'] as String,
        name: row['name'] as String,
        approvalStatus: row['approval_status'] as String,
        currentClassId: row['current_class_id'] as String?,
        proposedClassId: row['proposed_class_id'] as String?,
        birthDate: _date(row['birth_date']),
        phone: row['phone'] as String?,
        school: row['school'] as String?,
        grade: row['grade'] as String?,
        enrollmentAt: _date(row['enrollment_at']),
        photoPath: row['photo_path'] as String?,
        notes: row['notes'] as String?,
      );

  DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
