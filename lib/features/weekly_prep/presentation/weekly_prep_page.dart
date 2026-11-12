import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../attendance/domain/entities/meeting.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../auth/domain/entities/servant_profile.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/domain/entities/stage.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/prep_date_formatter.dart';
import '../domain/weekly_prep_permissions.dart';
import 'leadership/leadership_prep_dashboard.dart';
import 'servant/servant_prep_view.dart';
import 'weekly_prep_providers.dart';

class WeeklyPrepPage extends ConsumerStatefulWidget {
  const WeeklyPrepPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<WeeklyPrepPage> createState() => _WeeklyPrepPageState();
}

class _WeeklyPrepPageState extends ConsumerState<WeeklyPrepPage> {
  bool _refreshing = false;
  String? _classStageId;
  late Future<List<Stage>> _stagesFuture;
  bool _forceServantView = false;

  @override
  void initState() {
    super.initState();
    _stagesFuture = _loadStages();
    Future.microtask(_loadMeetingSchedule);
  }

  Future<void> _loadMeetingSchedule() async {
    final meetings = ref.read(meetingRepositoryProvider);
    try {
      await meetings.refresh(widget.serviceId);
      final profile = await ref.read(currentServantProfileProvider.future);
      if (ref.read(isSuperAdminProvider) ||
          profile?.role == 'overall_leader' ||
          profile?.role == 'overall_helper') {
        final service = await ref
            .read(serviceRepositoryProvider)
            .getService(widget.serviceId);
        if (service != null) await meetings.ensureConfiguredSchedule(service);
        await meetings.refresh(widget.serviceId);
      }
    } catch (_) {
      // Use the available schedule if offline.
    }
  }

  Future<List<Stage>> _loadStages() async {
    final repository = ref.read(serviceRepositoryProvider);
    final stages = await repository.getStages(widget.serviceId);
    final profile = await ref.read(currentServantProfileProvider.future);
    if ((profile?.role == 'class_servant' || profile?.role == 'class_leader') &&
        profile?.stageId == null &&
        profile?.classId != null) {
      for (final stage in stages) {
        final classes = await repository.getClasses(stage.id);
        if (classes.any((item) => item.id == profile!.classId)) {
          _classStageId = stage.id;
          break;
        }
      }
    }
    return stages;
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId);
      _stagesFuture = _loadStages();
      await ref.read(meetingRepositoryProvider).refresh(widget.serviceId);
      ref.invalidate(weeklyLessonsProvider(widget.serviceId));
      ref.invalidate(dashboardPreparationsProvider);
      ref.invalidate(dashboardStatusCountsProvider);
      await ref.read(weeklyLessonsProvider(widget.serviceId).future);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تحديث التحاضير: $error')));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  DateTime _monday(DateTime date) =>
      PrepDateFormatter.normalizeToMondayUtc(date);

  List<DateTime> _weeksFromMeetings(List<Meeting> meetings) {
    final weeks = <DateTime>[];
    final weekKeys = <String>{};

    void addWeek(DateTime date) {
      final monday = PrepDateFormatter.normalizeToMondayUtc(date);
      final key = '${monday.year}-${monday.month}-${monday.day}';
      if (weekKeys.add(key)) {
        weeks.add(monday);
      }
    }

    addWeek(DateTime.now());
    for (final meeting in meetings) {
      addWeek(meeting.meetingDate);
    }
    weeks.sort((a, b) => b.compareTo(a)); // Descending: newest first
    return weeks;
  }

