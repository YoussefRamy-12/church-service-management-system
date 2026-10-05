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
