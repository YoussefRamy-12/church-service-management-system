import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_colors.dart';
import '../../../app/ui/app_ui.dart';
import '../../../app/ui/components/empty_state.dart' as comp;
import '../../../core/sync/sync_engine_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/add_student_page.dart';
import '../../students/presentation/student_details_page.dart';
import '../../students/presentation/student_providers.dart';
import 'service_providers.dart';

class ServiceDashboardPage extends ConsumerStatefulWidget {
  const ServiceDashboardPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<ServiceDashboardPage> createState() =>
      _ServiceDashboardPageState();
}

class _ServiceDashboardPageState extends ConsumerState<ServiceDashboardPage> {
  String? _assignedStageId;
  String? _assignedClassLabel;
  bool _scopeLoaded = false;

  Future<void> _addStudent() async {
    final repository = ref.read(serviceRepositoryProvider);
    final profile = await ref.read(currentServantProfileProvider.future);
    try {
      await repository.refreshStages(widget.serviceId);
    } catch (_) {}
    if (!mounted) return;
    final stages = await repository.getStages(widget.serviceId);
    if (!mounted) return;
    if (stages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف مرحلة وفصلًا من الإعدادات أولًا.')),
      );
      return;
    }

    final isClassScoped =
        (profile?.role == 'class_servant' || profile?.role == 'class_leader') &&
        profile?.classId != null;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddStudentPage(
          serviceId: widget.serviceId,
          initialClassId: isClassScoped ? profile!.classId : null,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshDashboardData);
  }

  Future<void> _refreshDashboardData() async {
    final services = ref.read(serviceRepositoryProvider);
    final students = ref.read(studentRepositoryProvider);
    try {
      await services.getService(widget.serviceId);
      await services.refreshStages(widget.serviceId);
      final profile = await ref.read(currentServantProfileProvider.future);
      final stages = await services.getStages(widget.serviceId);
      String? assignedStageId;
      String? assignedClassLabel;

      for (final stage in stages) {
        try {
          await services.refreshClasses(stage.id);
        } catch (_) {
          // Keep the existing local structure when offline.
        }
        if (profile?.role == 'class_servant' && profile?.classId != null) {
          final classes = await services.getClasses(stage.id);
          for (final item in classes) {
            if (item.id == profile!.classId) {
              assignedStageId = stage.id;
              assignedClassLabel = '${stage.name} • ${item.name}';
              break;
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _assignedStageId = assignedStageId;
          _assignedClassLabel = assignedClassLabel;
          _scopeLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _scopeLoaded = true);
    }
    try {
      await students.refreshStudentsForService(widget.serviceId);
    } catch (_) {
      // Continue to show previously cached rows when offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final profile = ref.watch(currentServantProfileProvider);

    return FutureBuilder(
      future: repository.getService(widget.serviceId),
      builder: (context, snapshot) {
        final service = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(message: 'جاري تحميل لوحة الخدمة...'),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: comp.EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'تعذر تحميل لوحة الخدمة',
              message: 'تحقق من الاتصال وحاول مرة أخرى.',
              action: OutlinedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ),
          );
        }
        if (service == null) {
          return const Scaffold(
            body: comp.EmptyState(
              icon: Icons.church_outlined,
              title: 'الخدمة غير متاحة',
              message:
                  'لا توجد بيانات محلية للخدمة. اتصل بالإنترنت ثم أعد المحاولة.',
            ),
          );
        }

        final role = profile.hasValue ? profile.value?.role : null;
        final isClassServant = role == 'class_servant';
        final assignedClassId = profile.hasValue
            ? profile.value?.classId
            : null;
        final canManage =
            ref.watch(isSuperAdminProvider) ||
            role == 'overall_leader' ||
            role == 'overall_helper' ||
            role == 'leader' ||
            role == 'helper';
        final isSuperAdmin = ref.watch(isSuperAdminProvider);

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final isMobile = constraints.maxWidth < 600;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 16,
                  24,
                  wide ? 32 : 16,
                  40,
                ),
                children: [
                  // Header Row with screen title
                  Text(
                    'لوحة الخدمة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Identity & Single Primary Button CTA
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.church_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      service.churchName,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            key: const Key('dashboard_attendance'),
                            onPressed: () => context.go(
                              '/service/${widget.serviceId}/attendance',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                            icon: const Icon(Icons.fact_check_rounded),
                            label: const Text(
                              'تسجيل الحضور',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Data streams for students & sync queue (Needs attention & Metric cards)
                  StreamBuilder<List<Student>>(
                    stream: ref
                        .watch(studentRepositoryProvider)
                        .watchStudentsForService(widget.serviceId),
                    builder: (context, studentSnapshot) {
                      final students =
                          studentSnapshot.data ?? const <Student>[];
                      final visibleStudents = isClassServant
                          ? students
                                .where(
                                  (student) =>
                                      assignedClassId != null &&
                                      (student.currentClassId ==
                                              assignedClassId ||
                                          student.proposedClassId ==
                                              assignedClassId),
                                )
                                .toList()
                          : students;

                      return StreamBuilder<int>(
                        stream: ref
                            .watch(syncQueueRepositoryProvider)
                            .watchCountByStatus('conflict'),
                        builder: (context, conflictSnapshot) {
                          final conflictCount = conflictSnapshot.data ?? 0;
                          final pendingCount = visibleStudents
                              .where((student) => student.isPending)
                              .length;
                          final unassignedCount = visibleStudents
                              .where(
                                (student) =>
                                    student.currentClassId == null &&
                                    student.proposedClassId == null,
                              )
                              .length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // "Needs attention" block (ONLY from existing providers)
                              if (pendingCount > 0 ||
                                  unassignedCount > 0 ||
                                  conflictCount > 0) ...[
                                Card(
                                  key: const Key('dashboard_needs_attention'),
                                  elevation: 0,
                                  color: AppColors.of(
                                    context,
                                  ).warning.background.withValues(alpha: 0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.of(context)
                                          .warning
                                          .foreground
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              size: 20,
                                              color: AppColors.of(
                                                context,
                                              ).warning.foreground,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'يحتاج متابعة',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.of(
                                                  context,
                                                ).warning.foreground,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (pendingCount > 0)
                                              ActionChip(
                                                avatar: const Icon(
                                                  Icons.hourglass_top_rounded,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  '$pendingCount بانتظار الاعتماد',
                                                ),
                                                onPressed: () => context.go(
                                                  '/service/${widget.serviceId}/students',
                                                ),
                                              ),
                                            if (unassignedCount > 0)
                                              ActionChip(
                                                avatar: const Icon(
                                                  Icons.person_outline,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  '$unassignedCount غير مسكن بفصل',
                                                ),
                                                onPressed: () => context.go(
                                                  '/service/${widget.serviceId}/students',
                                                ),
                                              ),
                                            if (conflictCount > 0)
                                              ActionChip(
                                                avatar: const Icon(
                                                  Icons.sync_problem_rounded,
                                                  size: 16,
                                                ),
                                                label: Text(
                                                  '$conflictCount تعارض مزامنة',
                                                ),
                                                onPressed: () => context.push(
                                                  '/sync/conflicts',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Responsive metric cards (2+1 full-width on mobile, 3-up on wider screens)
                              Builder(
                                builder: (context) {
                                  final cards = [
                                    _metricCard(
                                      label: isClassServant
                                          ? 'تلاميذ الفصل'
                                          : 'إجمالي التلاميذ',
                                      value: studentSnapshot.hasData
                                          ? '${visibleStudents.length}'
                                          : '—',
                                      icon: Icons.groups_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      onTap: () => context.go(
                                        '/service/${widget.serviceId}/students',
                                      ),
                                    ),
                                    _metricCard(
                                      label: 'معتمدون',
                                      value: studentSnapshot.hasData
                                          ? '${visibleStudents.where((student) => student.isApproved).length}'
                                          : '—',
                                      icon: Icons.verified_rounded,
                                      color: AppColors.of(
                                        context,
                                      ).present.foreground,
                                      onTap: () => context.go(
                                        '/service/${widget.serviceId}/students',
                                      ),
                                    ),
                                    _metricCard(
                                      label: 'بانتظار الاعتماد',
                                      value: studentSnapshot.hasData
                                          ? '${visibleStudents.where((student) => student.isPending).length}'
                                          : '—',
                                      icon: Icons.pending_actions_rounded,
                                      color: AppColors.of(
                                        context,
                                      ).pending.foreground,
                                      onTap: () => context.go(
                                        '/service/${widget.serviceId}/students',
                                      ),
                                    ),
                                  ];
                                  if (isMobile) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: cards[0]),
                                            const SizedBox(width: 12),
                                            Expanded(child: cards[1]),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        cards[2],
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      Expanded(child: cards[0]),
                                      const SizedBox(width: 12),
                                      Expanded(child: cards[1]),
                                      const SizedBox(width: 12),
                                      Expanded(child: cards[2]),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),

                              // Offline note
                              Row(
                                children: [
                                  Icon(
                                    Icons.cloud_done_outlined,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'بيانات محفوظة محليًا',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Role-scoped: class servant scope card
                  if (isClassServant)
                    Card(
                      key: const Key('class_servant_dashboard_scope'),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.groups_outlined),
                        ),
                        title: const Text('فصلك'),
                        subtitle: Text(
                          !_scopeLoaded
                              ? 'جاري تحميل بيانات الفصل...'
                              : _assignedClassLabel ??
                                    'لم يتم العثور على الفصل المرتبط بحسابك.',
                        ),
                        onTap:
                            _assignedStageId == null || assignedClassId == null
                            ? null
                            : () => context.go(
                                '/service/${widget.serviceId}/stage/$_assignedStageId/class/$assignedClassId',
                              ),
                        trailing: _scopeLoaded && _assignedClassLabel == null
                            ? IconButton(
                                tooltip: 'إعادة تحميل بيانات الفصل',
                                onPressed: _refreshDashboardData,
                                icon: const Icon(Icons.refresh_rounded),
                              )
                            : const Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                  if (isClassServant) const SizedBox(height: 16),

                  // Role-scoped: class servant students overview
                  if (isClassServant && assignedClassId != null)
                    StreamBuilder<List<Student>>(
                      stream: ref
                          .watch(studentRepositoryProvider)
                          .watchStudentsForClass(assignedClassId),
                      builder: (context, snapshot) {
                        final rows = (snapshot.data ?? const <Student>[])
                            .where(
                              (student) =>
                                  student.currentClassId == assignedClassId ||
                                  student.proposedClassId == assignedClassId,
                            )
                            .toList();
                        return Card(
                          key: const Key('class_servant_students_overview'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'تلاميذ فصلك',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                if (snapshot.hasError)
                                  const Text(
                                    'تعذر تحميل التلاميذ المحفوظين محليًا.',
                                  ),
                                if (!snapshot.hasData && !snapshot.hasError)
                                  const LinearProgressIndicator(),
                                if (snapshot.hasData && rows.isEmpty)
                                  const Text(
                                    'لا يوجد تلاميذ مسجلون في فصلك بعد.',
                                  ),
                                for (final student in rows.take(5))
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      child: Text(
                                        student.name.characters.first,
                                      ),
                                    ),
                                    title: Text(student.name),
                                    subtitle: Text(
                                      student.isPending
                                          ? 'بانتظار الاعتماد'
                                          : student.school ??
                                                'لا توجد مدرسة مسجلة',
                                    ),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => StudentDetailsPage(
                                          student: student,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (rows.length > 5)
                                  TextButton(
                                    onPressed: () => context.go(
                                      '/service/${widget.serviceId}/students',
                                    ),
                                    child: const Text('عرض جميع التلاميذ'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  if (isClassServant && assignedClassId != null)
                    const SizedBox(height: 16),

                  // Quick Actions
                  Text(
                    'الوصول السريع',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final quickActions = <Widget>[
                        _QuickAction(
                          key: const Key('dashboard_students'),
                          icon: Icons.school_rounded,
                          label: 'التلاميذ',
                          onTap: () =>
                              context.go('/service/${widget.serviceId}/students'),
                        ),
                        _QuickAction(
                          key: const Key('dashboard_add_student'),
                          icon: Icons.person_add_alt_1_rounded,
                          label: 'إضافة تلميذ',
                          onTap: _addStudent,
                        ),
                        _QuickAction(
                          icon: Icons.history_edu_rounded,
                          label: 'المتابعة',
                          onTap: () => context.go(
                            '/service/${widget.serviceId}/follow-up',
                          ),
                        ),
                        if (canManage)
                          _QuickAction(
                            key: const Key('dashboard_reports'),
                            icon: Icons.bar_chart_rounded,
                            label: 'التقارير',
                            onTap: () => context.go(
                              '/service/${widget.serviceId}/reports',
                            ),
                          ),
                        if (isSuperAdmin)
                          _QuickAction(
                            key: const Key('dashboard_add_servant'),
                            icon: Icons.group_add_rounded,
                            label: 'إضافة خادم',
                            onTap: () => context.push(
                              '/service/${widget.serviceId}/servants?add=true',
                            ),
                          )
                        else
                          _QuickAction(
                            key: const Key('dashboard_notebook'),
                            icon: Icons.menu_book_rounded,
                            label: 'النوتة الروحية',
                            onTap: () => context.go(
                              '/service/${widget.serviceId}/spiritual-notebook',
                            ),
                          ),
                        if (canManage)
                          _QuickAction(
                            key: const Key('dashboard_servants'),
                            icon: Icons.groups_rounded,
                            label: 'الخدام',
                            onTap: () => context.go(
                              '/service/${widget.serviceId}/servants',
                            ),
                          ),
                      ];

                      assert(quickActions.length.isEven);
                      return GridView.builder(
                        itemCount: quickActions.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 2 : 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: isMobile ? 68 : 76,
                        ),
                        itemBuilder: (_, index) => quickActions[index],
                      );
                    },
                  ),

                  // Role-scoped: Stages & classes exploration (non-class-servant)
                  if (!isClassServant) ...[
                    const SizedBox(height: 28),
                    Text(
                      'المراحل والفصول',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder(
                      stream: repository.watchStages(widget.serviceId),
                      builder: (context, stageSnapshot) {
                        final allStages = stageSnapshot.data ?? const [];
                        final stages = isClassServant
                            ? allStages
                                  .where(
                                    (stage) => stage.id == _assignedStageId,
                                  )
                                  .toList()
                            : allStages;
                        if (stageSnapshot.hasError) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Icon(Icons.cloud_off_rounded),
                                  const SizedBox(height: 8),
                                  const Text('تعذر تحميل المراحل.'),
                                  TextButton.icon(
                                    onPressed: () => repository.refreshStages(
                                      widget.serviceId,
                                    ),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (!stageSnapshot.hasData ||
                            (stageSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                stages.isEmpty) ||
                            (isClassServant && !_scopeLoaded)) {
                          return const _StagesSkeletonCard();
                        }
                        if (stages.isEmpty) {
                          return const comp.EmptyState(
                            icon: Icons.school_outlined,
                            title: 'لا توجد مراحل محفوظة محليًا بعد',
                            message: 'ستظهر بيانات الخدمة هنا بعد المزامنة.',
                          );
                        }
                        return Column(
                          children: stages
                              .map(
                                (stage) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ExpansionTile(
                                    key: Key('dashboard_stage_${stage.id}'),
                                    leading: const Icon(Icons.layers_outlined),
                                    title: Text(
                                      stage.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      key: Key(
                                        'dashboard_open_stage_${stage.id}',
                                      ),
                                      tooltip: 'لوحة المرحلة',
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                      ),
                                      onPressed: () => context.go(
                                        '/service/${widget.serviceId}/stage/${stage.id}',
                                      ),
                                    ),
                                    initiallyExpanded: isClassServant,
                                    onExpansionChanged: (expanded) {
                                      if (expanded) {
                                        repository.refreshClasses(stage.id);
                                      }
                                    },
                                    children: [
                                      StreamBuilder(
                                        stream: repository.watchClasses(
                                          stage.id,
                                        ),
                                        builder: (context, classSnapshot) {
                                          final classes =
                                              classSnapshot.data ?? const [];
                                          final visibleClasses = isClassServant
                                              ? classes
                                                    .where(
                                                      (item) =>
                                                          item.id ==
                                                          assignedClassId,
                                                    )
                                                    .toList()
                                              : classes;
                                          if (classSnapshot.hasError) {
                                            return Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: TextButton.icon(
                                                onPressed: () => repository
                                                    .refreshClasses(stage.id),
                                                icon: const Icon(Icons.refresh),
                                                label: const Text(
                                                  'تعذر تحميل الفصول — أعد المحاولة',
                                                ),
                                              ),
                                            );
                                          }
                                          if (!classSnapshot.hasData) {
                                            return const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          if (visibleClasses.isEmpty) {
                                            return const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Text(
                                                'لا توجد فصول محفوظة محليًا.',
                                              ),
                                            );
                                          }
                                          return Column(
                                            children: visibleClasses
                                                .map(
                                                  (item) => ListTile(
                                                    key: Key(
                                                      'dashboard_class_${item.id}',
                                                    ),
                                                    leading: const Icon(
                                                      Icons.groups_outlined,
                                                    ),
                                                    title: Text(item.name),
                                                    trailing: const Icon(
                                                      Icons.chevron_left,
                                                    ),
                                                    onTap: () => context.go(
                                                      '/service/${widget.serviceId}/stage/${stage.id}/class/${item.id}',
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StagesSkeletonCard extends StatelessWidget {
  const _StagesSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      key: const Key('dashboard_stages_skeleton'),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
