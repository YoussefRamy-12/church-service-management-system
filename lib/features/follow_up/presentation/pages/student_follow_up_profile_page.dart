import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ui/app_ui.dart';
import '../../domain/entities/follow_up_student_item.dart';
import '../follow_up_case_providers.dart';
import '../widgets/follow_up_activity_card.dart';
import '../widgets/follow_up_case_card.dart';
import 'create_follow_up_case_page.dart';
import 'follow_up_case_details_page.dart';

class StudentFollowUpProfilePage extends ConsumerWidget {
  const StudentFollowUpProfilePage({
    super.key,
    required this.serviceId,
    required this.studentItem,
  });

  final String serviceId;
  final FollowUpStudentItem studentItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final student = studentItem.student;

    final casesStream = ref.watch(
      studentCasesProvider((serviceId: serviceId, studentId: student.id)),
    );
    final activitiesStream = ref.watch(
      studentActivitiesProvider(student.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(
            tooltip: 'فتح حالة متابعة جديدة',
            icon: const Icon(Icons.add_task_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateFollowUpCasePage(
                  serviceId: serviceId,
                  preselectedStudent: student,
                  classId: student.currentClassId ?? '',
                ),
              ),
            ),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.4,
        child: AppContent(
          maxWidth: 900,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // 1. Student Profile Header Card
              GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name.characters.first
                                  : '؟',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    size: 15,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    studentItem.className,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (student.phone != null &&
                                      student.phone!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.phone_rounded,
                                      size: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      student.phone!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    // Summary Metrics Row
                    Row(
                      children: [
                        _buildMetric(
                          context,
                          title: 'مرات الغياب',
                          value: '${studentItem.absenceCount}',
                          subtitle: 'من ${studentItem.totalEligibleMeetings} اجتماعات',
                          color: studentItem.absenceCount >= 2
                              ? const Color(0xFFDC2626)
                              : theme.colorScheme.onSurface,
                          icon: Icons.event_busy_rounded,
                        ),
                        const SizedBox(width: 12),
                        _buildMetric(
                          context,
                          title: 'حالات مفتوحة',
                          value: '${studentItem.activeCasesCount}',
                          subtitle: 'إجمالي الحالات: ${studentItem.totalCasesCount}',
                          color: studentItem.activeCasesCount > 0
                              ? const Color(0xFF2563EB)
                              : theme.colorScheme.onSurface,
                          icon: Icons.folder_open_rounded,
                        ),
                        const SizedBox(width: 12),
                        _buildMetric(
                          context,
                          title: 'آخر متابعة',
                          value: studentItem.latestFollowUpDate ?? 'لا يوجد',
                          subtitle: studentItem.latestFollowUpAuthor ?? 'لم يتم بعد',
                          color: theme.colorScheme.onSurface,
                          icon: Icons.history_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Cases Section Header & List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_shared_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'حالات المتابعة',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('حالة جديدة'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateFollowUpCasePage(
                          serviceId: serviceId,
                          preselectedStudent: student,
                          classId: student.currentClassId ?? '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              casesStream.when(
                data: (cases) {
                  if (cases.isEmpty) {
                    return const EmptyState(
                      icon: Icons.folder_off_outlined,
                      title: 'لا توجد حالات متابعة لهذا التلميذ',
                      message: 'يمكنك فتح حالة متابعة جديدة لتكليف الخدام بمتابعة محددة.',
                    );
                  }
                  return Column(
                    children: cases
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FollowUpCaseCard(
                              caseItem: c,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FollowUpCaseDetailsPage(
                                    serviceId: serviceId,
                                    caseId: c.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'تعذر تحميل الحالات',
                  message: '$err',
                ),
              ),

              const SizedBox(height: 24),

              // 3. Historical Activity Log Section
              Row(
                children: [
                  const Icon(Icons.timeline_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'سجل الأنشطة والمتابعات التاريخي',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'سجل زمني لجميع الاتصالات والافتقادات والملاحظات مع هوية كل كاتب',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              activitiesStream.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return const EmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'لا توجد أنشطة مسجلة بعد',
                      message: 'أي اتصال أو افتقاد يتم تسجيله سيظهر هنا بشكل غير قابل للتعديل.',
                    );
                  }
                  return Column(
                    children: activities
                        .map(
                          (act) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FollowUpActivityCard(
                              activity: act,
                              showCaseInfo: true,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'تعذر تحميل السجل التاريخي',
                  message: '$err',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

