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

class AttendanceSessionPage extends ConsumerStatefulWidget {
  const AttendanceSessionPage({super.key, required this.serviceId, required this.classId, required this.meetingId, required this.recordedBy});
  final String serviceId, classId, meetingId, recordedBy;
  @override ConsumerState<AttendanceSessionPage> createState() => _AttendanceSessionPageState();
}

class _AttendanceSessionPageState extends ConsumerState<AttendanceSessionPage> {
  String query = '';
  String? busyStudentId;

  Future<void> _checkIn(Student student) async {
    if (busyStudentId != null) return;
    setState(() => busyStudentId = student.id);
    try {
      await ref.read(attendanceRepositoryProvider).checkIn(
      meetingId: widget.meetingId, studentId: student.id,
      classIdAtAttendance: student.currentClassId ?? widget.classId,
      recordedBy: widget.recordedBy, checkedInAt: DateTime.now(),
    );
    await ref.read(syncEngineProvider).syncNow();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الحضور محليًا.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تسجيل الحضور: $e')));
    } finally {
      if (mounted) setState(() => busyStudentId = null);
    }
  }

  Future<void> _register() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final schoolController = TextEditingController();
    final gradeController = TextEditingController();
    DateTime? birthDate;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('تسجيل تلميذ جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'اسم التلميذ *')),
                  TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
                  TextField(controller: schoolController, decoration: const InputDecoration(labelText: 'المدرسة')),
                  TextField(controller: gradeController, decoration: const InputDecoration(labelText: 'الصف الدراسي')),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(birthDate == null ? 'تاريخ الميلاد: غير محدد' : 'تاريخ الميلاد: ${birthDate!.toLocal().toString().split(' ').first}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2015, 1, 1),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        helpText: 'اختر تاريخ الميلاد',
                      );
                      if (picked != null) setDialogState(() => birthDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: nameController.text.trim().isEmpty ? null : () => Navigator.pop(dialogContext, true),
                child: const Text('تسجيل'),
              ),
            ],
          ),
        ),
      );

      if (result != true) return;
      final local = ref.read(localStudentRepositoryProvider);
      final queue = ref.read(syncQueueRepositoryProvider);
      await OfflineFirstStudentRegistration(local, queue, ref.read(appDatabaseProvider)).registerPending(
        serviceId: widget.serviceId,
        proposedClassId: widget.classId,
        name: nameController.text.trim(),
        birthDate: birthDate,
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        school: schoolController.text.trim().isEmpty ? null : schoolController.text.trim(),
        grade: gradeController.text.trim().isEmpty ? null : gradeController.text.trim(),
      );
      await ref.read(syncEngineProvider).syncNow();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التلميذ محليًا كـ Pending وسيتم مزامنته.')),
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      schoolController.dispose();
      gradeController.dispose();
    }
  }

  Future<void> _editAttendance(String attendanceId, DateTime currentTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
      helpText: 'تعديل وقت تسجيل الحضور',
    );
    if (time == null || !mounted) return;
    final updated = DateTime(currentTime.year, currentTime.month, currentTime.day, time.hour, time.minute);
    await ref.read(attendanceRepositoryProvider).updateCheckedInAt(
      attendanceId: attendanceId,
      checkedInAt: updated,
    );
    await ref.read(syncEngineProvider).syncNow();
  }

  String _attendanceLabel(DateTime checkedInAt) {
    final start = DateTime(checkedInAt.year, checkedInAt.month, checkedInAt.day, 15);
    final earlyEnd = start.add(const Duration(minutes: 15));
    if (checkedInAt.isBefore(start)) return 'قبل بدء الاجتماع';
    if (checkedInAt.isBefore(earlyEnd)) return 'مبكر';
    return 'عادي';
  }

  @override
  Widget build(BuildContext context) {
    final studentsStream = ref.watch(studentRepositoryProvider).watchStudentsForClass(widget.classId);
    return Scaffold(
      key: const Key('attendance_session'),
      appBar: AppBar(title: const Text('تسجيل الحضور'), actions: [const SyncStatusWidget(),
        IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: 'QR', onPressed: () async {
          final id = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScanPage()));
          if (id == null) return;
          final students = await studentsStream.first;
          final match = students.where((s) => s.id == id).toList();
          if (match.isEmpty) { if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR غير مرتبط بتلميذ في هذا الفصل.'))); return; }
          await _checkIn(match.first);
        }),
        IconButton(icon: const Icon(Icons.person_add), tooltip: 'تلميذ جديد', onPressed: _register),
        IconButton(icon: const Icon(Icons.sync), onPressed: () => ref.read(syncEngineProvider).syncNow()),
      ]),
      body: StreamBuilder<List<Student>>(
        stream: studentsStream,
        builder: (context, snapshot) {
          final students = (snapshot.data ?? const <Student>[]).where((s) => s.name.contains(query)).toList();
          return Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'بحث بالاسم'))),
            Expanded(child: StreamBuilder(
              stream: ref.watch(attendanceRepositoryProvider).watchForMeeting(widget.meetingId),
              builder: (context, attendanceSnapshot) {
                final records = attendanceSnapshot.data ?? const [];
                final checked = {for (final row in records) row.studentId: row};
                return ListView.builder(itemCount: students.length, itemBuilder: (_, i) {
                  final student = students[i];
                  final record = checked[student.id];
                  final present = record != null;
                  return ListTile(
                    title: Text(student.name),
                    subtitle: Text(
                      present
                          ? '${student.isPending ? 'Pending' : 'معتمد'} • ${_attendanceLabel(record.checkedInAt)} • ${TimeOfDay.fromDateTime(record.checkedInAt).format(context)}'
                          : (student.isPending ? 'Pending — يحتاج اعتماد' : 'معتمد'),
                    ),
                    trailing: present
                        ? OutlinedButton(
                            onPressed: () => _editAttendance(record.id, record.checkedInAt),
                            child: const Text('تعديل'),
                          )
                        : FilledButton(
                            onPressed: () => _checkIn(student),
                            child: const Text('تسجيل'),
                          ),
                  );
                });
              },
            )),
          ]);
        },
      ),
    );
  }
}
