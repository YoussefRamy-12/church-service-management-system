// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/presentation/service_providers.dart';
import '../../students/presentation/student_providers.dart';
import 'follow_up_page.dart';
import 'absence_prioritization_page.dart';
import 'weekly_follow_up_page.dart';
import '../../../app/ui/app_ui.dart';
import '../../auth/presentation/auth_providers.dart';
import 'follow_up_scope.dart';

class FollowUpHubPage extends ConsumerStatefulWidget {
  const FollowUpHubPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<FollowUpHubPage> createState() => _FollowUpHubPageState();
}

class _FollowUpHubPageState extends ConsumerState<FollowUpHubPage> {
  String query = '';
  late Future<FollowUpScope> _scope;

  @override
  void initState() {
    super.initState();
    _scope = _loadScope();
    Future.microtask(
      () => ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId),
    );
  }

  Future<FollowUpScope> _loadScope() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    return resolveFollowUpClassScope(
      services: ref.read(serviceRepositoryProvider),
      serviceId: widget.serviceId,
      profile: profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(serviceRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتابعة'),
        actions: [
          IconButton(
            key: const Key('follow_up_weekly'),
            tooltip: 'متابعات هذا الأسبوع',
            icon: const Icon(Icons.calendar_view_week_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeeklyFollowUpPage(serviceId: widget.serviceId),
              ),
            ),
          ),
          IconButton(
            key: const Key('follow_up_priority'),
            tooltip: 'أولوية حسب الغياب',
            icon: const Icon(Icons.priority_high_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AbsencePrioritizationPage(serviceId: widget.serviceId),
              ),
            ),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.5,
        child: AppContent(
          maxWidth: 1000,
          child: FutureBuilder<FollowUpScope>(
            future: _scope,
            builder: (context, scopeSnapshot) {
              if (scopeSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'جاري تحميل نطاق الخدمة...');
              }
              if (scopeSnapshot.hasError) {
                return const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'تعذر تحديد نطاق المتابعة',
                  message: 'حدّث البيانات ثم حاول مرة أخرى.',
                );
              }
              final scope = scopeSnapshot.data!;
              return StreamBuilder(
                stream: services.watchStages(widget.serviceId),
                builder: (context, stageSnapshot) {
                  final stages = (stageSnapshot.data ?? const [])
                      .where(
                        (stage) =>
                            scope.stageIds == null ||
                            scope.stageIds!.contains(stage.id),
                      )
                      .toList();
                  if (stageSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      stages.isEmpty) {
                    return const LoadingView(message: 'جاري تحميل المراحل...');
                  }
                  if (stages.isEmpty) {
                    return const EmptyState(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'لا توجد مراحل متاحة',
                      message: 'حدّث البيانات عند توفر اتصال.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // Quick Action Navigation Cards (Responsive Stack <620px)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 620;
                          final weeklyCard = GlassCard(
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WeeklyFollowUpPage(
                                  serviceId: widget.serviceId,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00236F).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF00236F).withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_view_week_rounded,
                                    color: Color(0xFF00236F),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'متابعات الأسبوع',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'خطة الاتصال والتواصل الأسبوعية',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          );

                          final absenceCard = GlassCard(
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AbsencePrioritizationPage(
                                  serviceId: widget.serviceId,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.20),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.priority_high_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'أولوية الغياب',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'المتغيبون أكثر من أسبوع متتالي',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                weeklyCard,
                                const SizedBox(height: 10),
                                absenceCard,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: weeklyCard),
                              const SizedBox(width: 12),
                              Expanded(child: absenceCard),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      // Search Card
                      GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(8),
                        hoverElevation: false,
                        child: TextField(
                          key: const Key('follow_up_search'),
                          onChanged: (value) =>
                              setState(() => query = value.trim()),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            hintText: 'ابحث باسم التلميذ للمتابعة...',
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'مسح البحث',
                                    onPressed: () => setState(() => query = ''),
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final stage in stages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            borderRadius: 12,
                            padding: EdgeInsets.zero,
                            hoverElevation: false,
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: Key('follow_up_stage_' + stage.id),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00236F,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.layers_outlined,
                                    color: Color(0xFF00236F),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  stage.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                onExpansionChanged: (expanded) {
                                  if (expanded) {
                                    services.refreshClasses(stage.id);
                                  }
                                },
                                children: [
                                  StreamBuilder(
                                    stream: services.watchClasses(stage.id),
                                    builder: (context, classSnapshot) {
                                      final classes =
                                          (classSnapshot.data ?? const [])
                                              .where(
                                                (item) =>
                                                    scope.classIds == null ||
                                                    scope.classIds!.contains(
                                                      item.id,
                                                    ),
                                              )
                                              .toList();
                                      return Column(
                                        children: [
                                          for (final item in classes)
                                            Theme(
                                              data: Theme.of(context).copyWith(
                                                dividerColor:
                                                    Colors.transparent,
                                              ),
                                              child: ExpansionTile(
                                                key: Key(
                                                  'follow_up_class_' + item.id,
                                                ),
                                                leading: const Icon(
                                                  Icons.groups_outlined,
                                                ),
                                                title: Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                onExpansionChanged: (expanded) {
                                                  if (expanded) {
                                                    ref
                                                        .read(
                                                          studentRepositoryProvider,
                                                        )
                                                        .refreshStudents(
                                                          item.id,
                                                        );
                                                  }
                                                },
                                                children: [
                                                  StreamBuilder(
                                                    stream: ref
                                                        .watch(
                                                          studentRepositoryProvider,
                                                        )
                                                        .watchStudentsForClass(
                                                          item.id,
                                                        ),
                                                    builder: (context, studentSnapshot) {
                                                      final students =
                                                          studentSnapshot
                                                              .data ??
                                                          const [];
                                                      final filtered = students
                                                          .where(
                                                            (student) => student
                                                                .name
                                                                .toLowerCase()
                                                                .contains(
                                                                  query
                                                                      .toLowerCase(),
                                                                ),
                                                          )
                                                          .toList();
                                                      if (studentSnapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting &&
                                                          students.isEmpty) {
                                                        return const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                16,
                                                              ),
                                                          child:
                                                              LinearProgressIndicator(),
                                                        );
                                                      }
                                                      if (filtered.isEmpty) {
                                                        return const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                16,
                                                              ),
                                                          child: Text(
                                                            'لا توجد نتائج في هذا الفصل.',
                                                          ),
                                                        );
                                                      }
                                                      return Column(
                                                        children: [
                                                          for (final student
                                                              in filtered)
                                                            ListTile(
                                                              key: Key(
                                                                'follow_up_student_' +
                                                                    student.id,
                                                              ),
                                                              leading: Container(
                                                                width: 36,
                                                                height: 36,
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Theme.of(
                                                                        context,
                                                                      ).colorScheme.primary.withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    student
                                                                            .name
                                                                            .isEmpty
                                                                        ? '؟'
                                                                        : student
                                                                              .name
                                                                              .characters
                                                                              .first,
                                                                    style: TextStyle(
                                                                      color: Theme.of(
                                                                        context,
                                                                      ).colorScheme.primary,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w800,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              title: Text(
                                                                student.name,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              trailing: const Icon(
                                                                Icons
                                                                    .chevron_left_rounded,
                                                              ),
                                                              onTap: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).push(
                                                                    MaterialPageRoute(
                                                                      builder: (_) => FollowUpPage(
                                                                        student:
                                                                            student,
                                                                      ),
                                                                    ),
                                                                  ),
                                                            ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
