import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../domain/analytics_models.dart';
import '../domain/service_report.dart';

class LocalReportRepository {
  LocalReportRepository(this._db);

  final AppDatabase _db;

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
    final cachedService = await (_db.select(_db.cachedServices)
          ..where((t) => t.id.equals(serviceId)))
        .getSingleOrNull();
    if (cachedService != null) {
      final parts = cachedService.meetingStartTime.split('|');
      if (parts.length > 4) earlyMinutes = int.tryParse(parts[4]) ?? 15;
    }

    // 2. Fetch stages and classes for mapping
    final allStages = await (_db.select(_db.cachedStages)
          ..where((t) => t.serviceId.equals(serviceId)))
        .get();
    final stageMap = {for (final s in allStages) s.id: s.name};

    final stageIds = stageId != null
        ? {stageId}
        : allStages.map((s) => s.id).toSet();
    final classesInStages = await (_db.select(_db.cachedClasses)
          ..where((t) => t.stageId.isIn(stageIds)))
        .get();
    final classMap = {for (final c in classesInStages) c.id: c};

    // Determine effective classes
    final effectiveClassIds = classIds ??
        (stageId != null ? classesInStages.map((c) => c.id).toSet() : null);

    // 3. Query Students in scope
    final students = await (_db.select(_db.cachedStudents)
          ..where((t) => t.serviceId.equals(serviceId)))
        .get();

    final scopedStudents = students.where((row) {
      if (studentId != null && row.id != studentId) return false;
      if (row.currentClassId == null) return false;
      if (effectiveClassIds != null &&
          !effectiveClassIds.contains(row.currentClassId)) {
        return false;
      }
      return true;
    }).toList();

    final studentIds = scopedStudents.map((row) => row.id).toSet();
    final studentNames = {for (final row in scopedStudents) row.id: row.name};
    final studentClassMap = {
      for (final row in scopedStudents) row.id: row.currentClassId,
    };
    final studentEnrollment = <String, DateTime?>{
      for (final s in scopedStudents)
        s.id: s.enrollmentAt == null ? null : DateTime.tryParse(s.enrollmentAt!),
    };

    // 4. Query Meetings in period
    final startDateStr = DateFormat('yyyy-MM-dd').format(start);
    final endDateStr = DateFormat('yyyy-MM-dd').format(end);

