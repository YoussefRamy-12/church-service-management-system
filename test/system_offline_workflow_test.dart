import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_engine.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';
import 'package:church_service_management_system/features/attendance/data/local_attendance_repository.dart';
import 'package:church_service_management_system/features/attendance/data/offline_first_attendance_repository.dart';
import 'package:church_service_management_system/features/follow_up/data/local_follow_up_repository.dart';
import 'package:church_service_management_system/features/follow_up/data/offline_first_follow_up_repository.dart';
import 'package:church_service_management_system/features/students/data/local_student_repository.dart';
import 'package:church_service_management_system/features/students/data/offline_first_student_repository.dart';
import 'package:church_service_management_system/features/students/data/supabase_student_repository.dart';
import 'package:church_service_management_system/features/students/domain/entities/student.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoopTransport implements SyncTransport {
  @override
  Future<void> apply(
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) async {}
}

Student _student() => Student(
      id: 'student-1',
      serviceId: 'service-1',
      currentClassId: 'class-1',
      name: 'Peter',
      approvalStatus: 'approved',
      birthDate: DateTime(2014, 5, 10),
      enrollmentAt: DateTime(2026, 9, 1),
    );

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late OfflineFirstStudentRepository students;
  late OfflineFirstAttendanceRepository attendance;
  late OfflineFirstFollowUpRepository followUp;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);

    students = OfflineFirstStudentRepository(
      local: LocalStudentRepository(db),
      remote: SupabaseStudentRepository(
        SupabaseClient('https://example.supabase.co', 'test-key'),
      ),
      queue: queue,
    );

    attendance = OfflineFirstAttendanceRepository(
      local: LocalAttendanceRepository(db),
      queue: queue,
    );

    followUp = OfflineFirstFollowUpRepository(
      local: LocalFollowUpRepository(db),
      queue: queue,
    );
  });

  tearDown(() async => db.close());

  test('attendance, student update, and follow-up share one offline queue safely',
      () async {
    await students.local.cacheStudents([_student()]);

    final attendanceRecord = await attendance.checkIn(
      meetingId: 'meeting-1',
      studentId: 'student-1',
      classIdAtAttendance: 'class-1',
      recordedBy: 'servant-1',
      checkedInAt: DateTime(2026, 10, 7, 15, 5),
    );

    final followUpRecord = await followUp.create(
      studentId: 'student-1',
      createdBy: 'servant-1',
      followUpDate: '2026-10-07',
      contactStatus: 'contacted',
      contactMethod: 'phone',
      parentResponse: 'Will attend next week',
      actionRequired: 'Monitor attendance',
      anotherFollowUpNeeded: true,
      nextFollowUpDate: '2026-10-14',
    );

    final updatedStudent = await students.updateStudent(
      studentId: 'student-1',
      name: 'Peter Updated',
      notes: 'Follow-up completed',
    );

    final pending = await queue.pending();

    expect(pending, hasLength(3));
    expect(
      pending.map((item) => item.entityType).toSet(),
      containsAll(<String>['attendance', 'follow_up', 'student']),
    );
    expect(
      pending.map((item) => item.operationId).toSet(),
      containsAll(<String>[
        attendanceRecord.clientOperationId,
        followUpRecord.clientOperationId,
      ]),
    );

    final attendancePayload = jsonDecode(
      pending.firstWhere((item) => item.entityType == 'attendance').payloadJson,
    ) as Map<String, dynamic>;
    final followUpPayload = jsonDecode(
      pending.firstWhere((item) => item.entityType == 'follow_up').payloadJson,
    ) as Map<String, dynamic>;
    final studentPayload = jsonDecode(
      pending.firstWhere((item) => item.entityType == 'student').payloadJson,
    ) as Map<String, dynamic>;

    expect(attendancePayload['student_id'], 'student-1');
    expect(followUpPayload['student_id'], 'student-1');
    expect(studentPayload['name'], 'Peter Updated');

    final cachedStudent = await students.local.findById('student-1');
    expect(cachedStudent?.name, 'Peter Updated');

    final attendanceRows = await db.select(db.cachedAttendanceRecords).get();
    expect(attendanceRows, hasLength(1));
    expect(attendanceRows.single.studentId, 'student-1');

    final followUpRows =
        await followUp.watchForStudent('student-1').firstWhere((rows) => rows.isNotEmpty);
    expect(followUpRows.single.id, followUpRecord.id);
  });

  test('offline state keeps the complete cross-feature queue pending', () async {
    await students.local.cacheStudents([_student()]);
    await attendance.checkIn(
      meetingId: 'meeting-1',
      studentId: 'student-1',
      classIdAtAttendance: 'class-1',
      recordedBy: 'servant-1',
      checkedInAt: DateTime(2026, 10, 7, 15, 5),
    );
    await followUp.create(
      studentId: 'student-1',
      createdBy: 'servant-1',
      followUpDate: '2026-10-07',
      contactStatus: 'contacted',
    );

    final engine = SyncEngine(
      queue: queue,
      transport: _NoopTransport(),
      connectivityChecker: () async => [ConnectivityResult.none],
    );

    await engine.syncNow();

    expect(engine.status.name, 'offline');
    expect(await queue.pending(), hasLength(2));

    await engine.dispose();
  });
}
