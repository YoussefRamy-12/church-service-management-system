// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'meeting_providers.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../app/ui/app_ui.dart';

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
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
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
          if (snapshot.connectionState == ConnectionState.waiting && meetings.isEmpty) {
            return const LoadingView(message: 'جاري تحميل الاجتماعات...');
          }
          if (meetings.isEmpty) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_available_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text('لا توجد اجتماعات بعد', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('أنشئ اجتماعًا جديدًا لبدء تسجيل الحضور.'),
              ]),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: meetings.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, index) {
              final meeting = meetings[index];
              return ListTile(
                key: Key('attendance_meeting_' + meeting.id),
                title: Text(
                  'اجتماع ${meeting.meetingDate.toLocal().toString().split(' ').first}',
                ),
                subtitle: Text('بداية الاجتماع ' + meeting.startTime),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.go('/service/' + widget.serviceId + '/attendance/class-picker/' + meeting.id),
              );
            },
          );
        },
      ),
    );
  }
}