    final meetings = await (_db.select(_db.cachedMeetings)
          ..where(
            (t) =>
                t.serviceId.equals(serviceId) &
                t.meetingDate.isBiggerOrEqualValue(startDateStr) &
                t.meetingDate.isSmallerOrEqualValue(endDateStr),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.meetingDate)]))
        .get();

    final meetingIds = meetings.map((row) => row.id).toSet();

    // 5. Query Attendance records
    final attendanceRecords = meetingIds.isEmpty
        ? <CachedAttendanceRecord>[]
        : await (_db.select(_db.cachedAttendanceRecords)
              ..where((t) => t.meetingId.isIn(meetingIds)))
            .get();

    // Deduplicate attendance records (meetingId:studentId)
    final countedKeys = <String>{};
    var presentCount = 0;
    var earlyCount = 0;
    var beforeCount = 0;
    var normalCount = 0;

    final earlyItems = <String>[];
    final beforeItems = <String>[];
    final normalItems = <String>[];
    final attendanceItems = <String>[];

    // Attendance index by meeting and student
    final studentMeetingAttendance = <String, Set<String>>{}; // meetingId -> studentIds
    final studentAttendedMeetings = <String, Set<String>>{}; // studentId -> meetingIds

    for (final row in attendanceRecords) {
      if (!studentIds.contains(row.studentId)) continue;
      final key = '${row.meetingId}:${row.studentId}';
      if (!countedKeys.add(key)) continue;

      presentCount++;
      studentMeetingAttendance
          .putIfAbsent(row.meetingId, () => <String>{})
          .add(row.studentId);
      studentAttendedMeetings
          .putIfAbsent(row.studentId, () => <String>{})
          .add(row.meetingId);

      final meeting = meetings.firstWhere((item) => item.id == row.meetingId);
      final parts = meeting.startTime.split(':');
      final meetingDateParts = meeting.meetingDate.split('-');
      final startDateTime = DateTime(
        int.parse(meetingDateParts[0]),
        int.parse(meetingDateParts[1]),
        int.parse(meetingDateParts[2]),
        int.tryParse(parts[0]) ?? 15,
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );

      final checkedIn = row.checkedInAt;
      final earlyLimit = startDateTime.add(Duration(minutes: earlyMinutes));

      final studentName = studentNames[row.studentId] ?? row.studentId;
      final itemStr =
          '${meeting.meetingDate} • ${DateFormat('hh:mm a').format(checkedIn)} • $studentName';
      attendanceItems.add(itemStr);

      if (checkedIn.isBefore(startDateTime)) {
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
    for (final student in scopedStudents) {
      final enrollment = studentEnrollment[student.id];
      for (final meeting in meetings) {
        final meetingDate = DateTime.parse(meeting.meetingDate);
        if (enrollment == null || !meetingDate.isBefore(enrollment)) {
          expectedTotal++;
        }
      }
    }

    // 7. Meeting History Items
    final meetingHistory = <MeetingAttendanceItem>[];
    for (final meeting in meetings) {
      final mAttended = studentMeetingAttendance[meeting.id] ?? <String>{};
      var mExpected = 0;
      final meetingDate = DateTime.parse(meeting.meetingDate);
      for (final student in scopedStudents) {
        final enrollment = studentEnrollment[student.id];
        if (enrollment == null || !meetingDate.isBefore(enrollment)) {
          mExpected++;
        }
      }

      var mEarly = 0;
      var mBefore = 0;
      var mNormal = 0;

      final mRecords =
          attendanceRecords.where((r) => r.meetingId == meeting.id && studentIds.contains(r.studentId));
      final mCounted = <String>{};
      final parts = meeting.startTime.split(':');
      final dateParts = meeting.meetingDate.split('-');
      final startDt = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.tryParse(parts[0]) ?? 15,
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );
      final earlyLimit = startDt.add(Duration(minutes: earlyMinutes));

      for (final r in mRecords) {
        if (!mCounted.add(r.studentId)) continue;
        if (r.checkedInAt.isBefore(startDt)) {
          mBefore++;
        } else if (r.checkedInAt.isBefore(earlyLimit)) {
          mEarly++;
        } else {
          mNormal++;
        }
      }

      meetingHistory.add(
        MeetingAttendanceItem(
          meetingId: meeting.id,
          meetingDate: meeting.meetingDate,
          meetingName: meeting.name,
          startTime: meeting.startTime,
          expectedCount: mExpected,
          presentCount: mAttended.length,
          earlyCount: mEarly,
          beforeCount: mBefore,
          normalCount: mNormal,
        ),
      );
    }

    // 8. Consecutive Missed Meetings (الغياب المتكرر)
    // Order all meetings in service up to 'end' descending to detect current absence streak
    final allPastMeetings = await (_db.select(_db.cachedMeetings)
          ..where(
            (t) =>
                t.serviceId.equals(serviceId) &
                t.meetingDate.isSmallerOrEqualValue(endDateStr),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.meetingDate)]))
        .get();

    final pastMeetingIds = allPastMeetings.map((m) => m.id).toSet();
    final pastAttendance = pastMeetingIds.isEmpty
        ? <CachedAttendanceRecord>[]
        : await (_db.select(_db.cachedAttendanceRecords)
              ..where((t) => t.meetingId.isIn(pastMeetingIds)))
            .get();

    final pastStudentAttended = <String, Set<String>>{};
    for (final r in pastAttendance) {
      if (studentIds.contains(r.studentId)) {
        pastStudentAttended
            .putIfAbsent(r.studentId, () => <String>{})
            .add(r.meetingId);
      }
    }

    final repeatedAbsences = <RepeatedAbsenceRecord>[];
    for (final student in scopedStudents) {
      final enrollment = studentEnrollment[student.id];
      final attendedSet = pastStudentAttended[student.id] ?? <String>{};
      var consecutiveMissed = 0;
      String? lastAttended;

      for (final m in allPastMeetings) {
        final mDate = DateTime.parse(m.meetingDate);
        if (enrollment != null && mDate.isBefore(enrollment)) {
          break; // Stop before student was enrolled
        }
        if (attendedSet.contains(m.id)) {
          lastAttended ??= m.meetingDate;
          break; // Streak interrupted by attendance
        } else {
          consecutiveMissed++;
        }
      }

      if (consecutiveMissed >= 2) {
        final c = classMap[student.currentClassId];
        repeatedAbsences.add(
          RepeatedAbsenceRecord(
            studentId: student.id,
            studentName: student.name,
            classId: student.currentClassId ?? '',
            className: c?.name ?? 'فصل غير محدد',
            consecutiveMissedMeetings: consecutiveMissed,
            lastAttendedDate: lastAttended,
            phone: student.phone,
          ),
        );
      }
    }

    // Sort repeated absences by consecutiveMissed desc
    repeatedAbsences.sort(
      (a, b) => b.consecutiveMissedMeetings.compareTo(a.consecutiveMissedMeetings),
    );

    // 9. Follow-Up Analytics (Cases and Activities)
    final followUpCases = await (_db.select(_db.cachedFollowUpCases)
          ..where((t) => t.serviceId.equals(serviceId)))
        .get();

    final scopedCases = followUpCases.where((c) {
      if (effectiveClassIds != null && !effectiveClassIds.contains(c.classId)) {
        return false;
      }
      if (studentId != null && c.studentId != studentId) return false;
      return true;
    }).toList();

    final caseIds = scopedCases.map((c) => c.id).toSet();

    var openCases = 0;
    var assignedCases = 0;
    var inProgressCases = 0;
    var resolvedCases = 0;
    var closedCases = 0;
    var urgentHighCases = 0;

    for (final c in scopedCases) {
      switch (c.status) {
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
      if (c.priority == 'high' || c.priority == 'urgent') {
        urgentHighCases++;
      }
    }

    // Activities in date range
    final activities = caseIds.isEmpty
        ? <CachedFollowUpActivity>[]
        : await (_db.select(_db.cachedFollowUpActivities)
              ..where(
                (t) =>
                    t.caseId.isIn(caseIds) &
                    t.activityDate.isBiggerOrEqualValue(startDateStr) &
                    t.activityDate.isSmallerOrEqualValue(endDateStr),
              ))
            .get();

    final activityTypeCounts = <String, int>{};
    for (final a in activities) {
      activityTypeCounts[a.activityType] =
          (activityTypeCounts[a.activityType] ?? 0) + 1;
    }

    final followUpAnalytics = FollowUpAnalytics(
      totalCases: scopedCases.length,
      openCases: openCases,
      assignedCases: assignedCases,
      inProgressCases: inProgressCases,
      resolvedCases: resolvedCases,
      closedCases: closedCases,
      urgentOrHighPriorityCases: urgentHighCases,
      totalActivities: activities.length,
      activityTypeCounts: activityTypeCounts,
    );

    // Legacy follow-up records
    final legacyFollowUps = await (_db.select(_db.cachedFollowUpRecords)
          ..where(
            (t) =>
                t.studentId.isIn(studentIds) &
                t.followUpDate.isBiggerOrEqualValue(startDateStr) &
                t.followUpDate.isSmallerOrEqualValue(endDateStr),
          ))
        .get();

    // 10. Class Comparisons
    final relevantClasses = classesInStages.where((c) {
      if (effectiveClassIds != null && !effectiveClassIds.contains(c.id)) {
        return false;
      }
      return true;
    }).toList();

    final classComparisons = <ClassComparisonMetric>[];
    for (final c in relevantClasses) {
      final classStudents =
          scopedStudents.where((s) => s.currentClassId == c.id).toList();
      var cExpected = 0;
      var cPresent = 0;
      var cEarly = 0;
      var cNormal = 0;

      for (final s in classStudents) {
        final enrollment = studentEnrollment[s.id];
        for (final m in meetings) {
          final mDate = DateTime.parse(m.meetingDate);
          if (enrollment == null || !mDate.isBefore(enrollment)) {
            cExpected++;
          }
        }
      }

      for (final row in attendanceRecords) {
        if (studentClassMap[row.studentId] != c.id) continue;
        if (!countedKeys.contains('${row.meetingId}:${row.studentId}')) continue;
        cPresent++;
        final meeting = meetings.firstWhere((item) => item.id == row.meetingId);
        final parts = meeting.startTime.split(':');
        final dateParts = meeting.meetingDate.split('-');
        final startDt = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.tryParse(parts[0]) ?? 15,
          parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
        );
        final earlyLimit = startDt.add(Duration(minutes: earlyMinutes));
        if (row.checkedInAt.isBefore(earlyLimit)) {
          cEarly++;
        } else {
          cNormal++;
        }
      }

      final cRepeated = repeatedAbsences.where((r) => r.classId == c.id).length;
      final cCases = scopedCases.where((cs) => cs.classId == c.id).toList();
      final cOpenCases = cCases
          .where((cs) => cs.status == 'open' || cs.status == 'assigned' || cs.status == 'in_progress')
          .length;
      final cResolvedCases = cCases
          .where((cs) => cs.status == 'resolved' || cs.status == 'closed')
          .length;

      final stageName = stageMap[c.stageId] ?? 'المرحلة';

      classComparisons.add(
        ClassComparisonMetric(
          classId: c.id,
          className: c.name,
          stageId: c.stageId,
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

    // Sort class comparisons by attendance rate desc
    classComparisons.sort((a, b) => b.attendanceRate.compareTo(a.attendanceRate));

    // 11. Servant Workload
    final profiles = await (_db.select(_db.cachedProfiles)
          ..where((t) => t.serviceId.equals(serviceId)))
        .get();

    final assignments = await (_db.select(_db.cachedFollowUpCaseAssignments)
          ..where((t) => t.assignmentStatus.equals('active')))
        .get();

    final servantWorkloads = <ServantWorkloadMetric>[];
    for (final p in profiles) {
      if (effectiveClassIds != null && p.classId != null && !effectiveClassIds.contains(p.classId)) {
        continue;
      }
      final servantCaseIds = assignments
          .where((a) => a.servantId == p.id && caseIds.contains(a.caseId))
          .map((a) => a.caseId)
          .toSet();

      final servantActivities =
          activities.where((act) => act.createdBy == p.id).length;

      final className = p.classId != null ? classMap[p.classId]?.name : null;

      servantWorkloads.add(
        ServantWorkloadMetric(
          servantId: p.id,
          servantName: p.name,
          role: p.role,
          classId: p.classId,
          className: className,
          assignedCasesCount: servantCaseIds.length,
          activeCasesCount: servantCaseIds.length,
          completedActivitiesCount: servantActivities,
        ),
      );
    }

    // 12. Student Analytics & Attendance Tiers
    final tierCounts = {'90-100%': 0, '75-89%': 0, '50-74%': 0, '<50%': 0};
    for (final s in scopedStudents) {
      final enrollment = studentEnrollment[s.id];
      var sExp = 0;
      for (final m in meetings) {
        final mDate = DateTime.parse(m.meetingDate);
        if (enrollment == null || !mDate.isBefore(enrollment)) {
          sExp++;
        }
      }
      final attended = (studentAttendedMeetings[s.id] ?? <String>{}).length;
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
        scopedStudents.where((s) => s.approvalStatus == 'approved').length;
    final pendingCount =
        scopedStudents.where((s) => s.approvalStatus == 'pending').length;

    final studentAnalytics = StudentAnalytics(
      activeStudents: activeCount,
      pendingStudents: pendingCount,
      attendanceTiers: tierCounts,
      improvingCount: 0,
      decliningCount: repeatedAbsences.length,
    );

    // 13. Deterministic Actionable Insights (مؤشرات تحتاج إلى تدخل)
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

    // 14. Previous Period Comparison (if enabled)
    double? prevRate;
    if (compareWithPrevious && meetings.isNotEmpty) {
      final duration = end.difference(start);
      final days = duration.inDays <= 0 ? 7 : duration.inDays + 1;
      final prevEnd = start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(Duration(days: days - 1));

      final prevStartStr = DateFormat('yyyy-MM-dd').format(prevStart);
      final prevEndStr = DateFormat('yyyy-MM-dd').format(prevEnd);

      final prevMeetings = await (_db.select(_db.cachedMeetings)
            ..where(
              (t) =>
                  t.serviceId.equals(serviceId) &
                  t.meetingDate.isBiggerOrEqualValue(prevStartStr) &
                  t.meetingDate.isSmallerOrEqualValue(prevEndStr),
            ))
          .get();

      if (prevMeetings.isNotEmpty) {
        var prevExpected = 0;
        for (final student in scopedStudents) {
          final enrollment = studentEnrollment[student.id];
          for (final pm in prevMeetings) {
            final pmDate = DateTime.parse(pm.meetingDate);
            if (enrollment == null || !pmDate.isBefore(enrollment)) {
              prevExpected++;
            }
          }
        }

        final prevMeetingIds = prevMeetings.map((m) => m.id).toSet();
        final prevAttendance = await (_db.select(_db.cachedAttendanceRecords)
              ..where((t) => t.meetingId.isIn(prevMeetingIds)))
            .get();

        final prevCounted = <String>{};
        var prevPresent = 0;
        for (final r in prevAttendance) {
          if (!studentIds.contains(r.studentId)) continue;
          if (prevCounted.add('${r.meetingId}:${r.studentId}')) {
            prevPresent++;
          }
        }

        if (prevExpected > 0) {
          prevRate = (prevPresent * 100.0) / prevExpected;
        }
      }
    }

    // Scoped names for display
    final scopedStageName = stageId != null ? stageMap[stageId] : null;
    final scopedClassName =
        classIds != null && classIds.length == 1 ? classMap[classIds.first]?.name : null;

    return ServiceReport(
      students: studentIds.length,
      meetings: meetings.length,
      expectedAttendance: expectedTotal,
      present: presentCount,
      early: earlyCount,
      before: beforeCount,
      normal: normalCount,
      followUps: legacyFollowUps.length + activities.length,
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
        'students': scopedStudents.map((r) => r.name).toList(),
        'meetings': meetings.map((r) => '${r.meetingDate} • ${r.startTime}').toList(),
        'early': earlyItems,
        'before': beforeItems,
        'normal': normalItems,
        'attendance': attendanceItems,
        'followUps': legacyFollowUps
            .map((r) => '${r.followUpDate} • ${studentNames[r.studentId] ?? r.studentId}')
            .toList(),
      },
    );
  }
}
