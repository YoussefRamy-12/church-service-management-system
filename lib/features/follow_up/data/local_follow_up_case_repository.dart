import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/activity_type.dart';
import '../domain/entities/case_assignment.dart';
import '../domain/entities/case_priority.dart';
import '../domain/entities/case_status.dart';
import '../domain/entities/follow_up_activity.dart';
import '../domain/entities/follow_up_case.dart';
import '../domain/repositories/follow_up_case_repository.dart';

class LocalFollowUpCaseRepository implements FollowUpCaseRepository {
  LocalFollowUpCaseRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<FollowUpCase>> watchCasesForScope({
    required String serviceId,
    Set<String>? classIds,
    String? studentId,
  }) {
    final query = _db.select(_db.cachedFollowUpCases)
      ..where((c) => c.serviceId.equals(serviceId));

    if (classIds != null) {
      query.where((c) => c.classId.isIn(classIds));
    }
    if (studentId != null) {
      query.where((c) => c.studentId.equals(studentId));
    }

    query.orderBy([
      (c) => OrderingTerm(expression: c.updatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch().asyncMap((rows) async {
      final cases = <FollowUpCase>[];
      for (final r in rows) {
        cases.add(await _enrichCase(r));
      }
      return cases;
    });
  }

  @override
  Future<FollowUpCase?> getCaseById(String caseId) async {
    final row = await (_db.select(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .getSingleOrNull();

    if (row == null) return null;
    return _enrichCase(row);
  }

  @override
  Future<FollowUpCase> createCase({
    required String serviceId,
    required String studentId,
    required String classId,
    required String title,
    String? description,
    required CasePriority priority,
    required String createdBy,
    String caseType = 'general',
    List<String> initialServantIds = const [],
  }) async {
    final id = _uuid.v4();
    final clientOpId = _uuid.v4();
    final now = DateTime.now();

    final initialStatus = initialServantIds.isNotEmpty
        ? CaseStatus.assigned
        : CaseStatus.open;

    await _db.into(_db.cachedFollowUpCases).insert(
          CachedFollowUpCasesCompanion.insert(
            id: id,
            serviceId: serviceId,
            studentId: studentId,
            classId: classId,
            title: title,
            description: Value(description),
            priority: priority.value,
            status: initialStatus.value,
            caseType: Value(caseType),
            createdBy: createdBy,
            createdAt: now,
            updatedAt: now,
            clientOperationId: clientOpId,
            cachedAt: now,
          ),
        );

    // Initial Assignments
    for (final servantId in initialServantIds) {
      final assignmentId = _uuid.v4();
      final assignmentOpId = _uuid.v4();
      await _db.into(_db.cachedFollowUpCaseAssignments).insert(
            CachedFollowUpCaseAssignmentsCompanion.insert(
              id: assignmentId,
              caseId: id,
              servantId: servantId,
              assignedBy: createdBy,
              assignedAt: now,
              assignmentStatus: const Value('active'),
              clientOperationId: assignmentOpId,
              cachedAt: now,
            ),
          );
    }

    // Initial Activity
    final activityId = _uuid.v4();
    final activityOpId = _uuid.v4();
    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    await _db.into(_db.cachedFollowUpActivities).insert(
          CachedFollowUpActivitiesCompanion.insert(
            id: activityId,
            caseId: id,
            activityType: ActivityType.note.value,
            description: 'تم فتح حالة المتابعة: $title',
            createdBy: createdBy,
            createdAt: now,
            activityDate: dateStr,
            clientOperationId: activityOpId,
            cachedAt: now,
          ),
        );

    final createdRow = await (_db.select(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(id)))
        .getSingle();

    return _enrichCase(createdRow);
  }

  @override
  Future<FollowUpCase> updateCaseStatus({
    required String caseId,
    required CaseStatus newStatus,
    required String actorId,
    required String actorRole,
    String? note,
  }) async {
    final now = DateTime.now();
    DateTime? resolvedAt;
    DateTime? closedAt;

    if (newStatus == CaseStatus.resolved) {
      resolvedAt = now;
    } else if (newStatus == CaseStatus.closed) {
      closedAt = now;
    }

    await (_db.update(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .write(
      CachedFollowUpCasesCompanion(
        status: Value(newStatus.value),
        updatedAt: Value(now),
        resolvedAt: Value(resolvedAt),
        closedAt: Value(closedAt),
        cachedAt: Value(now),
      ),
    );

    // Record traceable activity for status transition
    final dateStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final description = note?.trim().isNotEmpty == true
        ? 'تغيير الحالة إلى ${newStatus.arabicLabel}: ${note!.trim()}'
        : 'تم تغيير حالة المتابعة إلى "${newStatus.arabicLabel}"';

    await _db.into(_db.cachedFollowUpActivities).insert(
          CachedFollowUpActivitiesCompanion.insert(
            id: _uuid.v4(),
            caseId: caseId,
            activityType: ActivityType.statusChange.value,
            description: description,
            createdBy: actorId,
            createdAt: now,
            activityDate: dateStr,
            clientOperationId: _uuid.v4(),
            cachedAt: now,
          ),
        );

    final updatedRow = await (_db.select(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .getSingle();

    return _enrichCase(updatedRow);
  }

  @override
  Future<FollowUpCase> updateCasePriority({
    required String caseId,
    required CasePriority newPriority,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .write(
      CachedFollowUpCasesCompanion(
        priority: Value(newPriority.value),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );

    final row = await (_db.select(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .getSingle();
    return _enrichCase(row);
  }

  @override
  Future<FollowUpCase> updateCaseDetails({
    required String caseId,
    required String title,
    String? description,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .write(
      CachedFollowUpCasesCompanion(
        title: Value(title),
        description: Value(description),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );

    final row = await (_db.select(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .getSingle();
    return _enrichCase(row);
  }

  @override
  Stream<List<CaseAssignment>> watchAssignmentsForCase(String caseId) {
    return (_db.select(_db.cachedFollowUpCaseAssignments)
          ..where((a) => a.caseId.equals(caseId))
          ..orderBy([
            (a) => OrderingTerm(
                  expression: a.assignedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch()
        .asyncMap((rows) async {
      final list = <CaseAssignment>[];
      for (final r in rows) {
        final profile = await (_db.select(_db.cachedProfiles)
              ..where((p) => p.id.equals(r.servantId)))
            .getSingleOrNull();

        final assigner = await (_db.select(_db.cachedProfiles)
              ..where((p) => p.id.equals(r.assignedBy)))
            .getSingleOrNull();

        list.add(
          CaseAssignment(
            id: r.id,
            caseId: r.caseId,
            servantId: r.servantId,
            assignedBy: r.assignedBy,
            assignedAt: r.assignedAt,
            assignmentStatus: r.assignmentStatus,
            removedAt: r.removedAt,
            clientOperationId: r.clientOperationId,
            servantName: profile?.name,
            servantRole: profile?.role,
            assignedByName: assigner?.name,
          ),
        );
      }
      return list;
    });
  }

  @override
  Future<void> assignServants({
    required String caseId,
    required List<String> servantIds,
    required String assignedBy,
  }) async {
    final now = DateTime.now();
    final names = <String>[];

    for (final sId in servantIds) {
      // Check if already active
      final existing = await (_db.select(_db.cachedFollowUpCaseAssignments)
            ..where((a) =>
                a.caseId.equals(caseId) &
                a.servantId.equals(sId) &
                a.assignmentStatus.equals('active')))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.cachedFollowUpCaseAssignments).insert(
              CachedFollowUpCaseAssignmentsCompanion.insert(
                id: _uuid.v4(),
                caseId: caseId,
                servantId: sId,
                assignedBy: assignedBy,
                assignedAt: now,
                assignmentStatus: const Value('active'),
                clientOperationId: _uuid.v4(),
                cachedAt: now,
              ),
            );

        final profile = await (_db.select(_db.cachedProfiles)
              ..where((p) => p.id.equals(sId)))
            .getSingleOrNull();
        if (profile != null) names.add(profile.name);
      }
    }

    if (names.isNotEmpty) {
      // If case was open, move to assigned
      final currentCase = await (_db.select(_db.cachedFollowUpCases)
            ..where((c) => c.id.equals(caseId)))
          .getSingle();

      if (currentCase.status == CaseStatus.open.value) {
        await (_db.update(_db.cachedFollowUpCases)
              ..where((c) => c.id.equals(caseId)))
            .write(
          CachedFollowUpCasesCompanion(
            status: Value(CaseStatus.assigned.value),
            updatedAt: Value(now),
            cachedAt: Value(now),
          ),
        );
      }

      final dateStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      await _db.into(_db.cachedFollowUpActivities).insert(
            CachedFollowUpActivitiesCompanion.insert(
              id: _uuid.v4(),
              caseId: caseId,
              activityType: ActivityType.assignmentChange.value,
              description: 'تم تكليف الخدام: ${names.join('، ')}',
              createdBy: assignedBy,
              createdAt: now,
              activityDate: dateStr,
              clientOperationId: _uuid.v4(),
              cachedAt: now,
            ),
          );
    }
  }

  @override
  Future<void> removeAssignment({
    required String assignmentId,
    required String caseId,
    required String removedBy,
  }) async {
    final now = DateTime.now();
    final assignment = await (_db.select(_db.cachedFollowUpCaseAssignments)
          ..where((a) => a.id.equals(assignmentId)))
        .getSingleOrNull();

    if (assignment != null) {
      await (_db.update(_db.cachedFollowUpCaseAssignments)
            ..where((a) => a.id.equals(assignmentId)))
          .write(
        CachedFollowUpCaseAssignmentsCompanion(
          assignmentStatus: const Value('removed'),
          removedAt: Value(now),
          cachedAt: Value(now),
        ),
      );

      final profile = await (_db.select(_db.cachedProfiles)
            ..where((p) => p.id.equals(assignment.servantId)))
          .getSingleOrNull();

      final servantName = profile?.name ?? 'خادم';
      final dateStr =
          "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      await _db.into(_db.cachedFollowUpActivities).insert(
            CachedFollowUpActivitiesCompanion.insert(
              id: _uuid.v4(),
              caseId: caseId,
              activityType: ActivityType.assignmentChange.value,
              description: 'تم إلغاء تكليف: $servantName',
              createdBy: removedBy,
              createdAt: now,
              activityDate: dateStr,
              clientOperationId: _uuid.v4(),
              cachedAt: now,
            ),
          );
    }
  }

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForCase(String caseId) {
    return (_db.select(_db.cachedFollowUpActivities)
          ..where((a) => a.caseId.equals(caseId))
          ..orderBy([
            (a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .asyncMap((rows) async {
      final list = <FollowUpActivity>[];
      for (final r in rows) {
        list.add(await _enrichActivity(r));
      }
      return list;
    });
  }

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForScope({
    required String serviceId,
    Set<String>? classIds,
    int limit = 50,
  }) {
    if (classIds != null && classIds.isEmpty) {
      return Stream.value(const <FollowUpActivity>[]);
    }

    // Join both tables so activity inserts trigger this stream even when the
    // parent case status does not change (for example, an activity on an
    // already in-progress case).
    final query = _db.select(_db.cachedFollowUpActivities).join([
      innerJoin(
        _db.cachedFollowUpCases,
        _db.cachedFollowUpCases.id.equalsExp(
          _db.cachedFollowUpActivities.caseId,
        ),
      ),
    ])
      ..where(_db.cachedFollowUpCases.serviceId.equals(serviceId));

    if (classIds != null) {
      query.where(_db.cachedFollowUpCases.classId.isIn(classIds));
    }

    query
      ..orderBy([
        OrderingTerm(
          expression: _db.cachedFollowUpActivities.createdAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(limit);

    return query.watch().asyncMap((rows) async {
      final list = <FollowUpActivity>[];
      for (final row in rows) {
        final activity = row.readTable(_db.cachedFollowUpActivities);
        final parentCase = row.readTable(_db.cachedFollowUpCases);
        list.add(await _enrichActivity(activity, parentCase: parentCase));
      }
      return list;
    });
  }

  @override
  Stream<List<FollowUpActivity>> watchActivitiesForStudent(String studentId) {
    final query = _db.select(_db.cachedFollowUpActivities).join([
      innerJoin(
        _db.cachedFollowUpCases,
        _db.cachedFollowUpCases.id.equalsExp(
          _db.cachedFollowUpActivities.caseId,
        ),
      ),
    ])..where(_db.cachedFollowUpCases.studentId.equals(studentId));

    query.orderBy([
      OrderingTerm(
        expression: _db.cachedFollowUpActivities.createdAt,
        mode: OrderingMode.desc,
      ),
    ]);

    return query.watch().asyncMap((rows) async {
      final list = <FollowUpActivity>[];
      for (final row in rows) {
        final activity = row.readTable(_db.cachedFollowUpActivities);
        final parentCase = row.readTable(_db.cachedFollowUpCases);
        list.add(await _enrichActivity(activity, parentCase: parentCase));
      }
      return list;
    });
  }

  @override
  Future<FollowUpActivity> recordActivity({
    required String caseId,
    required ActivityType activityType,
    required String description,
    required String createdBy,
    required String activityDate,
  }) async {
    final id = _uuid.v4();
    final clientOpId = _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.cachedFollowUpActivities).insert(
          CachedFollowUpActivitiesCompanion.insert(
            id: id,
            caseId: caseId,
            activityType: activityType.value,
            description: description,
            createdBy: createdBy,
            createdAt: now,
            activityDate: activityDate,
            clientOperationId: clientOpId,
            cachedAt: now,
          ),
        );

    // Update parent case's updatedAt and transition to inProgress if currently open/assigned
    final currentCase = await (_db.select(_db.cachedFollowUpCases)
          ..where((c) => c.id.equals(caseId)))
        .getSingleOrNull();

    if (currentCase != null) {
      final shouldAdvance = currentCase.status == CaseStatus.open.value ||
          currentCase.status == CaseStatus.assigned.value;

      await (_db.update(_db.cachedFollowUpCases)
            ..where((c) => c.id.equals(caseId)))
          .write(
        CachedFollowUpCasesCompanion(
          status: shouldAdvance
              ? Value(CaseStatus.inProgress.value)
              : Value(currentCase.status),
          updatedAt: Value(now),
          cachedAt: Value(now),
        ),
      );
    }

    final row = await (_db.select(_db.cachedFollowUpActivities)
          ..where((a) => a.id.equals(id)))
        .getSingle();

    return _enrichActivity(row);
  }

  // --- Helpers for Joining Metadata ---

  Future<FollowUpCase> _enrichCase(CachedFollowUpCase r) async {
    final student = await (_db.select(_db.cachedStudents)
          ..where((s) => s.id.equals(r.studentId)))
        .getSingleOrNull();

    final classRow = await (_db.select(_db.cachedClasses)
          ..where((c) => c.id.equals(r.classId)))
        .getSingleOrNull();

    final creator = await (_db.select(_db.cachedProfiles)
          ..where((p) => p.id.equals(r.createdBy)))
        .getSingleOrNull();

    // Active assignments
    final assignments = await (_db.select(_db.cachedFollowUpCaseAssignments)
          ..where((a) =>
              a.caseId.equals(r.id) & a.assignmentStatus.equals('active')))
        .get();

    final servantNames = <String>[];
    for (final a in assignments) {
      final profile = await (_db.select(_db.cachedProfiles)
            ..where((p) => p.id.equals(a.servantId)))
          .getSingleOrNull();
      if (profile != null) servantNames.add(profile.name);
    }

    // Latest activity
    final latestAct = await (_db.select(_db.cachedFollowUpActivities)
          ..where((a) => a.caseId.equals(r.id))
          ..orderBy([
            (a) => OrderingTerm(
                  expression: a.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .getSingleOrNull();

    String? latestAuthorName;
    if (latestAct != null) {
      final author = await (_db.select(_db.cachedProfiles)
            ..where((p) => p.id.equals(latestAct.createdBy)))
          .getSingleOrNull();
      latestAuthorName = author?.name;
    }

    return FollowUpCase(
      id: r.id,
      serviceId: r.serviceId,
      studentId: r.studentId,
      classId: r.classId,
      title: r.title,
      description: r.description,
      priority: CasePriority.fromString(r.priority),
      status: CaseStatus.fromString(r.status),
      caseType: r.caseType,
      createdBy: r.createdBy,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      resolvedAt: r.resolvedAt,
      closedAt: r.closedAt,
      clientOperationId: r.clientOperationId,
      studentName: student?.name,
      className: classRow?.name,
      creatorName: creator?.name,
      assignedServantCount: assignments.length,
      assignedServantNames: servantNames,
      latestActivityDate: latestAct?.activityDate,
      latestActivityAuthorName: latestAuthorName,
    );
  }

  Future<FollowUpActivity> _enrichActivity(
    CachedFollowUpActivity r, {
    CachedFollowUpCase? parentCase,
  }) async {
    final author = await (_db.select(_db.cachedProfiles)
          ..where((p) => p.id.equals(r.createdBy)))
        .getSingleOrNull();

    final theCase = parentCase ??
        await (_db.select(_db.cachedFollowUpCases)
              ..where((c) => c.id.equals(r.caseId)))
            .getSingleOrNull();

    String? studentName;
    if (theCase != null) {
      final student = await (_db.select(_db.cachedStudents)
            ..where((s) => s.id.equals(theCase.studentId)))
          .getSingleOrNull();
      studentName = student?.name;
    }

    return FollowUpActivity(
      id: r.id,
      caseId: r.caseId,
      activityType: ActivityType.fromString(r.activityType),
      description: r.description,
      createdBy: r.createdBy,
      createdAt: r.createdAt,
      activityDate: r.activityDate,
      clientOperationId: r.clientOperationId,
      authorName: author?.name,
      authorRole: author?.role,
      studentName: studentName,
      caseTitle: theCase?.title,
    );
  }
}

