import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';

class LocalStudentRepository {
  LocalStudentRepository(this._db);

  final AppDatabase _db;

  Stream<List<Student>> watchStudentsForClass(String classId) {
    return (_db.select(_db.cachedStudents)
          ..where(
            (t) =>
                t.currentClassId.equals(classId) |
                t.proposedClassId.equals(classId),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch()
        .map((rows) => rows.map(_fromRow).toList());
  }

  Stream<List<Student>> watchStudentsForService(String serviceId) {
    return (_db.select(_db.cachedStudents)
          ..where((t) => t.serviceId.equals(serviceId))
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
            isDeacon: Value(student.isDeacon),
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
    final row = await (_db.select(
      _db.cachedStudents,
    )..where((t) => t.id.equals(studentId))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> deleteStudent(String studentId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.cachedAttendanceRecords)
            ..where((t) => t.studentId.equals(studentId)))
          .go();
      await (_db.delete(_db.cachedFollowUpRecords)
            ..where((t) => t.studentId.equals(studentId)))
          .go();
      await (_db.delete(_db.cachedStudentSensitiveData)
            ..where((t) => t.studentId.equals(studentId)))
          .go();
      await (_db.delete(
        _db.cachedStudents,
      )..where((t) => t.id.equals(studentId))).go();
    });
  }

  Future<Student> assignClass(String studentId, String classId) async {
    final current = await findById(studentId);
    if (current == null) {
      throw StateError('Student not found locally: $studentId');
    }
    final updated = Student(
      id: current.id,
      serviceId: current.serviceId,
      name: current.name,
      approvalStatus: current.approvalStatus,
      currentClassId: current.isApproved ? classId : current.currentClassId,
      proposedClassId: current.isPending ? classId : current.proposedClassId,
      birthDate: current.birthDate,
      phone: current.phone,
      school: current.school,
      grade: current.grade,
      isDeacon: current.isDeacon,
      enrollmentAt: current.enrollmentAt,
      photoPath: current.photoPath,
      notes: current.notes,
    );
    await cacheStudents([updated]);
    return updated;
  }

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
  }) async {
    final current = await findById(studentId);
    if (current == null) {
      throw StateError('Student not found locally: $studentId');
    }
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
      isDeacon: isDeacon ?? current.isDeacon,
      enrollmentAt: enrollmentAt,
      photoPath: _clean(photoPath),
      notes: _clean(notes),
    );
    await cacheStudents([updated]);
    return updated;
  }

  Future<Student> approvePending(String studentId) async {
    final current = await findById(studentId);
    if (current == null) {
      throw StateError('Student not found locally: $studentId');
    }
    if (!current.isPending || current.proposedClassId == null) {
      throw StateError(
        'Only pending students with a proposed class can be approved.',
      );
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
      isDeacon: current.isDeacon,
      enrollmentAt: current.enrollmentAt,
      photoPath: current.photoPath,
      notes: current.notes,
    );
    await cacheStudents([updated]);
    return updated;
  }

  // --- Sensitive Data Local Cache ---

  Future<void> cacheSensitiveData(SensitiveStudentData data) async {
    await _db
        .into(_db.cachedStudentSensitiveData)
        .insertOnConflictUpdate(
          CachedStudentSensitiveDataCompanion.insert(
            studentId: data.studentId,
            fatherJob: Value(data.fatherJob),
            fatherPhone: Value(data.effectiveFatherPhone),
            motherName: Value(data.motherName),
            motherJob: Value(data.motherJob),
            motherPhone: Value(data.effectiveMotherPhone),
            familySize: Value(data.familySize),
            birthOrder: Value(data.birthOrder),
            confessor: Value(data.confessor),
            medicalNotes: Value(data.medicalNotes),
            financialStatus: Value(data.financialStatus),
            address: Value(
              data.address ??
                  (data.fullAddress.isNotEmpty ? data.fullAddress : null),
            ),
            addressBuilding: Value(data.addressBuilding),
            addressStreet: Value(data.addressStreet),
            addressFloor: Value(data.addressFloor),
            addressApartment: Value(data.addressApartment),
            confidentialNotes: Value(data.confidentialNotes),
            studyYear: Value(data.studyYear),
            cachedAt: DateTime.now(),
          ),
        );
  }

  Future<SensitiveStudentData?> findSensitiveData(String studentId) async {
    final row = await (_db.select(
      _db.cachedStudentSensitiveData,
    )..where((t) => t.studentId.equals(studentId))).getSingleOrNull();
    if (row == null) return null;
    return SensitiveStudentData(
      studentId: row.studentId,
      fatherJob: row.fatherJob,
      fatherPhone: row.fatherPhone,
      motherName: row.motherName,
      motherJob: row.motherJob,
      motherPhone: row.motherPhone,
      familySize: row.familySize,
      birthOrder: row.birthOrder,
      confessor: row.confessor,
      medicalNotes: row.medicalNotes,
      financialStatus: row.financialStatus,
      address: row.address,
      addressBuilding: row.addressBuilding,
      addressStreet: row.addressStreet,
      addressFloor: row.addressFloor,
      addressApartment: row.addressApartment,
      confidentialNotes: row.confidentialNotes,
      studyYear: row.studyYear,
    );
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
    isDeacon: row.isDeacon,
    enrollmentAt: _parse(row.enrollmentAt),
    photoPath: row.photoPath,
    notes: row.notes,
  );

  DateTime? _parse(String? value) =>
      value == null ? null : DateTime.tryParse(value);
}
