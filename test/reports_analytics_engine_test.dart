import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/features/reports/data/local_report_repository.dart';
import 'package:church_service_management_system/features/reports/domain/service_report.dart';

void main() {
  late AppDatabase db;
  late LocalReportRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalReportRepository(db);
  });

  tearDown(() async => db.close());

  Future<void> seedFullData() async {
    await db.batch((batch) {
      // 1. Service
      batch.insert(
        db.cachedServices,
        CachedServicesCompanion.insert(
          id: 'service-church-1',
          name: 'أسرة تلاميذ المسيح',
          churchName: 'كنيسة العذراء',
          meetingStartTime: '18:00:00|Fri|Weekly|18:00|15',
          cachedAt: DateTime(2026, 10, 1),
        ),
      );

      // 2. Stages
      batch.insert(
        db.cachedStages,
        CachedStagesCompanion.insert(
          id: 'stage-5',
          serviceId: 'service-church-1',
          name: 'مرحلة ٥ ابتدائي',
          cachedAt: DateTime(2026, 10, 1),
        ),
      );

      // 3. Classes
      batch.insert(
        db.cachedClasses,
        CachedClassesCompanion.insert(
          id: 'class-5-1',
          stageId: 'stage-5',
          name: 'فصل 5/1 (مارمرقس)',
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      batch.insert(
        db.cachedClasses,
        CachedClassesCompanion.insert(
          id: 'class-5-2',
          stageId: 'stage-5',
          name: 'فصل 5/2 (مارجرجس)',
          cachedAt: DateTime(2026, 10, 1),
        ),
      );

      // 4. Students
      // Student 1: Enrolled Sept 1, perfect attendance
      batch.insert(
        db.cachedStudents,
        CachedStudentsCompanion.insert(
          id: 'student-1',
          serviceId: 'service-church-1',
          name: 'كيرلس أمير',
          approvalStatus: 'approved',
          currentClassId: const Value('class-5-1'),
          enrollmentAt: const Value('2026-09-01'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      // Student 2: Enrolled Sept 1, absent all 3 meetings (Repeated Absence!)
      batch.insert(
        db.cachedStudents,
        CachedStudentsCompanion.insert(
          id: 'student-2',
          serviceId: 'service-church-1',
          name: 'مينا عادل',
          approvalStatus: 'approved',
          currentClassId: const Value('class-5-1'),
          enrollmentAt: const Value('2026-09-01'),
          phone: const Value('01220000000'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      // Student 3: Enrolled Oct 10 (eligible only for meeting 2 & 3)
      batch.insert(
        db.cachedStudents,
        CachedStudentsCompanion.insert(
          id: 'student-3',
          serviceId: 'service-church-1',
          name: 'بيشوي نادر',
          approvalStatus: 'approved',
          currentClassId: const Value('class-5-2'),
          enrollmentAt: const Value('2026-10-10'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );

      // 5. Meetings (3 completed Fridays)
      batch.insert(
        db.cachedMeetings,
        CachedMeetingsCompanion.insert(
          id: 'meeting-1',
          serviceId: 'service-church-1',
          meetingDate: '2026-10-02',
          startTime: '18:00:00',
          name: const Value('اجتماع الجمعة الأول'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      batch.insert(
        db.cachedMeetings,
        CachedMeetingsCompanion.insert(
          id: 'meeting-2',
          serviceId: 'service-church-1',
          meetingDate: '2026-10-09',
          startTime: '18:00:00',
          name: const Value('اجتماع الجمعة الثاني'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );
      batch.insert(
        db.cachedMeetings,
        CachedMeetingsCompanion.insert(
          id: 'meeting-3',
          serviceId: 'service-church-1',
          meetingDate: '2026-10-16',
          startTime: '18:00:00',
          name: const Value('اجتماع الجمعة الثالث'),
          cachedAt: DateTime(2026, 10, 1),
        ),
      );

      // 6. Attendance records
      // Meeting 1: Student 1 present (18:05 -> early)
      batch.insert(
        db.cachedAttendanceRecords,
        CachedAttendanceRecordsCompanion.insert(
          id: 'att-1',
          meetingId: 'meeting-1',
          studentId: 'student-1',
          classIdAtAttendance: 'class-5-1',
          checkedInAt: DateTime(2026, 10, 2, 18, 5),
          recordedBy: 'servant-1',
          clientOperationId: 'op-1',
          syncState: const Value('synced'),
        ),
      );
      // Meeting 2: Student 1 present (18:25 -> normal)
      batch.insert(
        db.cachedAttendanceRecords,
        CachedAttendanceRecordsCompanion.insert(
          id: 'att-2',
          meetingId: 'meeting-2',
          studentId: 'student-1',
          classIdAtAttendance: 'class-5-1',
          checkedInAt: DateTime(2026, 10, 9, 18, 25),
          recordedBy: 'servant-1',
          clientOperationId: 'op-2',
          syncState: const Value('synced'),
        ),
      );
      // Meeting 3: Student 1 present (17:55 -> before)
      batch.insert(
        db.cachedAttendanceRecords,
        CachedAttendanceRecordsCompanion.insert(
          id: 'att-3',
          meetingId: 'meeting-3',
          studentId: 'student-1',
          classIdAtAttendance: 'class-5-1',
          checkedInAt: DateTime(2026, 10, 16, 17, 55),
          recordedBy: 'servant-1',
          clientOperationId: 'op-3',
          syncState: const Value('synced'),
        ),
      );
      // Meeting 3: Student 3 present (18:02 -> early)
      batch.insert(
        db.cachedAttendanceRecords,
        CachedAttendanceRecordsCompanion.insert(
          id: 'att-4',
          meetingId: 'meeting-3',
          studentId: 'student-3',
          classIdAtAttendance: 'class-5-2',
          checkedInAt: DateTime(2026, 10, 16, 18, 2),
          recordedBy: 'servant-2',
          clientOperationId: 'op-4',
          syncState: const Value('synced'),
        ),
      );

      // 7. Follow-up cases
      batch.insert(
        db.cachedFollowUpCases,
        CachedFollowUpCasesCompanion.insert(
          id: 'case-1',
          serviceId: 'service-church-1',
          studentId: 'student-2',
          classId: 'class-5-1',
          title: 'افتقاد غياب متكرر',
          priority: 'urgent',
          status: 'open',
          createdBy: 'servant-1',
          createdAt: DateTime(2026, 10, 10),
          updatedAt: DateTime(2026, 10, 10),
          clientOperationId: 'op-c1',
          cachedAt: DateTime(2026, 10, 10),
        ),
      );
    });
  }

  group('Reports Analytics Engine Formulas and Queries', () {
    test('accurately calculates weighted attendance rate and respects enrollment', () async {
      await seedFullData();

      final report = await repo.fetch(
        serviceId: 'service-church-1',
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 31),
      );

      expect(report.students, 3);
      expect(report.meetings, 3);
      // Expected: student-1 (3) + student-2 (3) + student-3 (1 meeting on Oct 16 after Oct 10 enrollment) = 7
      expect(report.expectedAttendance, 7);
      // Present: student-1 (3) + student-3 (1) = 4
      expect(report.present, 4);
      expect(report.attendancePercentage, closeTo(57.14, 0.01));
    });

    test('classifies arrival times into before, early, and normal correctly', () async {
      await seedFullData();

      final report = await repo.fetch(
        serviceId: 'service-church-1',
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 31),
      );

      expect(report.before, 1); // att-3 at 17:55
      expect(report.early, 2); // att-1 at 18:05, att-4 at 18:02
      expect(report.normal, 1); // att-2 at 18:25
      expect(report.earlyRate, 75.0); // (2 early + 1 before) / 4 present * 100
      expect(report.normalRate, 25.0);
    });

    test('detects repeated absences (consecutive missed meetings)', () async {
      await seedFullData();

      final report = await repo.fetch(
        serviceId: 'service-church-1',
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 31),
      );

      expect(report.repeatedAbsences, isNotEmpty);
      final severe = report.repeatedAbsences.firstWhere((r) => r.studentId == 'student-2');
      expect(severe.studentName, 'مينا عادل');
      expect(severe.consecutiveMissedMeetings, 3);
      expect(severe.className, contains('5/1'));
      expect(severe.phone, '01220000000');
    });

    test('generates deterministic actionable insights', () async {
      await seedFullData();

      final report = await repo.fetch(
        serviceId: 'service-church-1',
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 31),
      );

      expect(report.actionableInsights, isNotEmpty);
      expect(
        report.actionableInsights.any((i) => i.id == 'severe-absences'),
        isTrue,
      );
    });

    test('compares classes accurately with drilldown metrics', () async {
      await seedFullData();

      final report = await repo.fetch(
        serviceId: 'service-church-1',
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 31),
      );

      expect(report.classComparisons.length, 2);

      final class1 = report.classComparisons.firstWhere((c) => c.classId == 'class-5-1');
      // Class 5/1: students = 2, expected = 6, present = 3 -> 50%
      expect(class1.totalStudents, 2);
      expect(class1.expectedAttendance, 6);
      expect(class1.presentCount, 3);
      expect(class1.attendanceRate, 50.0);
      expect(class1.repeatedAbsencesCount, 1);
      expect(class1.openCasesCount, 1);
    });

    test('handles zero expected attendance without division by zero', () {
      const report = ServiceReport(
        students: 0,
        meetings: 0,
        expectedAttendance: 0,
        present: 0,
        early: 0,
        normal: 0,
        followUps: 0,
      );

      expect(report.attendancePercentage, 0.0);
      expect(report.absencePercentage, 100.0);
      expect(report.earlyRate, 0.0);
      expect(report.normalRate, 0.0);
      expect(report.absentCount, 0);
    });
  });
}
