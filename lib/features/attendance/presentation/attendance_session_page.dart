import 'package:church_service_management_system/app/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/domain/entities/student.dart';
import '../../students/data/offline_first_student_registration.dart';
import '../../students/presentation/student_providers.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/sync/sync_status_widget.dart';
import 'attendance_providers.dart';
import 'qr_scan_page.dart';
import '../../service/presentation/service_providers.dart';

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
  bool openingQrScanner = false;

  bool get _allStudentsMode => widget.classId == 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final service = await ref.read(serviceRepositoryProvider).getService(widget.serviceId);
        if (!mounted || service == null) return;
        final parts = service.meetingStartTime.split(':');
        setState(() {
          meetingTime = TimeOfDay(
            hour: int.tryParse(parts.first) ?? 15,
            minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          );
        });
      } catch (_) {}
    });
    if (_allStudentsMode) {
      Future.microtask(() async {
        try {
          await ref.read(studentRepositoryProvider).refreshStudentsForService(widget.serviceId);
        } catch (_) {}
      });
    }
  }

  Future<void> _checkIn(Student student) async {
    if (busyStudentId != null) return;
    final classId = student.currentClassId ??
        student.proposedClassId ??
        (_allStudentsMode ? null : widget.classId);
    if (classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تسجيل الحضور قبل إسناد التلميذ إلى فصل.')),
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
      await ref.read(syncEngineProvider).syncNow();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الحضور محليًا.')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تسجيل الحضور: $e')));
    } finally {
      if (mounted) setState(() => busyStudentId = null);
    }
  }

  Future<void> _register() async {
    if (_allStudentsMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف التلميذ من الفصل المقترح أولًا، ثم سجّل حضوره من القائمة العامة.')),
      );
      return;
    }
    final details = await showDialog<_NewStudentDetails>(
      context: context,
      builder: (_) => const _RegisterStudentDialog(),
    );
    if (details == null) return;
    final local = ref.read(localStudentRepositoryProvider);
    final queue = ref.read(syncQueueRepositoryProvider);
    await OfflineFirstStudentRegistration(
      local,
      queue,
      ref.read(appDatabaseProvider),
    ).registerPending(
      serviceId: widget.serviceId,
      proposedClassId: widget.classId,
      name: details.name,
      birthDate: details.birthDate,
      phone: details.phone,
      school: details.school,
      grade: details.grade,
    );
    await ref.read(syncEngineProvider).syncNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ التلميذ محليًا كـ Pending وسيتم مزامنته.')),
    );
  }

  Future<void> _editAttendance(
    String attendanceId,
    DateTime currentTime,
  ) async {
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
    await ref.read(syncEngineProvider).syncNow();
  }

  Future<void> _openQrScanner(Stream<List<Student>> studentsStream) async {
    if (openingQrScanner) return;
    setState(() => openingQrScanner = true);
    try {
      try {
        if (_allStudentsMode) {
          await ref.read(studentRepositoryProvider).refreshStudentsForService(widget.serviceId);
        } else {
          await ref.read(studentRepositoryProvider).refreshStudents(widget.classId);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح ماسح QR: $error')),
        );
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مراجعة الحضور',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('${presentIds.length}/${students.length}'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: students.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: _allStudentsMode ? 'لا يوجد تلاميذ في الخدمة' : 'لا يوجد تلاميذ في الفصل',
                      )
                    : ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final present = presentIds.contains(student.id);
                          return ListTile(
                            leading: Icon(
                              present
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              color: present
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            title: Text(student.name),
                            trailing: Text(present ? 'حاضر' : 'غير مسجل'),
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
                    child: const Text('متابعة تسجيل الحضور'),
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
    final earlyEnd = start.add(const Duration(minutes: 15));
    if (checkedInAt.isBefore(start)) return 'قبل بدء الاجتماع';
    if (checkedInAt.isBefore(earlyEnd)) return 'مبكر';
    return 'عادي';
  }

  @override
  Widget build(BuildContext context) {
    final studentRepository = ref.watch(studentRepositoryProvider);
    final studentsStream = _allStudentsMode
        ? studentRepository.watchStudentsForService(widget.serviceId)
        : studentRepository.watchStudentsForClass(widget.classId);
    return Scaffold(
      key: const Key('attendance_session'),
      appBar: AppBar(
        title: Text(_allStudentsMode ? 'حضور جميع طلاب الخدمة' : 'تسجيل الحضور'),
        actions: [
          IconButton(
            key: const Key('attendance_review'),
            tooltip: 'مراجعة الحضور',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () => _review(studentsStream),
          ),
          const SyncStatusWidget(),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR',
            onPressed: openingQrScanner ? null : () => _openQrScanner(studentsStream),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'تلميذ جديد',
            onPressed: _register,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(syncEngineProvider).syncNow(),
          ),
        ],
      ),
      body: StreamBuilder<List<Student>>(
        stream: studentsStream,
        builder: (context, snapshot) {
          final students = (snapshot.data ?? const <Student>[])
              .where((s) => s.name.contains(query))
              .toList();
          if (snapshot.hasError && snapshot.data == null)
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'تعذر تحميل التلاميذ',
            );
          if (!snapshot.hasData)
            return const LoadingView(message: 'جاري تحميل قائمة التلاميذ...');
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'بحث بالاسم',
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: ref
                      .watch(attendanceRepositoryProvider)
                      .watchForMeeting(widget.meetingId),
                  builder: (context, attendanceSnapshot) {
                    final records = attendanceSnapshot.data ?? const [];
                    final checked = {
                      for (final row in records) row.studentId: row,
                    };
                    if (students.isEmpty) {
                      return EmptyState(
                        icon: Icons.people_outline,
                        title: _allStudentsMode
                            ? 'لا يوجد تلاميذ في الخدمة'
                            : 'لا يوجد تلاميذ في هذا الفصل',
                      );
                    }
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final student = students[i];
                        final record = checked[student.id];
                        final present = record != null;
                        return ListTile(
                          title: Text(student.name),
                          subtitle: Text(
                            present
                                ? '${student.isPending ? 'Pending' : 'معتمد'} • ${_attendanceLabel(record.checkedInAt)} • ${TimeOfDay.fromDateTime(record.checkedInAt).format(context)}'
                                : (student.isPending
                                      ? 'Pending — يحتاج اعتماد'
                                      : 'معتمد'),
                          ),
                          trailing: present
                              ? OutlinedButton(
                                  onPressed: () => _editAttendance(
                                    record.id,
                                    record.checkedInAt,
                                  ),
                                  child: const Text('تعديل'),
                                )
                              : FilledButton(
                                  onPressed: () => _checkIn(student),
                                  child: const Text('تسجيل'),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NewStudentDetails {
  const _NewStudentDetails({required this.name, required this.phone, required this.school, required this.grade, required this.birthDate});
  final String name;
  final String? phone;
  final String? school;
  final String? grade;
  final DateTime? birthDate;
}

class _RegisterStudentDialog extends StatefulWidget {
  const _RegisterStudentDialog();
  @override
  State<_RegisterStudentDialog> createState() => _RegisterStudentDialogState();
}

class _RegisterStudentDialogState extends State<_RegisterStudentDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _school = TextEditingController();
  final _grade = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _school.dispose();
    _grade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('تسجيل تلميذ جديد'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _name, autofocus: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'اسم التلميذ *')),
      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
      TextField(controller: _school, decoration: const InputDecoration(labelText: 'المدرسة')),
      TextField(controller: _grade, decoration: const InputDecoration(labelText: 'الصف الدراسي')),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_birthDate == null ? 'تاريخ الميلاد: غير محدد' : 'تاريخ الميلاد: ${_birthDate!.toLocal().toString().split(' ').first}'),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: DateTime(2015, 1, 1), firstDate: DateTime(2000), lastDate: DateTime.now(), helpText: 'اختر تاريخ الميلاد');
          if (picked != null && mounted) setState(() => _birthDate = picked);
        },
      ),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(
        onPressed: _name.text.trim().isEmpty ? null : () => Navigator.pop(context, _NewStudentDetails(
          name: _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          school: _school.text.trim().isEmpty ? null : _school.text.trim(),
          grade: _grade.text.trim().isEmpty ? null : _grade.text.trim(),
          birthDate: _birthDate,
        )),
        child: const Text('تسجيل'),
      ),
    ],
  );
}
