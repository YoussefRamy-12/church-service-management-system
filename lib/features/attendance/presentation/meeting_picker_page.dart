import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import 'meeting_providers.dart';
import 'attendance_session_page.dart';

class MeetingPickerPage extends ConsumerStatefulWidget {
  const MeetingPickerPage({super.key, required this.serviceId, required this.classId});
  final String serviceId, classId;
  @override ConsumerState<MeetingPickerPage> createState() => _MeetingPickerPageState();
}

class _MeetingPickerPageState extends ConsumerState<MeetingPickerPage> {
  @override void initState() { super.initState(); Future.microtask(() => ref.read(meetingRepositoryProvider).refresh(widget.serviceId)); }
  @override Widget build(BuildContext context) {
    final repo = ref.watch(meetingRepositoryProvider);
    final profile = ref.watch(currentServantProfileProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار اجتماع الحضور')),
      body: StreamBuilder(
        stream: repo.watchMeetings(widget.serviceId),
        builder: (context, snapshot) {
          final meetings = snapshot.data ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: meetings.length,
            itemBuilder: (_, i) { final meeting = meetings[i]; return Card(child: ListTile(
              title: Text('اجتماع ${meeting.meetingDate.toLocal().toString().split(' ').first}'),
              subtitle: Text('البداية ${meeting.startTime}'),
              trailing: const Icon(Icons.chevron_left),
              onTap: profile == null ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AttendanceSessionPage(serviceId: widget.serviceId, classId: widget.classId, meetingId: meeting.id, recordedBy: profile.id))),
            )); },
          );
        },
      ),
    );
  }
}
