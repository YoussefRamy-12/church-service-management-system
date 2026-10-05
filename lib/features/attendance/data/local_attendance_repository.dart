import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../domain/entities/attendance_record.dart';
import '../domain/repositories/attendance_repository.dart';

class LocalAttendanceRepository implements AttendanceRepository {
  LocalAttendanceRepository(this._db);
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<AttendanceRecord>> watchForMeeting(String meetingId) =>
      (_db.select(_db.cachedAttendanceRecords)
        ..where((t) => t.meetingId.equals(meetingId))
        ..orderBy([(t) => OrderingTerm(expression: t.checkedInAt)]))
      .watch().map((rows) => rows.map(_map).toList());

  @override
  Future<AttendanceRecord> checkIn({
    required String meetingId,
    required String studentId,
    required String classIdAtAttendance,
    required String recordedBy,
    required DateTime checkedInAt,
  }) async {
    final existing = await (_db.select(_db.cachedAttendanceRecords)
      ..where((t) => t.meetingId.equals(meetingId))
      ..where((t) => t.studentId.equals(studentId))).getSingleOrNull();
    if (existing != null) return _map(existing);

    final id = _uuid.v4();
    final operationId = _uuid.v4();
    final record = AttendanceRecord(
      id: id, meetingId: meetingId, studentId: studentId,
      classIdAtAttendance: classIdAtAttendance, checkedInAt: checkedInAt,
      recordedBy: recordedBy, clientOperationId: operationId, syncState: 'pending',
    );
    await _db.into(_db.cachedAttendanceRecords).insert(
      CachedAttendanceRecordsCompanion.insert(
        id: id, meetingId: meetingId, studentId: studentId,
        classIdAtAttendance: classIdAtAttendance,
        checkedInAt: checkedInAt, recordedBy: recordedBy,
        clientOperationId: operationId,
      ),
    );
    return record;
  }

  AttendanceRecord _map(CachedAttendanceRecord r) => AttendanceRecord(
    id: r.id, meetingId: r.meetingId, studentId: r.studentId,
    classIdAtAttendance: r.classIdAtAttendance, checkedInAt: r.checkedInAt,
    recordedBy: r.recordedBy, clientOperationId: r.clientOperationId,
    syncState: r.syncState,
  );
}
