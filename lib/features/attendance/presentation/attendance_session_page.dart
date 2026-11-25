import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/app_colors.dart';
import '../../../app/design/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../service/presentation/service_providers.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/entities/attendance_record.dart';
import 'attendance_providers.dart';
import 'meeting_providers.dart';
import 'qr_scan_page.dart';
import 'widgets/attendance_bottom_action_bar.dart';
import 'widgets/attendance_filter.dart';
import 'widgets/attendance_review_sheet.dart';
import 'widgets/attendance_search_filter_bar.dart';
import 'widgets/attendance_session_header.dart';
import 'widgets/attendance_skeleton_roster.dart';
import 'widgets/attendance_student_tile.dart';
import 'widgets/register_student_dialog.dart';

class AttendanceSessionPage extends ConsumerStatefulWidget {
  const AttendanceSessionPage({
    super.key,
    required this.serviceId,
    required this.classId,
    required this.meetingId,
    required this.recordedBy,
  });

  final String serviceId, classId, meetingId, recordedBy;

  @override
  ConsumerState<AttendanceSessionPage> createState() =>
      _AttendanceSessionPageState();
}

class _AttendanceSessionPageState extends ConsumerState<AttendanceSessionPage> {
  String query = '';
  String? busyStudentId;
  TimeOfDay meetingTime = const TimeOfDay(hour: 15, minute: 0);
  DateTime _meetingDate = DateTime.now();
  String _meetingName = 'اجتماع الخدمة';
  int earlyAttendanceMinutes = 15;
  bool openingQrScanner = false;
  bool _readOnly = true;
  AttendanceFilter _filter = AttendanceFilter.all;
  Map<String, String> _classNames = {};
  List<Student> _studentsSnapshot = const [];

