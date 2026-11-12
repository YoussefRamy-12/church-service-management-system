import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../domain/analytics_models.dart';
import '../domain/service_report.dart';
import '../../attendance/data/attendance_timestamp.dart';

class SupabaseReportRepository {
  SupabaseReportRepository(this._client);

  final SupabaseClient _client;

  Future<ServiceReport> fetch({
    required String serviceId,
    required DateTime start,
    required DateTime end,
    Set<String>? classIds,
    String? stageId,
    String? studentId,
    bool compareWithPrevious = true,
  }) async {
    // 1. Service settings & early attendance minutes
    var earlyMinutes = 15;
    try {
      final service = await _client
          .from('services')
          .select('early_attendance_minutes')
          .eq('id', serviceId)
          .maybeSingle();
      earlyMinutes = service?['early_attendance_minutes'] as int? ?? 15;
    } catch (_) {}

    // 2. Fetch stages and classes
    final stagesRes = await _client
        .from('stages')
        .select('id, name')
        .eq('service_id', serviceId);
    final stageMap = {
      for (final s in (stagesRes as List))
        s['id'] as String: s['name'] as String,
    };

    final stagesToQuery = stageId != null ? [stageId] : stageMap.keys.toList();
    List<dynamic> classesRes = [];
    if (stagesToQuery.isNotEmpty) {
      classesRes = await _client
          .from('classes')
          .select('id, stage_id, name')
          .inFilter('stage_id', stagesToQuery);
    }

    final classMap = {
      for (final c in classesRes) c['id'] as String: c,
    };

    final effectiveClassIds = classIds ??
        (stageId != null
            ? classesRes.map((c) => c['id'] as String).toSet()
            : null);

    // 3. Query Students
    var studentQuery = _client
        .from('students')
        .select('id, name, phone, current_class_id, proposed_class_id, enrollment_at, approval_status')
        .eq('service_id', serviceId);

    if (studentId != null) {
      studentQuery = studentQuery.eq('id', studentId);
    }

    final studentsRes = await studentQuery;
    final scopedStudents = (studentsRes as List).where((row) {
      final currentClass = row['current_class_id'] as String?;
      return currentClass != null &&
          (effectiveClassIds == null || effectiveClassIds.contains(currentClass));
    }).toList();

    final studentIds =
        scopedStudents.map((row) => row['id'] as String).toList();
    final studentSet = studentIds.toSet();
    final studentNames = {
      for (final row in scopedStudents)
        row['id'] as String: row['name'] as String? ?? row['id'] as String,
    };
    final studentClassMap = {
      for (final row in scopedStudents)
        row['id'] as String: row['current_class_id'] as String?,
    };
    final studentEnrollment = <String, DateTime?>{
      for (final row in scopedStudents)
        row['id'] as String: row['enrollment_at'] == null
            ? null
            : DateTime.tryParse(row['enrollment_at'] as String),
    };

    // 4. Query Meetings in period
    final startDateStr = _date(start);
    final endDateStr = _date(end);

    final meetingsRes = await _client
        .from('meetings')
        .select('id, meeting_date, start_time, name')
        .eq('service_id', serviceId)
        .gte('meeting_date', startDateStr)
        .lte('meeting_date', endDateStr)
        .order('meeting_date');

    final meetingRows = (meetingsRes as List).cast<Map<String, dynamic>>();
    final meetingIds =
        meetingRows.map((row) => row['id'] as String).toList();

    // 5. Query Attendance
    List<dynamic> attendanceRes = [];
    if (meetingIds.isNotEmpty) {
      attendanceRes = await _client
          .from('attendance_records')
          .select(
            'meeting_id, student_id, checked_in_at, created_at, updated_at',
          )
          .inFilter('meeting_id', meetingIds);
    }

    // Deduplicate attendance
    final countedKeys = <String>{};
    var presentCount = 0;
    var earlyCount = 0;
    var beforeCount = 0;
    var normalCount = 0;

    final earlyItems = <String>[];
    final beforeItems = <String>[];
    final normalItems = <String>[];
    final attendanceItems = <String>[];

    final studentMeetingAttendance = <String, Set<String>>{};
    final studentAttendedMeetings = <String, Set<String>>{};

    for (final row in attendanceRes) {
      final sId = row['student_id'] as String;
      final mId = row['meeting_id'] as String;
      if (!studentSet.contains(sId)) continue;
      final key = '$mId:$sId';
      if (!countedKeys.add(key)) continue;

      presentCount++;
      studentMeetingAttendance
          .putIfAbsent(mId, () => <String>{})
          .add(sId);
      studentAttendedMeetings
          .putIfAbsent(sId, () => <String>{})
          .add(mId);

      final checkedIn = attendanceTimestampFromRow(row);
      final meeting = meetingRows.firstWhere((item) => item['id'] == mId);
      final startParts = (meeting['start_time'] as String).split(':');
      final dateParts = (meeting['meeting_date'] as String).split('-');
      final startDt = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.tryParse(startParts[0]) ?? 15,
        startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0,
      );
      final earlyLimit = startDt.add(Duration(minutes: earlyMinutes));

      final studentName = studentNames[sId] ?? sId;
      final itemStr =
          '${meeting['meeting_date']} • ${DateFormat('hh:mm a').format(checkedIn)} • $studentName';
      attendanceItems.add(itemStr);

      if (checkedIn.isBefore(startDt)) {
        beforeCount++;
        beforeItems.add(itemStr);
      } else if (checkedIn.isBefore(earlyLimit)) {
        earlyCount++;
        earlyItems.add(itemStr);
      } else {
        normalCount++;
        normalItems.add(itemStr);
      }
    }

