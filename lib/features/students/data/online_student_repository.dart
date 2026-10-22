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
    final rows = await _client
        .from('students')
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, is_deacon, enrollment_at, approval_status, '
          'photo_path, notes',
        )
        .eq('current_class_id', classId)
        .order('name');
    yield rows.map(_fromRow).toList();
  }

  @override
  Stream<List<Student>> watchStudentsForService(String serviceId) async* {
    final rows = await _client
        .from('students')
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, is_deacon, enrollment_at, approval_status, '
          'photo_path, notes',
        )
        .eq('service_id', serviceId)
        .order('name');
    yield rows.map(_fromRow).toList();
  }

  @override
  Future<void> refreshStudents(String classId) async {
    await _client
        .from('students')
        .select('id')
        .eq('current_class_id', classId)
        .limit(1);
  }

  @override
  Future<void> refreshStudentsForService(String serviceId) async {
    await _client
        .from('students')
        .select('id')
        .eq('service_id', serviceId)
        .limit(1);
  }

  @override
  Future<Student> updateStudent({
    required String studentId,
    required String name,
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
    final payload = <String, dynamic>{
      'name': name.trim(),
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'school': school?.trim().isEmpty == true ? null : school?.trim(),
      'grade': grade?.trim().isEmpty == true ? null : grade?.trim(),
      'is_deacon': ?isDeacon,
      'enrollment_at': enrollmentAt?.toIso8601String(),
      'photo_path': photoPath?.trim().isEmpty == true ? null : photoPath?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    };

    final rows = await _client
        .from('students')
        .update(payload)
        .eq('id', studentId)
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, is_deacon, enrollment_at, approval_status, '
          'photo_path, notes',
        );

    if (rows.isEmpty) {
      throw StateError('Student update was rejected or not found on server.');
    }

    if (sensitiveData != null) {
      final map = sensitiveData.toMap();
      if (map.values.any((v) => v != null && v.toString().trim().isNotEmpty)) {
        await _safeUpsertSensitiveData(studentId, map);
      }
    }

    return _fromRow(rows.first);
  }

  @override
  Future<Student> approvePending(String studentId) async {
    final currentRows = await _client
        .from('students')
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, is_deacon, enrollment_at, approval_status, '
          'photo_path, notes',
        )
        .eq('id', studentId);

    if (currentRows.isEmpty) {
      throw StateError('Student not found: $studentId');
    }
    final current = _fromRow(currentRows.first);
    if (!current.isPending || current.proposedClassId == null) {
      throw StateError(
        'Only pending students with a proposed class can be approved.',
      );
    }

    final rows = await _client
        .from('students')
        .update({
          'approval_status': 'approved',
          'current_class_id': current.proposedClassId,
          'proposed_class_id': null,
        })
        .eq('id', studentId)
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, is_deacon, enrollment_at, approval_status, '
          'photo_path, notes',
        );

    if (rows.isEmpty) {
      throw StateError('Student approval was rejected by server.');
    }

    return _fromRow(rows.first);
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    try {
      final rows = await _client
          .from('students')
          .delete()
          .eq('id', studentId)
          .select('id');
      if (rows.isEmpty) {
        throw StateError('Student deletion was rejected or student not found.');
      }
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw StateError(
          'تعذر حذف التلميذ لوجود سجلات مرتبطة به (مثل الحضور أو الافتقاد).',
        );
      }
      rethrow;
    }
  }

  @override
  Future<Student> assignClass(String studentId, String classId) async {
    final rows = await _client
        .from('students')
        .update({
          'current_class_id': classId,
          'proposed_class_id': null,
        })
        .eq('id', studentId)
        .select(
          'id, service_id, current_class_id, proposed_class_id, name, '
          'birth_date, phone, school, grade, is_deacon, enrollment_at, approval_status, '
          'photo_path, notes',
        );

    if (rows.isEmpty) {
      throw StateError('Class assignment was rejected by server.');
    }

    return _fromRow(rows.first);
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
    isDeacon: (row['is_deacon'] as bool?) ?? false,
    enrollmentAt: _date(row['enrollment_at']),
    photoPath: row['photo_path'] as String?,
    notes: row['notes'] as String?,
  );

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
