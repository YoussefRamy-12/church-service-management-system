// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:church_service_management_system/app/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/student_providers.dart';
import '../../students/presentation/add_student_page.dart';
import '../../students/presentation/student_details_page.dart';

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
      // The server applies the selected service/class RLS scope before this
      // result is cached for the offline-first dashboard.
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
            body: EmptyState(
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
            body: EmptyState(
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
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 20,
                  28,
                  wide ? 32 : 20,
                  40,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مرحبًا بك',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'لوحة الخدمة',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        key: const Key('dashboard_attendance'),
                        onPressed: () => context.go(
                          '/service/' + widget.serviceId + '/attendance',
                        ),
                        icon: const Icon(Icons.fact_check_rounded),
                        label: const Text('تسجيل الحضور'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4F46E5,
                                ).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.church_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: Theme.of(context).textTheme.titleLarge
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
                  ),
                  const SizedBox(height: 24),
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
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _DashboardMetric(
                            label: 'إجمالي التلاميذ',
                            value: studentSnapshot.hasData
                                ? '${visibleStudents.length}'
                                : '—',
                            icon: Icons.groups_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _DashboardMetric(
                            label: 'معتمدون',
                            value: studentSnapshot.hasData
                                ? '${visibleStudents.where((student) => student.isApproved).length}'
                                : '—',
                            icon: Icons.verified_rounded,
                            color: const Color(0xFF059669),
                          ),
                          _DashboardMetric(
                            label: 'بانتظار الاعتماد',
                            value: studentSnapshot.hasData
                                ? '${visibleStudents.where((student) => student.isPending).length}'
                                : '—',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFD97706),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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
                  Text(
                    'الوصول السريع',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickAction(
                        key: const Key('dashboard_students'),
                        icon: Icons.school_rounded,
                        label: 'التلاميذ',
                        onTap: () => context.go(
                          '/service/' + widget.serviceId + '/students',
                        ),
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
                          '/service/' + widget.serviceId + '/follow-up',
                        ),
                      ),
                      if (canManage)
                        _QuickAction(
                          key: const Key('dashboard_reports'),
                          icon: Icons.bar_chart_rounded,
                          label: 'التقارير',
                          onTap: () => context.go(
                            '/service/' + widget.serviceId + '/reports',
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
                        ),
                      if (canManage)
                        _QuickAction(
                          key: const Key('dashboard_servants'),
                          icon: Icons.groups_rounded,
                          label: 'الخدام',
                          onTap: () => context.go(
                            '/service/' + widget.serviceId + '/servants',
                          ),
                        ),
                    ],
                  ),
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
                                stages.isEmpty)) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }
                        if (isClassServant && !_scopeLoaded) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }
                        if (stages.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 42,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'لا توجد مراحل محفوظة محليًا بعد.',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ستظهر بيانات الخدمة هنا بعد المزامنة.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: stages
                              .map(
                                (stage) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ExpansionTile(
                                    key: Key('dashboard_stage_' + stage.id),
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
                                                      'dashboard_class_' +
                                                          item.id,
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
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
    label: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    onPressed: onTap,
    backgroundColor: Colors.white.withValues(alpha: 0.85),
    side: const BorderSide(color: Color(0x334F46E5), width: 1.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      opacity: 0.85,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 12),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