    // 6. Expected Attendance calculation
    var expectedTotal = 0;
    for (final sId in studentIds) {
      final enrolledAt = studentEnrollment[sId];
      for (final m in meetingRows) {
        final mDate = DateTime.parse(m['meeting_date'] as String);
        if (enrolledAt == null || !mDate.isBefore(enrolledAt)) {
          expectedTotal++;
        }
      }
    }

    // 7. Meeting History
    final meetingHistory = <MeetingAttendanceItem>[];
    for (final m in meetingRows) {
      final mId = m['id'] as String;
      final mAttended = studentMeetingAttendance[mId] ?? <String>{};
      var mExpected = 0;
      final mDate = DateTime.parse(m['meeting_date'] as String);
      for (final sId in studentIds) {
        final enrolledAt = studentEnrollment[sId];
        if (enrolledAt == null || !mDate.isBefore(enrolledAt)) {
          mExpected++;
        }
      }

      var mEarly = 0;
      var mBefore = 0;
      var mNormal = 0;

      final mRecords =
          attendanceRes.where((r) => r['meeting_id'] == mId && studentSet.contains(r['student_id']));
      final mCounted = <String>{};
      final parts = (m['start_time'] as String).split(':');
      final dateParts = (m['meeting_date'] as String).split('-');
      final startDt = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.tryParse(parts[0]) ?? 15,
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );
      final earlyLimit = startDt.add(Duration(minutes: earlyMinutes));

      for (final r in mRecords) {
        final sid = r['student_id'] as String;
        if (!mCounted.add(sid)) continue;
        final chk = attendanceTimestampFromRow(r);
        if (chk.isBefore(startDt)) {
          mBefore++;
        } else if (chk.isBefore(earlyLimit)) {
          mEarly++;
        } else {
          mNormal++;
        }
      }

