import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'meeting_providers.dart';
import '../../auth/presentation/auth_providers.dart';

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
    final profile = ref.watch(currentServantProfileProvider).value;
    final canCreate = profile?.role == 'overall_leader' || profile?.role == 'overall_helper';
    return Scaffold(
      appBar: AppBar(title: const Text('الاجتماعات'), actions: [IconButton(icon: const Icon(Icons.sync), onPressed: () => repo.refresh(widget.serviceId))]), floatingActionButton: canCreate ? FloatingActionButton(onPressed: () async { final now = DateTime.now(); await repo.create(serviceId: widget.serviceId, date: now, startTime: '15:00:00'); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الاجتماع محليًا وسيتم مزامنته.'))); }, child: const Icon(Icons.add)) : null,
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
