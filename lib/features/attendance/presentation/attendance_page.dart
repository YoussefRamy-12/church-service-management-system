import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'attendance_providers.dart';

class AttendancePage extends ConsumerWidget {
  const AttendancePage({
    super.key,
    required this.meetingId,
    required this.classId,
    required this.recordedBy,
    required this.students,
  });

  final String meetingId;
  final String classId;
  final String recordedBy;
  final List<({String id, String name})> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(attendanceRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الحضور')),
      body: StreamBuilder(
        stream: repository.watchForMeeting(meetingId),
        builder: (context, snapshot) {
          final checked = {
            for (final row in snapshot.data ?? const [])
              row.studentId,
          };
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, index) {
              final student = students[index];
              final present = checked.contains(student.id);
              return ListTile(
                title: Text(student.name),
                trailing: FilledButton.icon(
                  icon: Icon(present ? Icons.check : Icons.how_to_reg),
                  label: Text(present ? 'حاضر' : 'تسجيل'),
                  onPressed: present ? null : () async {
                    await repository.checkIn(
                      meetingId: meetingId,
                      studentId: student.id,
                      classIdAtAttendance: classId,
                      recordedBy: recordedBy,
                      checkedInAt: DateTime.now(),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