  bool get _allStudentsMode => widget.classId == 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadClassNames);
    Future.microtask(_loadMeetingMetadata);
    Future.microtask(() async {
      try {
        final service = await ref
            .read(serviceRepositoryProvider)
            .getService(widget.serviceId);
        if (!mounted || service == null) return;
        setState(() {
          earlyAttendanceMinutes = service.earlyAttendanceMinutes;
        });
      } catch (_) {}
    });
    // Sync remote attendance into local cache so check-ins from other
    // devices are visible and duplicates are prevented.
    Future.microtask(() async {
      try {
        await ref
            .read(attendanceRepositoryProvider)
            .refreshAttendanceForMeeting(widget.meetingId);
      } catch (_) {}
    });
    if (_allStudentsMode) {
      Future.microtask(() async {
        try {
          await ref
              .read(studentRepositoryProvider)
              .refreshStudentsForService(widget.serviceId);
        } catch (_) {}
      });
    }
  }

  Future<void> _loadMeetingMetadata() async {
    try {
      final meetings = await ref
          .read(meetingRepositoryProvider)
          .watchMeetings(widget.serviceId)
          .first;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected =
          meetings.where((meeting) => meeting.id == widget.meetingId);
      final selectedMeeting = selected.isEmpty ? null : selected.first;
      final active = meetings.where((meeting) {
        final date = meeting.meetingDate;
        final isNotFuture =
            !DateTime(date.year, date.month, date.day).isAfter(today);
        if (!isNotFuture || selectedMeeting == null) return isNotFuture;
        return selectedMeeting.scheduleId != null
            ? meeting.scheduleId == selectedMeeting.scheduleId
            : meeting.scheduleId == null &&
                meeting.name == selectedMeeting.name;
      }).toList()
        ..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
      final latestDay = active.isEmpty
          ? null
          : DateTime(
              active.first.meetingDate.year,
              active.first.meetingDate.month,
              active.first.meetingDate.day,
            );
      final selectedDay = selectedMeeting == null
          ? null
          : DateTime(
              selectedMeeting.meetingDate.year,
              selectedMeeting.meetingDate.month,
              selectedMeeting.meetingDate.day,
            );
      if (mounted) {
        setState(() {
          _readOnly = latestDay == null ||
              selectedDay == null ||
              selectedDay != latestDay;
          if (selectedMeeting != null) {
            _meetingName = selectedMeeting.name;
            _meetingDate = selectedMeeting.meetingDate;
            final parts = selectedMeeting.startTime.split(':');
            meetingTime = TimeOfDay(
              hour: int.tryParse(parts.first) ?? 15,
              minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
            );
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadClassNames() async {
    try {
      final repository = ref.read(serviceRepositoryProvider);
      final stages = await repository.getStages(widget.serviceId);
      final names = <String, String>{};
      for (final stage in stages) {
        for (final item in await repository.getClasses(stage.id)) {
          names[item.id] = item.name;
        }
      }
      if (mounted) setState(() => _classNames = names);
    } catch (_) {
      // Class names may not be cached yet; attendance must remain usable offline.
    }
  }

  String _classIdFor(Student student) =>
      student.currentClassId ??
      student.proposedClassId ??
      (_allStudentsMode ? 'unassigned' : widget.classId);

  String _classLabelFor(Student student) {
    final id = _classIdFor(student);
    if (id == 'unassigned') return 'بدون فصل محدد';
    return _classNames[id] ??
        (_allStudentsMode ? 'فصل غير محدد' : 'الفصل المحدد');
  }

  Color _classColorFor(BuildContext context, String id) {
    final palette = <Color>[
      Theme.of(context).colorScheme.primary,
      const Color(0xFF0D9488),
      const Color(0xFFB45309),
      const Color(0xFF475569),
      const Color(0xFF0369A1),
      const Color(0xFFBE123C),
    ];
    final stableHash = id.codeUnits.fold<int>(0, (value, unit) => value + unit);
    return palette[stableHash % palette.length];
  }

  Future<void> _checkIn(Student student) async {
    if (_readOnly) return;
    if (busyStudentId != null) return;
    final classId = student.currentClassId ??
        student.proposedClassId ??
        (_allStudentsMode ? null : widget.classId);
    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تسجيل الحضور قبل إسناد التلميذ إلى فصل.'),
        ),
      );
      return;
    }
    if (student.membershipId == null || student.serviceId != widget.serviceId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تسجيل الحضور بدون عضوية صحيحة في هذه الخدمة.'),
        ),
      );
      return;
    }
    setState(() => busyStudentId = student.id);
    try {
      await ref.read(attendanceRepositoryProvider).checkIn(
            meetingId: widget.meetingId,
            studentId: student.id,
            serviceId: student.serviceId,
            serviceStudentId: student.membershipId!,
            classIdAtAttendance: classId,
            recordedBy: widget.recordedBy,
            checkedInAt: DateTime.now(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل حضور ${student.name} بنجاح.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تسجيل الحضور: $e')));
      }
    } finally {
      if (mounted) setState(() => busyStudentId = null);
    }
  }

  Future<void> _register() async {
    if (_readOnly) return;
    if (_allStudentsMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'أضف التلميذ من الفصل المقترح أولاً، ثم سجّل حضوره من القائمة العامة.',
          ),
        ),
      );
      return;
    }
    final details = await showDialog<NewStudentDetails>(
      context: context,
      builder: (_) => const RegisterStudentDialog(),
    );
    if (details == null) return;
    final isOffline = ref.read(offlineSyncEnabledProvider);
    try {
      await ref.read(studentRegistrationProvider).registerPending(
            serviceId: widget.serviceId,
            proposedClassId: widget.classId,
            name: details.name,
            birthDate: details.birthDate,
            phone: details.phone,
            school: details.school,
            grade: details.grade,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'تم حفظ التلميذ محليًا كـ Pending وسيتم مزامنته.'
                : 'تم تسجيل التلميذ بنجاح وبانتظار الاعتماد.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تسجيل التلميذ: ${NetworkErrorFormatter.format(e)}',
          ),
        ),
      );
    }
  }

  Future<void> _editAttendance(
    String attendanceId,
    DateTime currentTime,
  ) async {
    if (_readOnly) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
      helpText: 'تعديل وقت تسجيل الحضور',
    );
    if (time == null || !mounted) return;
    final updated = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      time.hour,
      time.minute,
    );
    await ref
        .read(attendanceRepositoryProvider)
        .updateCheckedInAt(attendanceId: attendanceId, checkedInAt: updated);
    if (mounted) setState(() {});
  }

  Future<void> _openQrScanner(List<Student> students) async {
    if (_readOnly) return;
    if (openingQrScanner) return;
    setState(() => openingQrScanner = true);
    try {
      final attendance = await ref
          .read(attendanceRepositoryProvider)
          .watchForMeeting(widget.meetingId)
          .first;
      if (!mounted) return;

      final studentId =
          await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(
          builder: (_) => QrScanPage(
            students: students,
            presentStudentIds:
                attendance.map((record) => record.studentId).toSet(),
          ),
        ),
      );
      if (!mounted || studentId == null) return;

      for (final student in students) {
        if (student.id == studentId) {
          await _checkIn(student);
          break;
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح ماسح QR: $error')));
      }
    } finally {
      if (mounted) setState(() => openingQrScanner = false);
    }
  }

  Future<void> _review(List<Student> students) async {
    final records = await ref
        .read(attendanceRepositoryProvider)
        .watchForMeeting(widget.meetingId)
        .first;
    final presentIds = records.map((record) => record.studentId).toSet();
    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
          isDark ? AppDesignColors.darkSurface : AppDesignColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => AttendanceReviewSheet(
        students: students,
        presentIds: presentIds,
        allStudentsMode: _allStudentsMode,
        readOnly: _readOnly,
      ),
    );
  }

  String _attendanceLabel(DateTime checkedInAt) {
    final start = DateTime(
      checkedInAt.year,
      checkedInAt.month,
      checkedInAt.day,
      meetingTime.hour,
      meetingTime.minute,
    );
    final earlyEnd = start.add(Duration(minutes: earlyAttendanceMinutes));
    if (checkedInAt.isBefore(start)) return 'قبل الاجتماع';
    if (checkedInAt.isBefore(earlyEnd)) return 'مبكر';
    return 'عادي';
  }

  @override
  Widget build(BuildContext context) {
    final studentRepository = ref.watch(studentRepositoryProvider);
    final studentsStream = _allStudentsMode
        ? studentRepository.watchStudentsForService(widget.serviceId)
        : studentRepository.watchStudentsForClass(widget.classId);

    final displayClassName = _allStudentsMode
        ? 'كل طلاب الخدمة'
        : (_classNames[widget.classId] ?? 'تسجيل حضور الفصل');
    final formattedDate = AppDateFormatter.format(_meetingDate);

    return Scaffold(
      key: const Key('attendance_session'),
      appBar: AppBar(
        title: const Text(
          'تسجيل الحضور',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const Key('attendance_review'),
            tooltip: 'مراجعة الحضور',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () => _review(_studentsSnapshot),
          ),
          if (!_readOnly && !_allStudentsMode)
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              tooltip: 'تلميذ جديد',
              onPressed: _register,
            ),
        ],
      ),
      body: StreamBuilder<List<Student>>(
        stream: studentsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppDesignColors.lightError,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'تعذر تحميل قائمة التلاميذ',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AttendanceSkeletonRoster(),
            );
          }

          final allStudents = snapshot.data!;
          _studentsSnapshot = allStudents;

          return StreamBuilder<List<AttendanceRecord>>(
            stream: ref
                .watch(attendanceRepositoryProvider)
                .watchForMeeting(widget.meetingId),
            builder: (context, attendanceSnapshot) {
              final records = attendanceSnapshot.data ?? const [];
              final checkedMap = {
                for (final row in records) row.studentId: row,
              };

              final totalCount = allStudents.length;
              final studentIds =
                  allStudents.map((student) => student.id).toSet();
              final relevantRecords = records
                  .where((record) => studentIds.contains(record.studentId))
                  .toList();
              final presentCount = allStudents
                  .where((student) => checkedMap.containsKey(student.id))
                  .length;
              final absentCount =
                  totalCount > presentCount ? totalCount - presentCount : 0;
              final isPendingSync =
                  relevantRecords.any((record) => record.syncState == 'pending');
              final pendingCount = allStudents.where((s) => s.isPending).length;

              // Filter students
              final filtered = allStudents.where((s) {
                final matchesQuery =
                    s.name.toLowerCase().contains(query.trim().toLowerCase());
                if (!matchesQuery) return false;
                final isChecked = checkedMap.containsKey(s.id);
                switch (_filter) {
                  case AttendanceFilter.all:
                    return true;
                  case AttendanceFilter.present:
                    return isChecked;
                  case AttendanceFilter.absent:
                    return !isChecked;
                  case AttendanceFilter.pending:
                    return s.isPending;
                }
              }).toList()
                ..sort((a, b) {
                  if (_allStudentsMode) {
                    final classCompare =
                        _classLabelFor(a).compareTo(_classLabelFor(b));
                    if (classCompare != 0) return classCompare;
                    final classIdCompare =
                        _classIdFor(a).compareTo(_classIdFor(b));
                    if (classIdCompare != 0) return classIdCompare;
                  }
                  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                });

              return Column(
                children: [
                  // 1. Sticky Header
                  AttendanceSessionHeader(
                    className: displayClassName,
                    meetingName: _meetingName,
                    meetingDateFormatted: formattedDate,
                    presentCount: presentCount,
                    absentCount: absentCount,
                    totalCount: totalCount,
                    isPendingSync: isPendingSync,
                    readOnly: _readOnly,
                    onSyncNow: ref.watch(offlineSyncEnabledProvider)
                        ? () {
                            try {
                              ref.read(syncEngineProvider).syncNow();
                            } catch (_) {}
                          }
                        : null,
                  ),

                  // 2. Search & Filter Bar
                  AttendanceSearchFilterBar(
                    query: query,
                    onQueryChanged: (v) => setState(() => query = v),
                    filter: _filter,
                    onFilterChanged: (f) => setState(() => _filter = f),
                    totalCount: totalCount,
                    presentCount: presentCount,
                    absentCount: absentCount,
                    pendingCount: pendingCount,
                  ),

                  // 3. Scrollable Student Roster
                  Expanded(
                    child: allStudents.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  EmptyState(
                                    icon: Icons.people_outline,
                                    title: _allStudentsMode
                                        ? 'لا يوجد تلاميذ في الخدمة'
                                        : 'لا يوجد تلاميذ في هذا الفصل',
                                    message: _allStudentsMode
                                        ? 'تأكد من إضافة وتسكين التلاميذ في المراحل والفصول.'
                                        : 'أضف تلميذًا جديدًا للبدء في تسجيل الحضور.',
                                  ),
                                  if (!_readOnly && !_allStudentsMode) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    FilledButton.icon(
                                      onPressed: _register,
                                      icon: const Icon(Icons.person_add_rounded),
                                      label: const Text('إضافة تلميذ جديد'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : filtered.isEmpty
                            ? Center(
                                child: EmptyState(
                                  icon: Icons.search_off_rounded,
                                  title: 'لم يتم العثور على نتائج',
                                  message: query.isNotEmpty
                                      ? 'لا يوجد تلميذ يطابق "$query"'
                                      : 'لا يوجد تلاميذ في هذا الفلتر',
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.xs,
                                  AppSpacing.md,
                                  AppSpacing.xl,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.xs),
                                itemBuilder: (context, i) {
                                  final student = filtered[i];
                                  final record = checkedMap[student.id];
                                  final isBusy = busyStudentId == student.id;
                                  final classId = _classIdFor(student);
                                  final classColor =
                                      _classColorFor(context, classId);
                                  final previousClassId = i == 0
                                      ? null
                                      : _classIdFor(filtered[i - 1]);
                                  final showClassHeader = _allStudentsMode &&
                                      classId != previousClassId;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (showClassHeader)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            2,
                                            12,
                                            2,
                                            4,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  color: classColor,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _classLabelFor(student),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: classColor.withValues(
                                                    alpha: .10,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${filtered.where((item) => _classIdFor(item) == classId).length} تلميذ',
                                                  style: TextStyle(
                                                    color: classColor,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      AttendanceStudentTile(
                                        student: student,
                                        record: record,
                                        isBusy: isBusy,
                                        readOnly: _readOnly,
                                        classColor: classColor,
                                        classLabel: _allStudentsMode
                                            ? _classLabelFor(student)
                                            : '',
                                        attendanceTimingLabel: record != null
                                            ? _attendanceLabel(
                                                record.checkedInAt,
                                              )
                                            : '',
                                        onCheckIn: () => _checkIn(student),
                                        onEditTime: () {
                                          if (record != null) {
                                            _editAttendance(
                                              record.id,
                                              record.checkedInAt,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: AttendanceBottomActionBar(
        readOnly: _readOnly,
        openingQrScanner: openingQrScanner,
        onOpenQrScanner: () => _openQrScanner(_studentsSnapshot),
        onReview: () => _review(_studentsSnapshot),
      ),
    );
  }
}
