import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import 'meeting_providers.dart';
import 'attendance_session_page.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/sync/sync_status_widget.dart';

class MeetingPickerPage extends ConsumerStatefulWidget {
  const MeetingPickerPage({super.key, required this.serviceId, required this.classId});
  final String serviceId, classId;

  @override
  ConsumerState<MeetingPickerPage> createState() => _MeetingPickerPageState();
}

class _MeetingPickerPageState extends ConsumerState<MeetingPickerPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(meetingRepositoryProvider).refresh(widget.serviceId));
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(meetingRepositoryProvider);
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار اجتماع الحضور'),
        actions: [const SyncStatusWidget()],
      ),
      body: AppContent(
        maxWidth: 900,
        child: StreamBuilder(
          stream: repo.watchMeetings(widget.serviceId),
          builder: (context, snapshot) {
            final meetings = snapshot.data ?? const [];
            if (snapshot.connectionState == ConnectionState.waiting &&
                meetings.isEmpty) {
              return const LoadingView(message: 'جاري تحميل الاجتماعات...');
            }
            if (meetings.isEmpty) {
              return const EmptyState(
                icon: Icons.event_available_outlined,
                title: 'لا توجد اجتماعات',
                message: 'حدّث البيانات أو أنشئ اجتماعًا جديدًا من شاشة الاجتماعات.',
              );
            }
            if (profile == null) {
              return const LoadingView(message: 'جاري تجهيز الحساب...');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
              itemCount: meetings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final meeting = meetings[i];
                return Card(
                  child: ListTile(
                    key: Key('attendance_meeting_${meeting.id}'),
                    minVerticalPadding: 12,
                    leading: const CircleAvatar(
                      child: Icon(Icons.event_available_outlined),
                    ),
                    title: Text(
                      'اجتماع ${meeting.meetingDate.toLocal().toString().split(' ').first}',
                    ),
                    subtitle: Text('البداية ${meeting.startTime}'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AttendanceSessionPage(
                          serviceId: widget.serviceId,
                          classId: widget.classId,
                          meetingId: meeting.id,
                          recordedBy: profile.id,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
