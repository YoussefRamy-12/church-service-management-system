import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/reports/data/local_report_repository.dart';

void main() {
  late AppDatabase db;
  late LocalReportRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalReportRepository(db);
  });

  tearDown(() async => db.close());

  Future<void> seedBaseData() async {
    await db.batch((batch) {
      batch.insert(
        db.cachedClasses,
        CachedClassesCompanion.insert(
          id: 'class-1',
          stageId: 'stage-1',
          name: 'Class 1',
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      batch.insert(
        db.cachedStudents,
        CachedStudentsCompanion.insert(
          id: 'student-1',
          serviceId: 'service-1',
          name: 'Peter',
          approvalStatus: 'approved',
          currentClassId: const Value('class-1'),
          enrollmentAt: const Value('2026-09-01'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      batch.insert(
        db.cachedStudents,
        CachedStudentsCompanion.insert(
          id: 'student-2',
          serviceId: 'service-1',
          name: 'Mark',
          approvalStatus: 'approved',
          currentClassId: const Value('class-1'),
          enrollmentAt: const Value('2026-10-10'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      batch.insert(
        db.cachedMeetings,
        CachedMeetingsCompanion.insert(
          id: 'meeting-1',
          serviceId: 'service-1',
          meetingDate: '2026-10-05',
          startTime: '10:00:00',
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      batch.insert(
        db.cachedMeetings,
        CachedMeetingsCompanion.insert(
          id: 'meeting-2',
          serviceId: 'service-1',
          meetingDate: '2026-10-12',
          startTime: '10:00:00',
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
    });
  }

  test('report counts expected attendance only after enrollment', () async {
    await seedBaseData();

    final report = await repo.fetch(
      serviceId: 'service-1',
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
    );

    expect(report.students, 2);
    expect(report.meetings, 2);
    expect(report.expectedAttendance, 3);
    expect(report.present, 0);
  });

  test('report separates early and normal attendance', () async {
    await seedBaseData();

    await db.into(db.cachedAttendanceRecords).insert(
      CachedAttendanceRecordsCompanion.insert(
        id: 'attendance-1',
        meetingId: 'meeting-1',
        studentId: 'student-1',
        classIdAtAttendance: 'class-1',
        checkedInAt: DateTime(2026, 10, 5, 10, 10),
        recordedBy: 'servant-1',
        clientOperationId: 'op-1',
        syncState: const Value('synced'),
      ),
    );
    await db.into(db.cachedAttendanceRecords).insert(
      CachedAttendanceRecordsCompanion.insert(
        id: 'attendance-2',
        meetingId: 'meeting-2',
        studentId: 'student-1',
        classIdAtAttendance: 'class-1',
        checkedInAt: DateTime(2026, 10, 12, 10, 20),
        recordedBy: 'servant-1',
        clientOperationId: 'op-2',
        syncState: const Value('synced'),
      ),
    );

    final report = await repo.fetch(
      serviceId: 'service-1',
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
    );

    expect(report.present, 2);
    expect(report.early, 1);
    expect(report.normal, 1);
    expect(report.attendancePercentage, closeTo(66.6667, 0.01));
  });

  test('report can scope students by class', () async {
    await seedBaseData();

    await db.into(db.cachedClasses).insert(
      CachedClassesCompanion.insert(
        id: 'class-2',
        stageId: 'stage-1',
        name: 'Class 2',
        cachedAt: DateTime(2026, 10, 1),
      ),
    );
    await db.into(db.cachedStudents).insert(
      CachedStudentsCompanion.insert(
        id: 'student-3',
        serviceId: 'service-1',
        name: 'John',
        approvalStatus: 'approved',
        currentClassId: const Value('class-2'),
        enrollmentAt: const Value('2026-09-01'),
        cachedAt: DateTime(2026, 10, 1),
      ),
    );

    final report = await repo.fetch(
      serviceId: 'service-1',
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
      classIds: {'class-2'},
    );

    expect(report.students, 1);
    expect(report.expectedAttendance, 2);
  });

  test('report counts follow-ups only for scoped students and period', () async {
    await seedBaseData();

    await db.into(db.cachedFollowUpRecords).insert(
      CachedFollowUpRecordsCompanion.insert(
        id: 'follow-1',
        studentId: 'student-1',
        createdBy: 'servant-1',
        followUpDate: '2026-10-07',
        contactStatus: 'contacted',
        clientOperationId: 'op-follow-1',
        cachedAt: DateTime(2026, 10, 7),
      ),
    );
    await db.into(db.cachedFollowUpRecords).insert(
      CachedFollowUpRecordsCompanion.insert(
        id: 'follow-2',
        studentId: 'student-1',
        createdBy: 'servant-1',
        followUpDate: '2026-11-01',
        contactStatus: 'contacted',
        clientOperationId: 'op-follow-2',
        cachedAt: DateTime(2026, 11, 1),
      ),
    );

    final report = await repo.fetch(
      serviceId: 'service-1',
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
    );

    expect(report.followUps, 1);
  });

  test('report counts duplicate attendance for one student and meeting once', () async {
    await seedBaseData();

    await db.batch((batch) {
      batch.insert(
        db.cachedAttendanceRecords,
        CachedAttendanceRecordsCompanion.insert(
          id: 'attendance-duplicate-1',
          meetingId: 'meeting-1',
          studentId: 'student-1',
          classIdAtAttendance: 'class-1',
          checkedInAt: DateTime(2026, 10, 5, 10, 10),
          recordedBy: 'servant-1',
          clientOperationId: 'op-duplicate-1',
          syncState: const Value('synced'),
        ),
      );
      batch.insert(
        db.cachedAttendanceRecords,
        CachedAttendanceRecordsCompanion.insert(
          id: 'attendance-duplicate-2',
          meetingId: 'meeting-1',
          studentId: 'student-1',
          classIdAtAttendance: 'class-1',
          checkedInAt: DateTime(2026, 10, 5, 10, 11),
          recordedBy: 'servant-1',
          clientOperationId: 'op-duplicate-2',
          syncState: const Value('synced'),
        ),
      );
    });

    final report = await repo.fetch(
      serviceId: 'service-1',
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 31),
    );

    expect(report.present, 1);
    expect(report.early, 1);
    expect(report.normal, 0);
  });

}
