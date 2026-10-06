import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/service_report.dart';

class SupabaseReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  Future<ServiceReport> fetch({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    Set<String>? classIds,
  }) async {
    final students = await _client
        .from('students')
        .select('id, current_class_id, proposed_class_id, enrollment_at')
        .eq('service_id', serviceId);

    final scopedStudents = (students as List).where((row) {
      final currentClass = row['current_class_id'] as String?;
      return currentClass != null &&
          (classIds == null || classIds.contains(currentClass));
    }).toList();

    final meetings = await _client
        .from('meetings')
        .select('id, meeting_date, start_time')
        .eq('service_id', serviceId)
        .gte('meeting_date', _date(start))
        .lte('meeting_date', _date(end))
        .order('meeting_date');

    final meetingIds = (meetings as List).map((row) => row['id'] as String).toList();
    List<dynamic> attendance = [];
    if (meetingIds.isNotEmpty) {
      attendance = await _client
          .from('attendance_records')
          .select('meeting_id, student_id, checked_in_at')
          .inFilter('meeting_id', meetingIds);
    }

    final studentIds = scopedStudents.map((row) => row['id'] as String).toList();
    List<dynamic> followUps = [];
    if (studentIds.isNotEmpty) {
      followUps = await _client
          .from('follow_up_records')
          .select('id, student_id, follow_up_date')
          .inFilter('student_id', studentIds)
          .gte('follow_up_date', _date(start))
          .lte('follow_up_date', _date(end));
    }

    return _build(
      scopedStudents,
      meetings,
      attendance,
      followUps,
      classIds,
    );
  }

  ServiceReport _build(
    List<dynamic> students,
    List<dynamic> meetings,
    List<dynamic> attendance,
    List<dynamic> followUps,
    Set<String>? classIds,
  ) {
    final studentIds = students.map((row) => row['id'] as String).toSet();
    final enrollment = <String, DateTime?>{
      for (final row in students)
        row['id'] as String: row['enrollment_at'] == null
            ? null
            : DateTime.parse(row['enrollment_at'] as String),
    };

    final meetingRows = meetings.cast<Map<String, dynamic>>();
    var expected = 0;
    for (final studentId in studentIds) {
      for (final meeting in meetingRows) {
        final meetingDate = DateTime.parse(meeting['meeting_date'] as String);
        final enrolledAt = enrollment[studentId];
        if (enrolledAt == null || !meetingDate.isBefore(enrolledAt)) {
          expected++;
        }
      }
    }

    var present = 0;
    var early = 0;
    var normal = 0;
    final counted = <String>{};
    for (final row in attendance) {
      final studentId = row['student_id'] as String;
      final meetingId = row['meeting_id'] as String;
      if (!studentIds.contains(studentId)) continue;
      final key = '$meetingId:$studentId';
      if (!counted.add(key)) continue;
      present++;
      final checkedIn = DateTime.parse(row['checked_in_at'] as String);
      final meeting = meetingRows.firstWhere(
        (item) => item['id'] == meetingId,
      );
      final startParts = (meeting['start_time'] as String).split(':');
      final start = DateTime(
        checkedIn.year,
        checkedIn.month,
        checkedIn.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
        startParts.length > 2 ? int.parse(startParts[2]) : 0,
      );
      if (checkedIn.isBefore(start.add(const Duration(minutes: 15)))) {
        early++;
      } else {
        normal++;
      }
    }

    return ServiceReport(
      students: studentIds.length,
      meetings: meetingRows.length,
      expectedAttendance: expected,
      present: present,
      early: early,
      normal: normal,
      followUps: followUps.length,
    );
  }

  String _date(DateTime value) =>
      value.toIso8601String().split('T').first;
}
