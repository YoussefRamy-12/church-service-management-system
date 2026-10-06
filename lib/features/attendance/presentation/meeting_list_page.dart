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
    Future.microtask(
      () => ref.read(meetingRepositoryProvider).refresh(widget.serviceId),
    );
  }

  Future<void> _createMeeting() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'اختر تاريخ الاجتماع',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 0),
      helpText: 'اختر وقت بداية الاجتماع',
    );
    if (time == null || !mounted) return;

    final startTime =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';

    await ref.read(meetingRepositoryProvider).create(
      serviceId: widget.serviceId,
      date: date,
      startTime: startTime,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء الاجتماع محليًا وسيتم مزامنته.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(meetingRepositoryProvider);
    final profile = ref.watch(currentServantProfileProvider).value;
    final canCreate =
        profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاجتماعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'تحديث',
            onPressed: () => repo.refresh(widget.serviceId),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _createMeeting,
              tooltip: 'إنشاء اجتماع',
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder(
        stream: repo.watchMeetings(widget.serviceId),
        builder: (context, snapshot) {
          final meetings = snapshot.data ?? const [];
          if (meetings.isEmpty) {
            return const Center(child: Text('لا توجد اجتماعات محفوظة محليًا.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, index) {
              final meeting = meetings[index];
              return ListTile(
                title: Text(
                  'اجتماع ${meeting.meetingDate.toLocal().toString().split(' ').first}',
                ),
                subtitle: Text('بداية الاجتماع ${meeting.startTime}'),
              );
            },
          );
        },
      ),
    );
  }
}
