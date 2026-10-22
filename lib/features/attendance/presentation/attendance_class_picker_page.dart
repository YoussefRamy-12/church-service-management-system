// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../auth/domain/entities/session_identity.dart';
import '../../service/presentation/service_providers.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/sync/sync_status_widget.dart';

class AttendanceClassPickerPage extends ConsumerStatefulWidget {
  const AttendanceClassPickerPage({
    super.key,
    required this.serviceId,
    required this.meetingId,
  });
  final String serviceId;
  final String meetingId;

  @override
  ConsumerState<AttendanceClassPickerPage> createState() =>
      _AttendanceClassPickerPageState();
}

class _AttendanceClassPickerPageState
    extends ConsumerState<AttendanceClassPickerPage> {
  bool _redirectedToAssignedClass = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
    final identityState = ref.watch(currentSessionIdentityProvider);
    final recordedBy =
        profile?.id ??
        (identityState.hasValue
            ? switch (identityState.value) {
                SuperAdminIdentity(:final profile) => profile.id,
                _ => null,
              }
            : null);
    final isClassScoped =
        profile?.role == 'class_servant' || profile?.role == 'class_leader';
    final isStageLeader = profile?.role == 'stage_leader';
    final canUseServiceRoster =
        identityState.hasValue &&
        (identityState.value is SuperAdminIdentity ||
            profile?.role == 'overall_leader' ||
            profile?.role == 'overall_helper');

    if (recordedBy != null && isClassScoped && profile?.classId != null) {
      _openAssignedClass(profile!.classId!, recordedBy);
      return const Scaffold(
        body: LoadingView(message: 'جاري فتح شاشة حضور فصلك...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الفصل للحضور'),
        actions: [
          const SyncStatusWidget(),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'تحديث المراحل',
            onPressed: () => repository.refreshStages(widget.serviceId),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: repository.watchStages(widget.serviceId),
        builder: (context, snapshot) {
          final stages = snapshot.data ?? const [];
          if (snapshot.connectionState == ConnectionState.waiting &&
              stages.isEmpty) {
            return const LoadingView(message: 'جاري تحميل المراحل...');
          }
          if (recordedBy == null) {
            return const LoadingView(message: 'جاري تجهيز الحساب...');
          }

          final visibleStages = isStageLeader && profile?.stageId != null
              ? stages.where((stage) => stage.id == profile!.stageId).toList()
              : stages;
          return AppContent(
            maxWidth: 900,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
              children: [
                Text(
                  'اختر الفصل الذي ستسجل حضوره.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text('افتح المرحلة ثم اختر الفصل لبدء تسجيل الحضور.'),
                const SizedBox(height: 16),
                if (canUseServiceRoster)
                  Card(
                    child: ListTile(
                      key: const Key('attendance_all_students'),
                      leading: const CircleAvatar(
                        child: Icon(Icons.groups_rounded),
                      ),
                      title: const Text('كل طلاب الخدمة'),
                      subtitle: const Text(
                        'قائمة واحدة للبحث وتسجيل الحضور عند المدخل.',
                      ),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.go(
                        '/service/${widget.serviceId}/attendance/session/${widget.meetingId}/all?recordedBy=$recordedBy',
                      ),
                    ),
                  ),
                if (visibleStages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: EmptyState(
                      icon: Icons.school_outlined,
                      title: 'لا توجد مراحل متاحة',
                      message: 'يمكن تسجيل الحضور من قائمة كل طلاب الخدمة.',
                    ),
                  ),
                for (final stage in visibleStages)
                  ExpansionTile(
                    key: Key('attendance_stage_' + stage.id),
                    title: Text(stage.name),
                    onExpansionChanged: (expanded) {
                      if (expanded) repository.refreshClasses(stage.id);
                    },
                    children: [
                      StreamBuilder(
                        stream: repository.watchClasses(stage.id),
                        builder: (context, classSnapshot) {
                          final classes = classSnapshot.data ?? const [];
                          return Column(
                            children: [
                              for (final item in classes)
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.class_outlined),
                                  ),
                                  key: Key('attendance_class_' + item.id),
                                  title: Text(item.name),
                                  trailing: const Icon(Icons.chevron_left),
                                  onTap: () => context.go(
                                    '/service/' +
                                        widget.serviceId +
                                        '/attendance/session/' +
                                        widget.meetingId +
                                        '/' +
                                        item.id +
                                        '?recordedBy=' +
                                        recordedBy,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAssignedClass(String classId, String recordedBy) {
    if (_redirectedToAssignedClass) return;
    _redirectedToAssignedClass = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(
        '/service/${widget.serviceId}/attendance/session/${widget.meetingId}/$classId?recordedBy=$recordedBy',
      );
    });
  }
}