      meetingHistory.add(
        MeetingAttendanceItem(
          meetingId: mId,
          meetingDate: m['meeting_date'] as String,
          meetingName: m['name'] as String? ?? 'اجتماع الخدمة',
          startTime: m['start_time'] as String,
          expectedCount: mExpected,
          presentCount: mAttended.length,
          earlyCount: mEarly,
          beforeCount: mBefore,
          normalCount: mNormal,
        ),
      );
    }

    // 8. Consecutive Missed Meetings (الغياب المتكرر)
    final allPastMeetingsRes = await _client
        .from('meetings')
        .select('id, meeting_date')
        .eq('service_id', serviceId)
        .lte('meeting_date', endDateStr)
        .order('meeting_date', ascending: false);

    final pastMeetingRows =
        (allPastMeetingsRes as List).cast<Map<String, dynamic>>();
    final pastMeetingIds =
        pastMeetingRows.map((m) => m['id'] as String).toList();

    List<dynamic> pastAttendanceRes = [];
    if (pastMeetingIds.isNotEmpty && studentIds.isNotEmpty) {
      pastAttendanceRes = await _client
          .from('attendance_records')
          .select('meeting_id, student_id')
          .inFilter('meeting_id', pastMeetingIds)
          .inFilter('student_id', studentIds);
    }

    final pastStudentAttended = <String, Set<String>>{};
    for (final r in pastAttendanceRes) {
      final sid = r['student_id'] as String;
      final mid = r['meeting_id'] as String;
      pastStudentAttended
          .putIfAbsent(sid, () => <String>{})
          .add(mid);
    }

    final repeatedAbsences = <RepeatedAbsenceRecord>[];
    for (final s in scopedStudents) {
      final sid = s['id'] as String;
      final enrolledAt = studentEnrollment[sid];
      final attendedSet = pastStudentAttended[sid] ?? <String>{};
      var consecutiveMissed = 0;
      String? lastAttended;

      for (final m in pastMeetingRows) {
        final mDate = DateTime.parse(m['meeting_date'] as String);
        if (enrolledAt != null && mDate.isBefore(enrolledAt)) {
          break;
        }
        final mid = m['id'] as String;
        if (attendedSet.contains(mid)) {
          lastAttended ??= m['meeting_date'] as String;
          break;
        } else {
          consecutiveMissed++;
        }
      }

      if (consecutiveMissed >= 2) {
        final currentClassId = s['current_class_id'] as String?;
        final c = classMap[currentClassId];
        repeatedAbsences.add(
          RepeatedAbsenceRecord(
            studentId: sid,
            studentName: s['name'] as String? ?? sid,
            classId: currentClassId ?? '',
            className: c != null ? (c['name'] as String) : 'فصل غير محدد',
            consecutiveMissedMeetings: consecutiveMissed,
            lastAttendedDate: lastAttended,
            phone: s['phone'] as String?,
          ),
        );
      }
    }

    repeatedAbsences.sort(
      (a, b) => b.consecutiveMissedMeetings.compareTo(a.consecutiveMissedMeetings),
    );

    // 9. Follow-Up Cases & Activities
    List<dynamic> followUpCasesRes = [];
    try {
      followUpCasesRes = await _client
          .from('follow_up_cases')
          .select('id, student_id, class_id, priority, status')
          .eq('service_id', serviceId);
    } catch (_) {}

    final scopedCases = followUpCasesRes.where((c) {
      final cid = c['class_id'] as String?;
      if (effectiveClassIds != null && (cid == null || !effectiveClassIds.contains(cid))) {
        return false;
      }
      if (studentId != null && c['student_id'] != studentId) return false;
      return true;
    }).toList();

    final caseIds = scopedCases.map((c) => c['id'] as String).toList();

    var openCases = 0;
    var assignedCases = 0;
    var inProgressCases = 0;
    var resolvedCases = 0;
    var closedCases = 0;
    var urgentHighCases = 0;

    for (final c in scopedCases) {
      final st = c['status'] as String?;
      switch (st) {
        case 'open':
          openCases++;
          break;
        case 'assigned':
          assignedCases++;
          break;
        case 'in_progress':
          inProgressCases++;
          break;
        case 'resolved':
          resolvedCases++;
          break;
        case 'closed':
          closedCases++;
          break;
      }
      final prio = c['priority'] as String?;
      if (prio == 'high' || prio == 'urgent') {
        urgentHighCases++;
      }
    }

    List<dynamic> activitiesRes = [];
    if (caseIds.isNotEmpty) {
      try {
        activitiesRes = await _client
            .from('follow_up_activities')
            .select('id, case_id, activity_type, created_by, activity_date')
            .inFilter('case_id', caseIds)
            .gte('activity_date', startDateStr)
            .lte('activity_date', endDateStr);
      } catch (_) {}
    }

    final activityTypeCounts = <String, int>{};
    for (final a in activitiesRes) {
      final type = a['activity_type'] as String? ?? 'general';
      activityTypeCounts[type] = (activityTypeCounts[type] ?? 0) + 1;
    }

    final followUpAnalytics = FollowUpAnalytics(
      totalCases: scopedCases.length,
      openCases: openCases,
      assignedCases: assignedCases,
      inProgressCases: inProgressCases,
      resolvedCases: resolvedCases,
      closedCases: closedCases,
      urgentOrHighPriorityCases: urgentHighCases,
      totalActivities: activitiesRes.length,
      activityTypeCounts: activityTypeCounts,
    );

    // Legacy follow-up records
    List<dynamic> legacyFollowUps = [];
    if (studentIds.isNotEmpty) {
      try {
        legacyFollowUps = await _client
            .from('follow_up_records')
            .select('id, student_id, follow_up_date')
            .inFilter('student_id', studentIds)
            .gte('follow_up_date', startDateStr)
            .lte('follow_up_date', endDateStr);
      } catch (_) {}
    }

    // 10. Class Comparisons
    final relevantClasses = classesRes.where((c) {
      final cid = c['id'] as String;
      return effectiveClassIds == null || effectiveClassIds.contains(cid);
    }).toList();

    final classComparisons = <ClassComparisonMetric>[];
    for (final c in relevantClasses) {
      final cid = c['id'] as String;
      final classStudents =
          scopedStudents.where((s) => s['current_class_id'] == cid).toList();
      var cExpected = 0;
      var cPresent = 0;
      var cEarly = 0;
      var cNormal = 0;

      for (final s in classStudents) {
        final sid = s['id'] as String;
        final enrolledAt = studentEnrollment[sid];
        for (final m in meetingRows) {
          final mDate = DateTime.parse(m['meeting_date'] as String);
          if (enrolledAt == null || !mDate.isBefore(enrolledAt)) {
            cExpected++;
          }
        }
      }

      for (final row in attendanceRes) {
        final sid = row['student_id'] as String;
        final mid = row['meeting_id'] as String;
        if (studentClassMap[sid] != cid) continue;
        if (!countedKeys.contains('$mid:$sid')) continue;
        cPresent++;
        final checkedIn = attendanceTimestampFromRow(row);
        final meeting = meetingRows.firstWhere((item) => item['id'] == mid);
        final parts = (meeting['start_time'] as String).split(':');
        final dateParts = (meeting['meeting_date'] as String).split('-');
        final startDt = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.tryParse(parts[0]) ?? 15,
          parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
        );
        final earlyLimit = startDt.add(Duration(minutes: earlyMinutes));
        if (checkedIn.isBefore(earlyLimit)) {
          cEarly++;
        } else {
          cNormal++;
        }
      }

      final cRepeated = repeatedAbsences.where((r) => r.classId == cid).length;
      final cCases = scopedCases.where((cs) => cs['class_id'] == cid).toList();
      final cOpenCases = cCases
          .where((cs) =>
              cs['status'] == 'open' ||
              cs['status'] == 'assigned' ||
              cs['status'] == 'in_progress')
          .length;
      final cResolvedCases = cCases
          .where((cs) => cs['status'] == 'resolved' || cs['status'] == 'closed')
          .length;

      final stageIdOfClass = c['stage_id'] as String?;
      final stageName = stageIdOfClass != null
          ? (stageMap[stageIdOfClass] ?? 'المرحلة')
          : 'المرحلة';

      classComparisons.add(
        ClassComparisonMetric(
          classId: cid,
          className: c['name'] as String,
          stageId: stageIdOfClass ?? '',
          stageName: stageName,
          totalStudents: classStudents.length,
          expectedAttendance: cExpected,
          presentCount: cPresent,
          earlyCount: cEarly,
          normalCount: cNormal,
          repeatedAbsencesCount: cRepeated,
          openCasesCount: cOpenCases,
          resolvedCasesCount: cResolvedCases,
        ),
      );
    }

    classComparisons.sort((a, b) => b.attendanceRate.compareTo(a.attendanceRate));

    // 11. Servant Workload
    List<dynamic> profilesRes = [];
    try {
      profilesRes = await _client
          .from('servant_profiles')
          .select('id, name, role, class_id')
          .eq('service_id', serviceId)
          .eq('account_status', 'active');
    } catch (_) {}

    List<dynamic> assignmentsRes = [];
    if (caseIds.isNotEmpty) {
      try {
        assignmentsRes = await _client
            .from('follow_up_case_assignments')
            .select('case_id, servant_id')
            .inFilter('case_id', caseIds)
            .eq('assignment_status', 'active');
      } catch (_) {}
    }

    final servantWorkloads = <ServantWorkloadMetric>[];
    for (final p in profilesRes) {
      final pClassId = p['class_id'] as String?;
      if (effectiveClassIds != null && pClassId != null && !effectiveClassIds.contains(pClassId)) {
        continue;
      }
      final pId = p['id'] as String;
      final servantCaseIds = assignmentsRes
          .where((a) => a['servant_id'] == pId)
          .map((a) => a['case_id'] as String)
          .toSet();

      final servantActivities =
          activitiesRes.where((act) => act['created_by'] == pId).length;

      final className =
          pClassId != null ? (classMap[pClassId]?['name'] as String?) : null;

      servantWorkloads.add(
        ServantWorkloadMetric(
          servantId: pId,
          servantName: p['name'] as String? ?? 'خادم',
          role: p['role'] as String? ?? 'class_servant',
          classId: pClassId,
          className: className,
          assignedCasesCount: servantCaseIds.length,
          activeCasesCount: servantCaseIds.length,
          completedActivitiesCount: servantActivities,
        ),
      );
    }

    // 12. Student Analytics & Tiers
    final tierCounts = {'90-100%': 0, '75-89%': 0, '50-74%': 0, '<50%': 0};
    for (final s in scopedStudents) {
      final sid = s['id'] as String;
      final enrolledAt = studentEnrollment[sid];
      var sExp = 0;
      for (final m in meetingRows) {
        final mDate = DateTime.parse(m['meeting_date'] as String);
        if (enrolledAt == null || !mDate.isBefore(enrolledAt)) {
          sExp++;
        }
      }
      final attended = (studentAttendedMeetings[sid] ?? <String>{}).length;
      final rate = sExp == 0 ? 0.0 : (attended * 100.0) / sExp;
      if (rate >= 90) {
        tierCounts['90-100%'] = (tierCounts['90-100%'] ?? 0) + 1;
      } else if (rate >= 75) {
        tierCounts['75-89%'] = (tierCounts['75-89%'] ?? 0) + 1;
      } else if (rate >= 50) {
        tierCounts['50-74%'] = (tierCounts['50-74%'] ?? 0) + 1;
      } else {
        tierCounts['<50%'] = (tierCounts['<50%'] ?? 0) + 1;
      }
    }

    final activeCount =
        scopedStudents.where((s) => s['approval_status'] == 'approved').length;
    final pendingCount =
        scopedStudents.where((s) => s['approval_status'] == 'pending').length;

    final studentAnalytics = StudentAnalytics(
      activeStudents: activeCount,
      pendingStudents: pendingCount,
      attendanceTiers: tierCounts,
      improvingCount: 0,
      decliningCount: repeatedAbsences.length,
    );

    // 13. Actionable Insights
    final actionableInsights = <ActionableInsight>[];
    if (repeatedAbsences.isNotEmpty) {
      final severeAbsences =
          repeatedAbsences.where((r) => r.consecutiveMissedMeetings >= 3).toList();
      if (severeAbsences.isNotEmpty) {
        actionableInsights.add(
          ActionableInsight(
            id: 'severe-absences',
            title: 'غياب متكرر حرج يستلزم تدخلاً عاجلاً',
            description:
                'يوجد ${severeAbsences.length} تلميذ تغيبوا عن ٣ اجتماعات متتالية أو أكثر.',
            severity: InsightSeverity.critical,
            targetTab: 'attendance',
          ),
        );
      } else {
        actionableInsights.add(
          ActionableInsight(
            id: 'repeated-absences',
            title: 'تلاميذ بحاجة إلى افتقاد دوري',
            description:
                'يوجد ${repeatedAbsences.length} تلميذ تغيبوا عن اجتماعين متتاليين.',
            severity: InsightSeverity.warning,
            targetTab: 'attendance',
          ),
        );
      }
    }

    for (final cm in classComparisons) {
      if (cm.expectedAttendance > 0 && cm.attendanceRate < 60) {
        actionableInsights.add(
          ActionableInsight(
            id: 'low-class-${cm.classId}',
            title: 'انخفاض نسبة الحضور في ${cm.className}',
            description:
                'سجل الفصل نسبة حضور ${cm.attendanceRate.toStringAsFixed(1)}% وهو دون المعدل المستهدف (60%).',
            severity: InsightSeverity.warning,
            classId: cm.classId,
            targetTab: 'overview',
          ),
        );
      }
      if (cm.openCasesCount >= 5) {
        actionableInsights.add(
          ActionableInsight(
            id: 'accumulating-cases-${cm.classId}',
            title: 'تراكم حالات المتابعة في ${cm.className}',
            description:
                'يوجد ${cm.openCasesCount} حالة افتقاد مفتوحة قيد الانتظار لم تحسم بعد.',
            severity: InsightSeverity.warning,
            classId: cm.classId,
            targetTab: 'follow_up',
          ),
        );
      }
    }

    // 14. Previous Period Comparison
    double? prevRate;
    if (compareWithPrevious && meetingRows.isNotEmpty) {
      final duration = end.difference(start);
      final days = duration.inDays <= 0 ? 7 : duration.inDays + 1;
      final prevEnd = start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(Duration(days: days - 1));

      final prevStartStr = _date(prevStart);
      final prevEndStr = _date(prevEnd);

      final prevMeetingsRes = await _client
          .from('meetings')
          .select('id, meeting_date')
          .eq('service_id', serviceId)
          .gte('meeting_date', prevStartStr)
          .lte('meeting_date', prevEndStr);

      final prevMeetingRows =
          (prevMeetingsRes as List).cast<Map<String, dynamic>>();

      if (prevMeetingRows.isNotEmpty) {
        var prevExpected = 0;
        for (final sid in studentIds) {
          final enrolledAt = studentEnrollment[sid];
          for (final pm in prevMeetingRows) {
            final pmDate = DateTime.parse(pm['meeting_date'] as String);
            if (enrolledAt == null || !pmDate.isBefore(enrolledAt)) {
              prevExpected++;
            }
          }
        }

        final prevMeetingIds =
            prevMeetingRows.map((m) => m['id'] as String).toList();
        List<dynamic> prevAttendance = [];
        if (prevMeetingIds.isNotEmpty) {
          prevAttendance = await _client
              .from('attendance_records')
              .select('meeting_id, student_id')
              .inFilter('meeting_id', prevMeetingIds);
        }

        final prevCounted = <String>{};
        var prevPresent = 0;
        for (final r in prevAttendance) {
          final sid = r['student_id'] as String;
          final mid = r['meeting_id'] as String;
          if (!studentSet.contains(sid)) continue;
          if (prevCounted.add('$mid:$sid')) {
            prevPresent++;
          }
        }

        if (prevExpected > 0) {
          prevRate = (prevPresent * 100.0) / prevExpected;
        }
      }
    }

    final scopedStageName = stageId != null ? stageMap[stageId] : null;
    final scopedClassName = classIds != null && classIds.length == 1
        ? (classMap[classIds.first]?['name'] as String?)
        : null;

    return ServiceReport(
      students: studentIds.length,
      meetings: meetingRows.length,
      expectedAttendance: expectedTotal,
      present: presentCount,
      early: earlyCount,
      before: beforeCount,
      normal: normalCount,
      followUps: legacyFollowUps.length + activitiesRes.length,
      previousPeriodAttendanceRate: prevRate,
      meetingHistory: meetingHistory,
      repeatedAbsences: repeatedAbsences,
      classComparisons: classComparisons,
      servantWorkloads: servantWorkloads,
      actionableInsights: actionableInsights,
      followUpAnalytics: followUpAnalytics,
      studentAnalytics: studentAnalytics,
      scopedStageName: scopedStageName,
      scopedClassName: scopedClassName,
      details: {
        'students': scopedStudents
            .map((r) => r['name'] as String? ?? r['id'] as String)
            .toList(),
        'meetings': meetingRows
            .map((r) => '${r['meeting_date']} • ${r['start_time']}')
            .toList(),
        'early': earlyItems,
        'before': beforeItems,
        'normal': normalItems,
        'attendance': attendanceItems,
        'followUps': legacyFollowUps
            .map((r) =>
                '${r['follow_up_date']} • ${studentNames[r['student_id']] ?? r['student_id']}')
            .toList(),
      },
    );
  }

  String _date(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
}
