import 'package:church_service_management_system/app/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/domain/entities/student.dart';
import 'widgets/register_student_dialog.dart';
import '../../students/presentation/student_providers.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../../core/sync/sync_status_widget.dart';
import '../domain/entities/attendance_record.dart';
import 'attendance_providers.dart';
import 'qr_scan_page.dart';
import '../../service/presentation/service_providers.dart';
import 'meeting_providers.dart';

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
  int earlyAttendanceMinutes = 15;
  bool openingQrScanner = false;
  bool _readOnly = true;
  _AttendanceFilter _filter = _AttendanceFilter.all;

  bool get _allStudentsMode => widget.classId == 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final meetings = await ref.read(meetingRepositoryProvider).watchMeetings(widget.serviceId).first;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final active = meetings.where((meeting) {
          final date = meeting.meetingDate;
          return !DateTime(date.year, date.month, date.day).isAfter(today);
        }).toList()..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
        if (mounted) setState(() => _readOnly = active.isEmpty || active.first.id != widget.meetingId);
      } catch (_) {}
    });
    Future.microtask(() async {
      try {
        final service = await ref
            .read(serviceRepositoryProvider)
            .getService(widget.serviceId);
        if (!mounted || service == null) return;
        final parts = service.meetingStartTime.split(':');
        setState(() {
          meetingTime = TimeOfDay(
            hour: int.tryParse(parts.first) ?? 15,
            minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          );
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

  Future<void> _checkIn(Student student) async {
    if (_readOnly) return;
    if (busyStudentId != null) return;
    final classId =
        student.currentClassId ??
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
    setState(() => busyStudentId = student.id);
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .checkIn(
            meetingId: widget.meetingId,
            studentId: student.id,
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
            'أضف التلميذ من الفصل المقترح أولًا، ثم سجّل حضوره من القائمة العامة.',
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
      await ref
          .read(studentRegistrationProvider)
          .registerPending(
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
        SnackBar(content: Text('تعذر تسجيل التلميذ: ${NetworkErrorFormatter.format(e)}')),
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
  }

  Future<void> _openQrScanner(Stream<List<Student>> studentsStream) async {
    if (_readOnly) return;
    if (openingQrScanner) return;
    setState(() => openingQrScanner = true);
    try {
      try {
        if (_allStudentsMode) {
          await ref
              .read(studentRepositoryProvider)
              .refreshStudentsForService(widget.serviceId);
        } else {
          await ref
              .read(studentRepositoryProvider)
              .refreshStudents(widget.classId);
        }
      } catch (_) {}

      final students = await studentsStream.first;
      final attendance = await ref
          .read(attendanceRepositoryProvider)
          .watchForMeeting(widget.meetingId)
          .first;
      if (!mounted) return;

      final studentId = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => QrScanPage(
            students: students,
            presentStudentIds: attendance
                .map((record) => record.studentId)
                .toSet(),
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

  Future<void> _review(Stream<List<Student>> studentsStream) async {
    final students = await studentsStream.first;
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
      backgroundColor: isDark
          ? const Color(0xF7131D33)
          : const Color(0xF7FFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fact_check_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مراجعة الحضور',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'نسبة الحضور: ${presentIds.length} من أصل ${students.length}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    GlassBadge(
                      label: '${presentIds.length}/${students.length}',
                      color: theme.colorScheme.primary,
                      showDot: false,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: students.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: _allStudentsMode
                            ? 'لا يوجد تلاميذ في الخدمة'
                            : 'لا يوجد تلاميذ في الفصل',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: students.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final present = presentIds.contains(student.id);
                          return SolidCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  present
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_outlined,
                                  color: present
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF94A3B8),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                GlassBadge(
                                  label: present ? 'حاضر' : 'غير مسجل',
                                  color: present
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                  showDot: present,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_readOnly ? 'إغلاق' : 'متابعة تسجيل الحضور'),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Color _attendanceColor(DateTime checkedInAt) {
    final label = _attendanceLabel(checkedInAt);
    if (label == 'مبكر') return const Color(0xFFD97706); // Amber
    if (label == 'عادي') return const Color(0xFF059669); // Green
    if (label == 'قبل الاجتماع') return const Color(0xFF4F46E5);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final studentRepository = ref.watch(studentRepositoryProvider);
    final studentsStream = _allStudentsMode
        ? studentRepository.watchStudentsForService(widget.serviceId)
        : studentRepository.watchStudentsForClass(widget.classId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: const Key('attendance_session'),
      appBar: AppBar(
        title: Text(
          _allStudentsMode ? 'حضور جميع طلاب الخدمة' : 'تسجيل الحضور',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const Key('attendance_review'),
            tooltip: 'مراجعة الحضور',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () => _review(studentsStream),
          ),
          const SyncStatusWidget(),
          if (!_readOnly) IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'تلميذ جديد',
            onPressed: _register,
          ),
          if (ref.watch(offlineSyncEnabledProvider))
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'مزامنة الآن',
              onPressed: () => ref.read(syncEngineProvider).syncNow(),
            ),
        ],
      ),
      body: StreamBuilder<List<Student>>(
        stream: studentsStream,
        builder: (context, snapshot) {
          final allStudents = snapshot.data ?? const <Student>[];
          if (snapshot.hasError && snapshot.data == null) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'تعذر تحميل التلاميذ',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingView(message: 'جاري تحميل قائمة التلاميذ...');
          }

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
              final presentCount = checkedMap.length;
              final absentCount = totalCount > presentCount
                  ? totalCount - presentCount
                  : 0;
              int earlyCount = 0;
              int normalCount = 0;
              for (final rec in records) {
                final label = _attendanceLabel(rec.checkedInAt);
                if (label == 'مبكر') earlyCount++;
                if (label == 'عادي') normalCount++;
              }

              // Filter students
              final filtered = allStudents.where((s) {
                final matchesQuery = s.name.contains(query);
                if (!matchesQuery) return false;
                final isChecked = checkedMap.containsKey(s.id);
                switch (_filter) {
                  case _AttendanceFilter.all:
                    return true;
                  case _AttendanceFilter.present:
                    return isChecked;
                  case _AttendanceFilter.absent:
                    return !isChecked;
                  case _AttendanceFilter.pending:
                    return s.isPending;
                }
              }).toList();

              return AppContent(
                maxWidth: 1000,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_readOnly)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64748B).withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(children: [
                          Icon(Icons.lock_outline_rounded),
                          SizedBox(width: 10),
                          Expanded(child: Text('اجتماع سابق — العرض فقط، تم إيقاف تعديل وتسجيل الحضور.')),
                        ]),
                      ),
                    // Top Overview Banner & KPI Cards
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 14),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4338CA),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.event_note_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _allStudentsMode
                                          ? 'جلسة حضور الخدمة العامة'
                                          : 'جلسة الحضور الميداني',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'بداية الاجتماع: ${meetingTime.format(context)} • الحضور المبكر حتى ${TimeOfDay.fromDateTime(DateTime(2020, 1, 1, meetingTime.hour, meetingTime.minute).add(Duration(minutes: earlyAttendanceMinutes))).format(context)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Fast QR Scan Hero CTA
                              if (!_readOnly) FilledButton.icon(
                                onPressed: openingQrScanner
                                    ? null
                                    : () => _openQrScanner(studentsStream),
                                icon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 20,
                                ),
                                label: const Text('مسح QR'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // KPI Mini Tiles
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _KpiPill(
                                label: 'إجمالي المقيدين',
                                value: '$totalCount',
                                icon: Icons.groups_rounded,
                                color: const Color(0xFF4F46E5),
                              ),
                              _KpiPill(
                                label: 'حاضر',
                                value: '$presentCount',
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF059669),
                              ),
                              _KpiPill(
                                label: 'غائب',
                                value: '$absentCount',
                                icon: Icons.cancel_outlined,
                                color: const Color(0xFFDC2626),
                              ),
                              _KpiPill(
                                label: 'مبكر',
                                value: '$earlyCount',
                                icon: Icons.star_rounded,
                                color: const Color(0xFFD97706),
                              ),
                              _KpiPill(
                                label: 'قبل الاجتماع',
                                value: '${records.where((r) => _attendanceLabel(r.checkedInAt) == 'قبل الاجتماع').length}',
                                icon: Icons.access_time_filled_rounded,
                                color: const Color(0xFF4F46E5),
                              ),
                              _KpiPill(
                                label: 'عادي',
                                value: '$normalCount',
                                icon: Icons.schedule_rounded,
                                color: const Color(0xFF0D9488),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search and Filter Bar
                    SolidCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      borderRadius: 16,
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (v) => setState(() => query = v),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 22,
                              ),
                              hintText: 'ابحث باسم التلميذ...',
                              suffixIcon: query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          setState(() => query = ''),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                          const Divider(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChipButton(
                                  label: 'الكل ($totalCount)',
                                  selected: _filter == _AttendanceFilter.all,
                                  onTap: () => setState(
                                    () => _filter = _AttendanceFilter.all,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _FilterChipButton(
                                  label: 'حاضر ($presentCount)',
                                  selected:
                                      _filter == _AttendanceFilter.present,
                                  color: const Color(0xFF059669),
                                  onTap: () => setState(
                                    () => _filter = _AttendanceFilter.present,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _FilterChipButton(
                                  label: 'غائب ($absentCount)',
                                  selected: _filter == _AttendanceFilter.absent,
                                  color: const Color(0xFFDC2626),
                                  onTap: () => setState(
                                    () => _filter = _AttendanceFilter.absent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _FilterChipButton(
                                  label: 'بانتظار الاعتماد',
                                  selected:
                                      _filter == _AttendanceFilter.pending,
                                  color: const Color(0xFFD97706),
                                  onTap: () => setState(
                                    () => _filter = _AttendanceFilter.pending,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Student Roster
                    if (filtered.isEmpty)
                      Expanded(
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'لم يتم العثور على نتائج',
                          message: query.isNotEmpty
                              ? 'لا يوجد تلميذ يطابق "$query"'
                              : 'لا يوجد تلاميذ في هذا الفلتر',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final student = filtered[i];
                            final record = checkedMap[student.id];
                            final isPresent = record != null;
                            final isBusy = busyStudentId == student.id;

                            return SolidCard(
                              key: ValueKey(student.id),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              borderRadius: 16,
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: isPresent
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF059669),
                                                Color(0xFF10B981),
                                              ],
                                            )
                                          : (student.isPending
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFD97706),
                                                      Color(0xFFF59E0B),
                                                    ],
                                                  )
                                                : (isDark
                                                      ? const LinearGradient(
                                                          colors: [
                                                            Color(0xFF1E293B),
                                                            Color(0xFF334155),
                                                          ],
                                                        )
                                                      : const LinearGradient(
                                                          colors: [
                                                            Color(0xFFE2E8F0),
                                                            Color(0xFFCBD5E1),
                                                          ],
                                                        ))),
                                      boxShadow: isPresent
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF059669,
                                                ).withValues(alpha: 0.35),
                                                blurRadius: 10,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: isPresent
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          )
                                        : Text(
                                            student.name.isNotEmpty
                                                ? student.name.characters.first
                                                : 'ت',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Student Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (student.isPending)
                                              const GlassBadge(
                                                label: 'بانتظار الاعتماد',
                                                color: Color(0xFFD97706),
                                                showDot: true,
                                              ),
                                            if (isPresent) ...[
                                              GlassBadge(
                                                label: _attendanceLabel(
                                                  record.checkedInAt,
                                                ),
                                                color: _attendanceColor(
                                                  record.checkedInAt,
                                                ),
                                                showDot: false,
                                              ),
                                              Text(
                                                TimeOfDay.fromDateTime(
                                                  record.checkedInAt,
                                                ).format(context),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ] else ...[
                                              Text(
                                                'غير مسجل',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? const Color(0xFF64748B)
                                                      : const Color(0xFF94A3B8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Button
                                  if (isPresent)
                                    OutlinedButton.icon(
                                      onPressed: _readOnly ? null : () => _editAttendance(
                                        record.id,
                                        record.checkedInAt,
                                      ),
                                      icon: const Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('تعديل'),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(80, 40),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                      ),
                                    )
                                  else
                                    FilledButton.icon(
                                      onPressed: _readOnly || isBusy
                                          ? null
                                          : () => _checkIn(student),
                                      icon: isBusy
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.how_to_reg_rounded,
                                              size: 18,
                                            ),
                                      label: const Text('تسجيل'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF059669,
                                        ),
                                        minimumSize: const Size(88, 42),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _AttendanceFilter { all, present, absent, pending }

class _KpiPill extends StatelessWidget {
  const _KpiPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF4F46E5);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor
              : effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? effectiveColor
                : effectiveColor.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : effectiveColor,
          ),
        ),
      ),
    );
  }
}
