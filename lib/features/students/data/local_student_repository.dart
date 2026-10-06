import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/student.dart';
import '../domain/repositories/student_repository.dart';

class LocalStudentRepository implements StudentRepository {
  LocalStudentRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) {
    return (_db.select(_db.cachedStudents)
          ..where((t) => t.currentClassId.equals(classId) | t.proposedClassId.equals(classId))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch()
        .map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> cacheStudents(List<Student> students) async {
    await _db.batch((batch) {
      for (final student in students) {
        batch.insert(
          _db.cachedStudents,
          CachedStudentsCompanion.insert(
            id: student.id,
            serviceId: student.serviceId,
            currentClassId: Value(student.currentClassId),
            proposedClassId: Value(student.proposedClassId),
            name: student.name,
            birthDate: Value(student.birthDate?.toIso8601String()),
            phone: Value(student.phone),
            school: Value(student.school),
            grade: Value(student.grade),
            enrollmentAt: Value(student.enrollmentAt?.toIso8601String()),
            approvalStatus: student.approvalStatus,
            photoPath: Value(student.photoPath),
            notes: Value(student.notes),
            cachedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<Student?> findById(String studentId) async {
    final row = await (_db.select(_db.cachedStudents)
          ..where((t) => t.id.equals(studentId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<Student> updateStudent({
    required String studentId,
    required String name,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    String? notes,
  }) async {
    final current = await findById(studentId);
    if (current == null) throw StateError('Student not found locally: $studentId');
    final updated = Student(
      id: current.id,
      serviceId: current.serviceId,
      name: name.trim(),
      approvalStatus: current.approvalStatus,
      currentClassId: current.currentClassId,
      proposedClassId: current.proposedClassId,
      birthDate: birthDate,
      phone: _clean(phone),
      school: _clean(school),
      grade: _clean(grade),
      enrollmentAt: current.enrollmentAt,
      photoPath: current.photoPath,
      notes: _clean(notes),
    );
    await cacheStudents([updated]);
    return updated;
  }

  Future<Student> approvePending(String studentId) async {
    final current = await findById(studentId);
    if (current == null) throw StateError('Student not found locally: $studentId');
    if (!current.isPending || current.proposedClassId == null) {
      throw StateError('Only pending students with a proposed class can be approved.');
    }
    final updated = Student(
      id: current.id,
      serviceId: current.serviceId,
      name: current.name,
      approvalStatus: 'approved',
      currentClassId: current.proposedClassId,
      proposedClassId: null,
      birthDate: current.birthDate,
      phone: current.phone,
      school: current.school,
      grade: current.grade,
      enrollmentAt: current.enrollmentAt,
      photoPath: current.photoPath,
      notes: current.notes,
    );
    await cacheStudents([updated]);
    return updated;
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Student _fromRow(CachedStudent row) => Student(
        id: row.id,
        serviceId: row.serviceId,
        name: row.name,
        approvalStatus: row.approvalStatus,
        currentClassId: row.currentClassId,
        proposedClassId: row.proposedClassId,
        birthDate: _parse(row.birthDate),
        phone: row.phone,
        school: row.school,
        grade: row.grade,
        enrollmentAt: _parse(row.enrollmentAt),
        photoPath: row.photoPath,
        notes: row.notes,
      );

  DateTime? _parse(String? value) =>
      value == null ? null : DateTime.tryParse(value);
}
