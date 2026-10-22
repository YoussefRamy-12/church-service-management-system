import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/service_report.dart';

class LocalReportRepository {
  LocalReportRepository(this._db);

  final AppDatabase _db;

  Future<ServiceReport> fetch({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    Set<String>? classIds,
  }) async {
    var earlyMinutes = 15;
    final cachedService = await (_db.select(_db.cachedServices)
      ..where((t) => t.id.equals(serviceId))).getSingleOrNull();
    if (cachedService != null) {
      final parts = cachedService.meetingStartTime.split('|');
      if (parts.length > 4) earlyMinutes = int.tryParse(parts[4]) ?? 15;
    }
    final students = await (_db.select(
      _db.cachedStudents,
    )..where((t) => t.serviceId.equals(serviceId))).get();
    final scopedStudents = students.where((row) {
      return row.currentClassId != null &&
          (classIds == null || classIds.contains(row.currentClassId));
    }).toList();

    final meetings =
        await (_db.select(_db.cachedMeetings)..where(
              (t) =>
                  t.serviceId.equals(serviceId) &
                  t.meetingDate.isBiggerOrEqualValue(
                    start.toIso8601String().split('T').first,
                  ) &
                  t.meetingDate.isSmallerOrEqualValue(
                    end.toIso8601String().split('T').first,
                  ),
            ))
            .get();

    final meetingIds = meetings.map((row) => row.id).toSet();
    final attendance = await (_db.select(
      _db.cachedAttendanceRecords,
    )..where((t) => t.meetingId.isIn(meetingIds))).get();

    final studentIds = scopedStudents.map((row) => row.id).toSet();
    final studentNames = {for (final row in scopedStudents) row.id: row.name};
    final followUps =
        await (_db.select(_db.cachedFollowUpRecords)..where(
              (t) =>
                  t.studentId.isIn(studentIds) &
                  t.followUpDate.isBiggerOrEqualValue(
                    start.toIso8601String().split('T').first,
                  ) &
                  t.followUpDate.isSmallerOrEqualValue(
                    end.toIso8601String().split('T').first,
                  ),
            ))
            .get();

    var expected = 0;
    for (final student in scopedStudents) {
      for (final meeting in meetings) {
        final enrollment = student.enrollmentAt == null
            ? null
            : DateTime.parse(student.enrollmentAt!);
        final meetingDate = DateTime.parse(meeting.meetingDate);
        if (enrollment == null || !meetingDate.isBefore(enrollment)) {
          expected++;
        }
      }
    }

    var present = 0;
    var early = 0;
    var normal = 0;
    final counted = <String>{};
    for (final row in attendance) {
      if (!studentIds.contains(row.studentId)) continue;
      final key = '${row.meetingId}:${row.studentId}';
      if (!counted.add(key)) continue;

      present++;
      final meeting = meetings.firstWhere((item) => item.id == row.meetingId);
      final parts = meeting.startTime.split(':');
      final startTime = DateTime(
        row.checkedInAt.year,
        row.checkedInAt.month,
        row.checkedInAt.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2]) : 0,
      );
      if (row.checkedInAt.isBefore(
        startTime.add(Duration(minutes: earlyMinutes)),
      )) {
        early++;
      } else {
        normal++;
      }
    }

    return ServiceReport(
      students: studentIds.length,
      meetings: meetings.length,
      expectedAttendance: expected,
      present: present,
      early: early,
      normal: normal,
      followUps: followUps.length,
      details: {
        'students': scopedStudents.map((row) => row.name).toList(),
        'meetings': meetings.map((row) => '${row.meetingDate} • ${row.startTime}').toList(),
        'early': attendance.where((row) => counted.contains('${row.meetingId}:${row.studentId}')).where((row) {
          final meeting = meetings.firstWhere((item) => item.id == row.meetingId);
          final parts = meeting.startTime.split(':');
          final began = DateTime(row.checkedInAt.year, row.checkedInAt.month, row.checkedInAt.day, int.tryParse(parts[0]) ?? 15, int.tryParse(parts[1]) ?? 0);
          return row.checkedInAt.isBefore(began.add(Duration(minutes: earlyMinutes)));
        }).map((row) => '${row.checkedInAt} • ${studentNames[row.studentId] ?? row.studentId}').toList(),
        'followUps': followUps.map((row) => '${row.followUpDate} • ${studentNames[row.studentId] ?? row.studentId}').toList(),
        'normal': attendance.where((row) {
          if (!studentIds.contains(row.studentId)) return false;
          final meeting = meetings.firstWhere((item) => item.id == row.meetingId);
          final parts = meeting.startTime.split(':');
          final began = DateTime(row.checkedInAt.year, row.checkedInAt.month, row.checkedInAt.day, int.tryParse(parts[0]) ?? 15, int.tryParse(parts[1]) ?? 0);
          return !row.checkedInAt.isBefore(began.add(Duration(minutes: earlyMinutes)));
        }).map((row) => '${row.checkedInAt} • ${studentNames[row.studentId] ?? row.studentId}').toList(),
        'attendance': attendance
            .where((row) => studentIds.contains(row.studentId))
            .map((row) => '${row.checkedInAt} • ${studentNames[row.studentId] ?? row.studentId}')
            .toList(),
      },
    );
  }
}