  List<Stage> _permittedStages(
    List<Stage> stages,
    ServantProfile? profile,
    bool superAdmin,
  ) {
    if (superAdmin ||
        profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper') {
      return stages;
    }
    final assignedStage = profile?.stageId ?? _classStageId;
    if (assignedStage != null) {
      return stages.where((stage) => stage.id == assignedStage).toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    // Realtime auto-refresh across leader and servant screens
    ref.listen(weeklyPrepChangesStreamProvider(widget.serviceId), (_, _) {
      ref.invalidate(weeklyLessonsProvider(widget.serviceId));
      ref.invalidate(dashboardPreparationsProvider);
      ref.invalidate(dashboardStatusCountsProvider);
      ref.invalidate(servantPreparationProvider);
    });

    final profileState = ref.watch(currentServantProfileProvider);
    final superAdmin = ref.watch(isSuperAdminProvider);

    return FutureBuilder<List<Stage>>(
      future: _stagesFuture,
      builder: (context, stageSnapshot) {
        final stages = stageSnapshot.data ?? const <Stage>[];
        return profileState.when(
          loading: () => const Scaffold(
            body: LoadingView(message: 'جاري تحميل بيانات الخدمة...'),
          ),
          error: (err, _) => Scaffold(
            body: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'تعذر تحميل الحساب',
              message: '$err',
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const Scaffold(
                body: EmptyState(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'الحساب الإداري غير مرتبط بملف خادم',
                  message:
                      'يلزم ربط حساب Super Admin بملف خادم نشط قبل استخدام لوحة التحاضير ومراجعة الطلبات.',
                ),
              );
            }

            final isLeader = WeeklyPrepPermissions.canViewLeadershipDashboard(
              profile: profile,
              isSuperAdmin: superAdmin,
            );

            final allowedStages = _permittedStages(stages, profile, superAdmin);

            return StreamBuilder<List<Meeting>>(
              stream: ref
                  .watch(meetingRepositoryProvider)
                  .watchMeetings(widget.serviceId),
              builder: (context, meetingSnapshot) {
                final weeks = _weeksFromMeetings(
                  meetingSnapshot.data ?? const [],
                );
                final currentWeekMonday = _monday(DateTime.now());

                final lessonsAsync = ref.watch(
                  weeklyLessonsProvider(widget.serviceId),
                );

                return lessonsAsync.when(
                  loading: () => const Scaffold(
                    body: LoadingView(message: 'جاري تحميل ملفات التحضير...'),
                  ),
                  error: (error, _) => Scaffold(
                    body: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'تعذر تحميل التحاضير',
                      message: '$error',
                      action: OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ),
                  ),
                  data: (lessons) {
                    // If user is a leader and not toggled to personal servant view:
                    if (isLeader && !_forceServantView) {
                      return Stack(
                        children: [
                          LeadershipPrepDashboard(
                            serviceId: widget.serviceId,
                            currentLeader: profile!,
                            stages: allowedStages,
                            weeks: weeks,
                            lessons: lessons,
                            onRefresh: _refresh,
                            refreshing: _refreshing,
                          ),
                          // Floating toggle to switch to personal servant preparation view
                          PositionedDirectional(
                            start: 24,
                            bottom: 24,
                            child: FloatingActionButton.extended(
                              heroTag: 'toggle_prep_view',
                              onPressed: () =>
                                  setState(() => _forceServantView = true),
                              icon: const Icon(Icons.person_rounded),
                              label: const Text('تحضيري الشخصي'),
                            ),
                          ),
                        ],
                      );
                    }

                    // Otherwise, Servant preparation view:
                    return Stack(
                      children: [
                        ServantPrepView(
                          serviceId: widget.serviceId,
                          profile: profile!,
                          lessons: lessons,
                          stages: allowedStages,
                          initialStageId: profile.stageId ?? _classStageId,
                          currentWeekMonday: currentWeekMonday,
                          onRefresh: _refresh,
                          refreshing: _refreshing,
                        ),
                        if (isLeader)
                          PositionedDirectional(
                            start: 24,
                            bottom: 24,
                            child: FloatingActionButton.extended(
                              heroTag: 'toggle_leader_view',
                              onPressed: () =>
                                  setState(() => _forceServantView = false),
                              icon: const Icon(Icons.dashboard_rounded),
                              label: const Text('لوحة المتابعة'),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
