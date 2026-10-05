import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'meeting_providers.dart';

class MeetingListPage extends ConsumerStatefulWidget {
  const MeetingListPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<MeetingListPage> createState() => _MeetingListPageState();
}

class _MeetingListPageState extends ConsumerState<MeetingListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(meetingRepositoryProvider).refresh(widget.serviceId));
  }
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(meetingRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الاجتماعات'), actions: [IconButton(icon: const Icon(Icons.sync), onPressed: () => repo.refresh(widget.serviceId))]),
      body: StreamBuilder(
        stream: repo.watchMeetings(widget.serviceId),
        builder: (context, snapshot) {
          final meetings = snapshot.data ?? const [];
          if (meetings.isEmpty) return const Center(child: Text('لا توجد اجتماعات محفوظة محليًا.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16), itemCount: meetings.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final meeting = meetings[index];
              return ListTile(title: Text('اجتماع ${meeting.meetingDate.toLocal().toString().split(' ').first}'), subtitle: Text('بداية الاجتماع ${meeting.startTime}'));
            },
          );
        },
      ),
    );
  }
}
