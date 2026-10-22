import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui/app_ui.dart';
import '../../attendance/presentation/meeting_picker_page.dart';
import '../../students/presentation/class_students_page.dart';
import '../../students/presentation/student_providers.dart';
import 'service_providers.dart';

class StageDashboardPage extends ConsumerStatefulWidget {
  const StageDashboardPage({
    super.key,
    required this.serviceId,
    required this.stageId,
  });
  final String serviceId;
  final String stageId;

  @override
  ConsumerState<StageDashboardPage> createState() => _StageDashboardPageState();
}

class _StageDashboardPageState extends ConsumerState<StageDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(serviceRepositoryProvider).refreshClasses(widget.stageId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المرحلة')),
      body: StreamBuilder(
        stream: repository.watchStages(widget.serviceId),
        builder: (context, stageSnapshot) {
          if (stageSnapshot.hasError) {
            return _DashboardError(
              onRetry: () => repository.refreshStages(widget.serviceId),
            );
          }
          if (!stageSnapshot.hasData) {
            return const LoadingView(message: 'جاري تحميل بيانات المرحلة...');
          }
          final matches = stageSnapshot.data!.where(
            (stage) => stage.id == widget.stageId,
          );
          if (matches.isEmpty) {
            return const EmptyState(
              icon: Icons.layers_outlined,
              title: 'المرحلة غير متاحة',
              message: 'حدّث بيانات الخدمة ثم حاول مرة أخرى.',
            );
          }
          final stage = matches.first;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                stage.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text('نظرة عامة على فصول المرحلة.'),
              const SizedBox(height: 20),
              StreamBuilder(
                stream: repository.watchClasses(widget.stageId),
                builder: (context, classSnapshot) {
                  if (classSnapshot.hasError) {
                    return _DashboardError(
                      onRetry: () => repository.refreshClasses(widget.stageId),
                    );
                  }
                  if (!classSnapshot.hasData) {
                    return const LoadingView(message: 'جاري تحميل الفصول...');
                  }
                  final classes = classSnapshot.data!;
                  if (classes.isEmpty) {
                    return const EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'لا توجد فصول في هذه المرحلة',
                      message: 'ستظهر الفصول هنا بعد تحديث بيانات الخدمة.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryCard(
                        icon: Icons.groups_rounded,
                        label: 'الفصول',
                        value: '${classes.length}',
                      ),
                      const SizedBox(height: 16),
                      for (final item in classes)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            key: Key('stage_dashboard_class_${item.id}'),
                            leading: const CircleAvatar(
                              child: Icon(Icons.groups_outlined),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: const Text('عرض لوحة الفصل والتلاميذ'),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => context.go(
                              '/service/${widget.serviceId}/stage/${widget.stageId}/class/${item.id}',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class ClassDashboardPage extends ConsumerWidget {
  const ClassDashboardPage({
    super.key,
    required this.serviceId,
    required this.stageId,
    required this.classId,
  });
  final String serviceId;
  final String stageId;
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(serviceRepositoryProvider);
    final students = ref.watch(studentRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الفصل')),
      body: StreamBuilder(
        stream: services.watchClasses(stageId),
        builder: (context, classSnapshot) {
          if (classSnapshot.hasError) {
            return _DashboardError(
              onRetry: () => services.refreshClasses(stageId),
            );
          }
          if (!classSnapshot.hasData) {
            return const LoadingView(message: 'جاري تحميل بيانات الفصل...');
          }
          final matches = classSnapshot.data!.where(
            (item) => item.id == classId,
          );
          if (matches.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'الفصل غير متاح',
              message: 'ارجع إلى المرحلة واختر فصلًا آخر.',
            );
          }
          final item = matches.first;
          return StreamBuilder(
            stream: students.watchStudentsForClass(classId),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.hasError) {
                return _DashboardError(
                  onRetry: () => students.refreshStudents(classId),
                );
              }
              if (!studentSnapshot.hasData) {
                return const LoadingView(message: 'جاري تحميل ملخص الفصل...');
              }
              final rows = studentSnapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('ملخص التلاميذ والوصول السريع لأدوات الفصل.'),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _SummaryCard(
                        icon: Icons.school_rounded,
                        label: 'إجمالي التلاميذ',
                        value: '${rows.length}',
                      ),
                      _SummaryCard(
                        icon: Icons.pending_actions_rounded,
                        label: 'بانتظار الاعتماد',
                        value:
                            '${rows.where((student) => student.isPending).length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('class_dashboard_attendance'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MeetingPickerPage(
                          serviceId: serviceId,
                          classId: classId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.fact_check_rounded),
                    label: const Text('تسجيل الحضور'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('class_dashboard_students'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassStudentsPage(
                          classId: classId,
                          className: item.name,
                          serviceId: serviceId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.people_alt_outlined),
                    label: const Text('عرض قائمة التلاميذ'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'أحدث التلاميذ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (rows.isEmpty)
                    const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'لا يوجد تلاميذ مسجلون',
                      message: 'يمكن إضافة التلاميذ من صفحة الفصل.',
                    ),
                  for (final student in rows.take(5))
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(student.name.characters.first),
                      ),
                      title: Text(student.name),
                      subtitle: Text(
                        student.isPending
                            ? 'في انتظار الاعتماد'
                            : (student.school ?? 'بدون مدرسة مسجلة'),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: 'تعذر تحميل البيانات',
    message:
        'تحقق من الاتصال أو أعد المحاولة. ستظل البيانات المحفوظة متاحة دون اتصال.',
    action: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('إعادة المحاولة'),
    ),
  );
}
