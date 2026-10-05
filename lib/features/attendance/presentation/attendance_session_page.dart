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

  Future<void> _checkIn(Student student) async {
    await ref.read(attendanceRepositoryProvider).checkIn(
      meetingId: widget.meetingId, studentId: student.id,
      classIdAtAttendance: student.currentClassId ?? widget.classId,
      recordedBy: widget.recordedBy, checkedInAt: DateTime.now(),
    );
    await ref.read(syncEngineProvider).syncNow();
  }

  Future<void> _register() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (_) => AlertDialog(
      title: const Text('تسجيل تلميذ جديد'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'اسم التلميذ')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('تسجيل'))],
    ));
    if (name == null || name.isEmpty) return;
    final local = ref.read(localStudentRepositoryProvider);
    final queue = ref.read(syncQueueRepositoryProvider);
    await OfflineFirstStudentRegistration(local, queue, ref.read(appDatabaseProvider)).registerPending(
      serviceId: widget.serviceId, proposedClassId: widget.classId, name: name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التلميذ محليًا كـ Pending وسيتم مزامنته.')));
  }

  @override
  Widget build(BuildContext context) {
    final studentsStream = ref.watch(studentRepositoryProvider).watchStudentsForClass(widget.classId);
    return Scaffold(
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
                final checked = {for (final row in attendanceSnapshot.data ?? const []) row.studentId};
                return ListView.builder(itemCount: students.length, itemBuilder: (_, i) {
                  final student = students[i];
                  final present = checked.contains(student.id);
                  return ListTile(title: Text(student.name), subtitle: Text(student.isPending ? 'Pending — يحتاج اعتماد' : 'معتمد'), trailing: FilledButton(onPressed: present ? null : () => _checkIn(student), child: Text(present ? 'حاضر' : 'تسجيل')));
                });
              },
            )),
          ]);
        },
      ),
    );
  }
}
