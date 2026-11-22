import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';

/// Global identity is cached once in CachedStudents. Service-specific roster
/// projections are keyed by membership ID in CachedServiceStudents.
class LocalStudentRepository {
  LocalStudentRepository(this._db);

  final AppDatabase _db;

  Stream<List<Student>> watchStudentsForClass(String classId) {
    return (_db.select(_db.cachedServiceStudents)
          ..where(
            (t) =>
                (t.classId.equals(classId) | t.proposedClassId.equals(classId)) &
                t.status.isIn(const ['active', 'pending']),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.studentName)]))
        .watch()
        .map((rows) => rows.map(_fromMembershipRow).toList());
  }

  Stream<List<Student>> watchStudentsForService(String serviceId) {
    return (_db.select(_db.cachedServiceStudents)
          ..where(
            (t) =>
                t.serviceId.equals(serviceId) &
                t.status.isIn(const ['active', 'pending']),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.studentName)]))
        .watch()
        .map((rows) => rows.map(_fromMembershipRow).toList());
  }

  Future<void> cacheStudents(List<Student> students) async {
    await _db.batch((batch) {
      for (final student in students) {
        if (student.membershipId == null) {
          // Legacy/test compatibility: rows without a membership ID are kept
          // as read-only legacy projections until a membership refresh occurs.
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
              membershipId: const Value(null),
              identityServiceId: Value(student.identityServiceId ?? student.serviceId),
              membershipStatus: Value(student.membershipStatus),
              cachedAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
          continue;
        }

        batch.insert(
          _db.cachedServiceStudents,
          CachedServiceStudentsCompanion.insert(
            id: student.membershipId!,
            studentId: student.id,
            serviceId: student.serviceId,
            classId: Value(student.currentClassId),
            proposedClassId: Value(student.proposedClassId),
            enrollmentDate: student.enrollmentAt?.toUtc().toIso8601String() ??
                DateTime.now().toUtc().toIso8601String(),
            status: student.membershipStatus,
            school: Value(student.school),
            grade: Value(student.grade),
            isDeacon: Value(student.isDeacon),
            notes: Value(student.notes),
            studentName: Value(student.name),
            birthDate: Value(student.birthDate?.toIso8601String()),
            phone: Value(student.phone),
            photoPath: Value(student.photoPath),
            identityServiceId: Value(student.identityServiceId),
            cachedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );

        final identityOwner = student.identityServiceId ?? student.serviceId;
        final identity = CachedStudentsCompanion.insert(
          id: student.id,
          serviceId: identityOwner,
          currentClassId: const Value(null),
          proposedClassId: const Value(null),
          name: student.name,
          birthDate: Value(student.birthDate?.toIso8601String()),
          phone: Value(student.phone),
          school: const Value(null),
          grade: const Value(null),
          enrollmentAt: const Value(null),
          approvalStatus: 'approved',
          isDeacon: const Value(false),
          photoPath: Value(student.photoPath),
          notes: const Value(null),
          membershipId: const Value(null),
          identityServiceId: Value(identityOwner),
          membershipStatus: const Value('active'),
          cachedAt: DateTime.now(),
        );
        batch.insert(
          _db.cachedStudents,
          identity,
          mode: student.serviceId == identityOwner
              ? InsertMode.insertOrReplace
              : InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Finds the exact membership when [membershipId] is supplied. Without it,
  /// a single cached membership is accepted for legacy callers; ambiguous
  /// multi-service identities are never resolved by guesswork.
  Future<Student?> findById(
    String studentId, {
    String? membershipId,
    String? serviceId,
  }) async {
    if (membershipId != null) {
      final membership = await (_db.select(_db.cachedServiceStudents)
            ..where((t) => t.id.equals(membershipId) & t.studentId.equals(studentId)))
          .getSingleOrNull();
      if (membership != null) return _fromMembershipRow(membership);
    }
    if (serviceId != null) {
      final membership = await (_db.select(_db.cachedServiceStudents)
            ..where((t) => t.studentId.equals(studentId) & t.serviceId.equals(serviceId)))
          .getSingleOrNull();
      if (membership != null) return _fromMembershipRow(membership);
    }
    final memberships = await (_db.select(_db.cachedServiceStudents)
          ..where((t) => t.studentId.equals(studentId)))
        .get();
    if (memberships.length == 1) return _fromMembershipRow(memberships.single);
    if (memberships.length > 1) return null;

    final identity = await (_db.select(_db.cachedStudents)
          ..where((t) => t.id.equals(studentId)))
        .getSingleOrNull();
    return identity == null ? null : _fromRow(identity);
  }

  /// Archive a service membership locally; global identity and history remain.
  Future<void> archiveMembership(
    String studentId, {
    String? membershipId,
  }) async {
    final current = await findById(studentId, membershipId: membershipId);
    if (current == null || current.membershipId == null) return;
    await (_db.update(_db.cachedServiceStudents)
          ..where((t) => t.id.equals(current.membershipId!)))
        .write(
          CachedServiceStudentsCompanion(
            status: const Value('inactive'),
            cachedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<Student> assignClass(
    String studentId,
    String classId, {
    String? membershipId,
  }) async {
    final current = await findById(studentId, membershipId: membershipId);
    if (current == null) {
      throw StateError('Student membership not found locally: $studentId');
    }
    final updated = current.copyWith(
      currentClassId: current.isApproved ? classId : current.currentClassId,
      proposedClassId: current.isPending ? classId : current.proposedClassId,
    );
    await cacheStudents([updated]);
    return updated;
  }

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
    bool updateGlobalIdentity = true,
  }) async {
    final current = await findById(studentId, membershipId: membershipId);
    if (current == null) {
      throw StateError('Student membership not found locally: $studentId');
    }
    final updated = current.copyWith(
      name: updateGlobalIdentity ? name.trim() : current.name,
      birthDate: updateGlobalIdentity ? birthDate : current.birthDate,
      phone: updateGlobalIdentity ? _clean(phone) : current.phone,
      school: _clean(school),
      grade: _clean(grade),
      isDeacon: isDeacon ?? current.isDeacon,
      enrollmentAt: enrollmentAt ?? current.enrollmentAt,
      photoPath: updateGlobalIdentity ? _clean(photoPath) : current.photoPath,
      notes: _clean(notes),
    );
    await cacheStudents([updated]);
    return updated;
  }

  Future<Student> approvePending(
    String studentId, {
    String? membershipId,
  }) async {
    final current = await findById(studentId, membershipId: membershipId);
    if (current == null) {
      throw StateError('Student membership not found locally: $studentId');
    }
    if (!current.isPending || current.proposedClassId == null) {
      throw StateError(
        'Only pending memberships with a proposed class can be approved.',
      );
    }
    final updated = current.copyWith(
      approvalStatus: 'approved',
      membershipStatus: 'active',
      currentClassId: current.proposedClassId,
      proposedClassId: null,
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
    final row = await (_db.select(_db.cachedStudentSensitiveData)
          ..where((t) => t.studentId.equals(studentId)))
        .getSingleOrNull();
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

  Student _fromMembershipRow(CachedServiceStudent row) {
    final status = row.status;
    return Student(
      id: row.studentId,
      membershipId: row.id,
      identityServiceId: row.identityServiceId,
      serviceId: row.serviceId,
      name: row.studentName,
      approvalStatus: status == 'pending' ? 'pending' : 'approved',
      membershipStatus: status,
      currentClassId: row.classId,
      proposedClassId: row.proposedClassId,
      birthDate: _parse(row.birthDate),
      phone: row.phone,
      school: row.school,
      grade: row.grade,
      isDeacon: row.isDeacon,
      enrollmentAt: _parse(row.enrollmentDate),
      photoPath: row.photoPath,
      notes: row.notes,
    );
  }

  Student _fromRow(CachedStudent row) => Student(
    id: row.id,
    serviceId: row.serviceId,
    name: row.name,
    approvalStatus: row.approvalStatus,
    membershipId: row.membershipId,
    identityServiceId: row.identityServiceId ?? row.serviceId,
    membershipStatus: row.membershipStatus,
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
