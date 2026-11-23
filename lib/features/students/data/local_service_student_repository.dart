import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/service_student.dart';

class LocalServiceStudentRepository {
  LocalServiceStudentRepository(this._db, this._queue);

  final AppDatabase _db;
  final SyncQueueRepository _queue;

  Stream<List<ServiceStudent>> watchForService(String serviceId) =>
      (_db.select(_db.cachedServiceStudents)
            ..where((t) => t.serviceId.equals(serviceId))
            ..orderBy([(t) => OrderingTerm(expression: t.enrollmentDate)]))
          .watch()
          .map((rows) => rows.map(_fromRow).toList());

  Future<ServiceStudent?> findById(String membershipId) async {
    final row = await (_db.select(_db.cachedServiceStudents)
          ..where((t) => t.id.equals(membershipId)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> cache(List<ServiceStudent> memberships) async {
    await _db.batch((batch) {
      for (final membership in memberships) {
        batch.insert(
          _db.cachedServiceStudents,
          CachedServiceStudentsCompanion.insert(
            id: membership.id,
            studentId: membership.studentId,
            serviceId: membership.serviceId,
            classId: Value(membership.classId),
            proposedClassId: Value(membership.proposedClassId),
            enrollmentDate: membership.enrollmentDate.toUtc().toIso8601String(),
            status: membership.status,
            school: Value(membership.school),
            grade: Value(membership.grade),
            isDeacon: Value(membership.isDeacon),
            notes: Value(membership.notes),
            studentName: Value(membership.studentName),
            birthDate: Value(membership.birthDate?.toIso8601String()),
            phone: Value(membership.phone),
            photoPath: Value(membership.photoPath),
            identityServiceId: Value(membership.identityServiceId),
            cachedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> saveOffline(ServiceStudent membership) async {
    await cache([membership]);
    await _queue.enqueue(
      SyncOperation(
        // Membership mutations are last-write-wins while still queued.
        // Reusing the membership UUID replaces an earlier pending upsert
        // (for example active -> inactive archive) instead of replaying two
        // writes whose timestamps may be identical on local storage.
        operationId: membership.id,
        entityType: 'service_student',
        operationType: 'upsert',
        payloadJson: jsonEncode(membership.toMap()),
      ),
    );
  }

  Future<void> archiveOffline(ServiceStudent membership) async {
    final archived = ServiceStudent(
      id: membership.id,
      studentId: membership.studentId,
      serviceId: membership.serviceId,
      classId: membership.classId,
      proposedClassId: membership.proposedClassId,
      enrollmentDate: membership.enrollmentDate,
      status: 'inactive',
      school: membership.school,
      grade: membership.grade,
      isDeacon: membership.isDeacon,
      notes: membership.notes,
      studentName: membership.studentName,
      birthDate: membership.birthDate,
      phone: membership.phone,
      photoPath: membership.photoPath,
      identityServiceId: membership.identityServiceId,
    );
    await saveOffline(archived);
  }

  ServiceStudent _fromRow(CachedServiceStudent row) => ServiceStudent(
    id: row.id,
    studentId: row.studentId,
    serviceId: row.serviceId,
    classId: row.classId,
    proposedClassId: row.proposedClassId,
    enrollmentDate: DateTime.parse(row.enrollmentDate).toLocal(),
    status: row.status,
    school: row.school,
    grade: row.grade,
    isDeacon: row.isDeacon,
    notes: row.notes,
    studentName: row.studentName,
    birthDate: row.birthDate == null
        ? null
        : DateTime.tryParse(row.birthDate!),
    phone: row.phone,
    photoPath: row.photoPath,
    identityServiceId: row.identityServiceId,
  );
}
