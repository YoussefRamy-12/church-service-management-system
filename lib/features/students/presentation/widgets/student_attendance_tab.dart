import 'package:church_service_management_system/core/utils/app_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/ui/app_ui.dart';
import '../../../attendance/presentation/attendance_providers.dart';
import '../../../attendance/presentation/meeting_providers.dart';
import '../../domain/entities/student.dart';

class StudentAttendanceTab extends ConsumerStatefulWidget {
  const StudentAttendanceTab({super.key, required this.student});
  final Student student;

  @override
  ConsumerState<StudentAttendanceTab> createState() =>
      _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends ConsumerState<StudentAttendanceTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(meetingRepositoryProvider).refresh(widget.student.serviceId);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final attendanceStream = ref
        .watch(attendanceRepositoryProvider)
        .watchForStudent(student.id);
    final meetingsStream = ref
        .watch(meetingRepositoryProvider)
        .watchMeetings(student.serviceId);
    return AppContent(
      maxWidth: 900,
      child: StreamBuilder(
        stream: meetingsStream,
        builder: (context, meetingSnapshot) => StreamBuilder(
          stream: attendanceStream,
          builder: (context, snapshot) {
            if (snapshot.hasError || meetingSnapshot.hasError) {
              return const EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر تحميل سجل الحضور',
              );
            }
            if (!snapshot.hasData || !meetingSnapshot.hasData) {
              return const LoadingView(message: 'جاري تحميل سجل الحضور...');
            }
            final meetingsById = {
              for (final meeting in meetingSnapshot.data!) meeting.id: meeting,
            };
            final rows = [...snapshot.data!]
              ..sort((a, b) {
                final aDate = meetingsById[a.meetingId]?.meetingDate ?? a.checkedInAt;
                final bDate = meetingsById[b.meetingId]?.meetingDate ?? b.checkedInAt;
                return bDate.compareTo(aDate);
              });
            if (rows.isEmpty) {
              return const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'لا يوجد سجل حضور بعد',
                message: 'ستظهر سجلات الاجتماعات التي سُجل فيها التلميذ هنا.',
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Text(
                  'سجل الحضور',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (final record in rows)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.check_rounded),
                      ),
                      title: Text(
                        meetingsById[record.meetingId] == null
                            ? 'موعد الاجتماع غير متاح'
                            : '${meetingsById[record.meetingId]!.name} — ${AppDateFormatter.format(meetingsById[record.meetingId]!.meetingDate)}',
                      ),
                      subtitle: Text(
                        meetingsById[record.meetingId] == null
                            ? 'تاريخ تسجيل الحضور: ${AppDateFormatter.formatDateTime(record.checkedInAt)}'
                            : 'وقت تسجيل الحضور: ${DateFormat('HH:mm').format(record.checkedInAt.toLocal())}',
                      ),
                      trailing: Icon(
                        record.syncState == 'synced'
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_upload_outlined,
                        semanticLabel: record.syncState == 'synced'
                            ? 'تمت المزامنة'
                            : 'بانتظار المزامنة',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

