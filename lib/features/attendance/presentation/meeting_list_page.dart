// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'meeting_providers.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../../core/sync/sync_status_widget.dart';
import '../../service/presentation/service_providers.dart';

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
    Future.microtask(_loadAndEnsureSchedule);
  }

  Future<void> _loadAndEnsureSchedule() async {
    final meetings = ref.read(meetingRepositoryProvider);
    try {
      await meetings.refresh(widget.serviceId);
    } catch (_) {
      // Offline users can only use the shared meetings already cached locally.
      return;
    }
    try {
      final profile = await ref.read(currentServantProfileProvider.future);
      final canManageSchedule =
          ref.read(isSuperAdminProvider) ||
          profile?.role == 'overall_leader' ||
          profile?.role == 'overall_helper';
      if (!canManageSchedule) return;
      final service = await ref
          .read(serviceRepositoryProvider)
          .getService(widget.serviceId);
      if (service != null) {
        await meetings.ensureConfiguredSchedule(service);
        // Reload the shared server state once schedule generation is complete.
        await meetings.refresh(widget.serviceId);
      }
    } catch (_) {}
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

    final service = await ref.read(serviceRepositoryProvider).getService(widget.serviceId);
    if (service == null || !mounted) return;
    final startTime = service.meetingStartTime;

    try {
      await ref
          .read(meetingRepositoryProvider)
          .create(serviceId: widget.serviceId, date: date, startTime: startTime);

      if (!mounted) return;
      final isOffline = ref.read(offlineSyncEnabledProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'تم إنشاء الاجتماع محليًا وسيتم مزامنته.'
                : 'تم إنشاء الاجتماع بنجاح في ${startTime.substring(0, 5)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء الاجتماع: ${NetworkErrorFormatter.format(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(meetingRepositoryProvider);
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
    final canCreate =
        ref.watch(isSuperAdminProvider) ||
        profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الاجتماعات'),
        actions: [
          const SyncStatusWidget(),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'تحديث الاجتماعات',
            onPressed: () => repo.refresh(widget.serviceId),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _createMeeting,
                tooltip: 'إنشاء اجتماع',
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'اجتماع جديد',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            )
          : null,
      body: AmbientBackground(
        intensity: 0.5,
        child: StreamBuilder(
          stream: repo.watchMeetings(widget.serviceId),
          builder: (context, snapshot) {
            final rawMeetings = snapshot.data ?? const [];
            if (snapshot.connectionState == ConnectionState.waiting &&
                rawMeetings.isEmpty) {
              return const LoadingView(message: 'جاري تحميل الاجتماعات...');
            }
            if (rawMeetings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(36),
                    hoverElevation: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_available_outlined,
                            size: 38,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'لا توجد اجتماعات بعد',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أنشئ اجتماعًا جديدًا لبدء تسجيل الحضور والغياب.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (canCreate) ...[
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _createMeeting,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('إنشاء أول اجتماع'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            final meetings = List.of(rawMeetings)
              ..sort(
                (a, b) => a.meetingDate.compareTo(b.meetingDate),
              ); // Oldest to newest, with future meetings at the bottom.
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final eligible = meetings.where((meeting) {
              final date = meeting.meetingDate;
              return !DateTime(date.year, date.month, date.day).isAfter(today);
            }).toList();
            final currentMeetingId = eligible.isEmpty ? null : eligible.last.id;

            return AppContent(
              maxWidth: 900,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: meetings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final meeting = meetings[index];
                  final isCurrent = meeting.id == currentMeetingId;
                  final meetingDay = DateTime(meeting.meetingDate.year, meeting.meetingDate.month, meeting.meetingDate.day);
                  final isFuture = meetingDay.isAfter(today);
                  final dateParts = meeting.meetingDate
                      .toLocal()
                      .toString()
                      .split(' ')
                      .first;

                  return GlassCard(
                    key: Key('attendance_meeting_' + meeting.id),
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    onTap: () => context.go(
                      '/service/' +
                          widget.serviceId +
                          '/attendance/class-picker/' +
                          meeting.id,
                    ),
                    child: Row(
                      children: [
                        // Calendar date badge
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCurrent
                                  ? [
                                      const Color(0xFF4F46E5),
                                      const Color(0xFF7C3AED),
                                    ]
                                  : [
                                      const Color(0xFF64748B),
                                      const Color(0xFF94A3B8),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isCurrent
                                            ? const Color(0xFF4F46E5)
                                            : const Color(0xFF64748B))
                                        .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${meeting.meetingDate.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _monthLabel(meeting.meetingDate.month),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Meeting info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'اجتماع $dateParts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isCurrent)
                                    const GlassBadge(
                                      label: 'الاجتماع الحالي',
                                      color: Color(0xFF10B981),
                                    )
                                  else if (isFuture)
                                    const GlassBadge(
                                      label: 'قادم',
                                      color: Color(0xFFF59E0B),
                                    )
                                  else
                                    const GlassBadge(
                                      label: 'للقراءة فقط',
                                      color: Color(0xFF64748B),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 15,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'بداية الاجتماع ${meeting.startTime}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action chevron
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _monthLabel(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '$month';
  }
}
