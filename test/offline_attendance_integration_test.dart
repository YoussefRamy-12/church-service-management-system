import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/database/app_database.dart';
import 'package:church_service_management_system/core/sync/sync_queue_repository.dart';
import 'package:church_service_management_system/features/attendance/data/local_attendance_repository.dart';
import 'package:church_service_management_system/features/attendance/data/offline_first_attendance_repository.dart';

void main() {
  late AppDatabase db;
  late SyncQueueRepository queue;
  late OfflineFirstAttendanceRepository attendance;

  setUp(() {
    db = AppDatabase.forTesting();
    queue = SyncQueueRepository(db);
    attendance = OfflineFirstAttendanceRepository(
      local: LocalAttendanceRepository(db),
      queue: queue,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('offline check-in is immediately available locally and queued for sync', () async {
    final checkedInAt = DateTime(2026, 10, 7, 10, 30);

    final record = await attendance.checkIn(
      meetingId: 'meeting-1',
      studentId: 'student-1',
      classIdAtAttendance: 'class-1',
      recordedBy: 'servant-1',
      checkedInAt: checkedInAt,
    );

    final localRows = await db.select(db.cachedAttendanceRecords).get();
    final pending = await queue.pending();

    expect(localRows, hasLength(1));
    expect(localRows.single.studentId, 'student-1');
    expect(localRows.single.syncState, 'pending');
    expect(localRows.single.clientOperationId, record.clientOperationId);

    expect(pending, hasLength(1));
    expect(pending.single.operationId, record.clientOperationId);
    expect(pending.single.entityType, 'attendance');
    expect(pending.single.operationType, 'upsert');

    final payload = jsonDecode(pending.single.payloadJson) as Map<String, dynamic>;
    expect(payload['meeting_id'], 'meeting-1');
    expect(payload['student_id'], 'student-1');
    expect(payload['class_id_at_attendance'], 'class-1');
  });

  test('duplicate check-in does not create a second attendance record or sync operation', () async {
    final first = await attendance.checkIn(
      meetingId: 'meeting-1',
      studentId: 'student-1',
      classIdAtAttendance: 'class-1',
      recordedBy: 'servant-1',
      checkedInAt: DateTime(2026, 10, 7, 10, 30),
    );

    final second = await attendance.checkIn(
      meetingId: 'meeting-1',
      studentId: 'student-1',
      classIdAtAttendance: 'class-1',
      recordedBy: 'servant-1',
      checkedInAt: DateTime(2026, 10, 7, 10, 31),
    );

    final localRows = await db.select(db.cachedAttendanceRecords).get();
    final pending = await queue.pending();

    expect(second.id, first.id);
    expect(second.clientOperationId, first.clientOperationId);
    expect(localRows, hasLength(1));
    expect(pending, hasLength(1));
  });

  test('attendance can be read through the local watch stream', () async {
    final stream = attendance.watchForMeeting('meeting-1');

    await attendance.checkIn(
      meetingId: 'meeting-1',
      studentId: 'student-1',
      classIdAtAttendance: 'class-1',
      recordedBy: 'servant-1',
      checkedInAt: DateTime(2026, 10, 7, 10, 30),
    );

    final rows = await stream.firstWhere((value) => value.isNotEmpty);
    expect(rows, hasLength(1));
    expect(rows.single.studentId, 'student-1');
  });
}
