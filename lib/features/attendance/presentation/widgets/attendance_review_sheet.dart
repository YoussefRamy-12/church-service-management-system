import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
import '../../../students/domain/entities/student.dart';

class AttendanceReviewSheet extends StatelessWidget {
  const AttendanceReviewSheet({
    super.key,
    required this.students,
    required this.presentIds,
    required this.allStudentsMode,
    required this.readOnly,
  });

  final List<Student> students;
  final Set<String> presentIds;
  final bool allStudentsMode;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fact_check_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مراجعة الحضور',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'نسبة الحضور: ${presentIds.length} من أصل ${students.length}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  GlassBadge(
                    label: '${presentIds.length}/${students.length}',
                    color: theme.colorScheme.primary,
                    showDot: false,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: students.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: allStudentsMode
                          ? 'لا يوجد تلاميذ في الخدمة'
                          : 'لا يوجد تلاميذ في الفصل',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final present = presentIds.contains(student.id);
                        return SolidCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                present
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_outlined,
                                color: present
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF94A3B8),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              GlassBadge(
                                label: present ? 'حاضر' : 'غير مسجل',
                                color: present
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B),
                                showDot: present,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(readOnly ? 'إغلاق' : 'متابعة تسجيل الحضور'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
