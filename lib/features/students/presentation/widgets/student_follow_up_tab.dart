import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ui/app_ui.dart';
import '../../../follow_up/presentation/follow_up_case_providers.dart';
import '../../../follow_up/presentation/follow_up_providers.dart';
import '../../../follow_up/presentation/pages/create_follow_up_case_page.dart';
import '../../../follow_up/presentation/pages/follow_up_case_details_page.dart';
import '../../../follow_up/presentation/widgets/case_priority_badge.dart';
import '../../../follow_up/presentation/widgets/case_status_badge.dart';
import '../../../follow_up/presentation/widgets/follow_up_activity_card.dart';
import '../../domain/entities/student.dart';

class StudentFollowUpTab extends ConsumerWidget {
  const StudentFollowUpTab({super.key, required this.student});
  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(
      studentCasesProvider((
        serviceId: student.serviceId,
        studentId: student.id,
      )),
    );
    final activitiesAsync = ref.watch(
      studentActivitiesProvider((
        serviceId: student.serviceId,
        studentId: student.id,
      )),
    );

    return AppContent(
      maxWidth: 900,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'حالات المتابعة',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              FilledButton.icon(
                key: const Key('student_follow_up_add'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateFollowUpCasePage(
                      serviceId: student.serviceId,
                      preselectedStudent: student,
                      classId: student.currentClassId ?? student.proposedClassId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('فتح حالة'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          casesAsync.when(
            loading: () => const LoadingView(
              message: 'جاري تحميل حالات المتابعة...',
            ),
            error: (error, _) {
              return const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر تحميل حالات المتابعة',
                message: 'حاول تحديث الصفحة.',
              );
            },
            data: (cases) {
              if (cases.isEmpty) {
                return const EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'لا توجد حالات متابعة',
                  message: 'افتح حالة جديدة لتسجيل المتابعة ومراحلها في ملف التلميذ.',
                );
              }
              return Column(
                children: cases.map((caseItem) {
                  return Card(
                    key: ValueKey('student_follow_up_case_${caseItem.id}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FollowUpCaseDetailsPage(
                            serviceId: student.serviceId,
                            caseId: caseItem.id,
                          ),
                        ),
                      ),
                      leading: const Icon(Icons.folder_shared_outlined),
                      title: Text(
                        caseItem.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            CaseStatusBadge(
                              status: caseItem.status,
                              dense: true,
                            ),
                            CasePriorityBadge(
                              priority: caseItem.priority,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'سجل الأنشطة والافتقاد',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          activitiesAsync.when(
            loading: () => const LoadingView(
              message: 'جاري تحميل سجل الأنشطة...',
            ),
            error: (error, _) {
              return const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر تحميل سجل الأنشطة',
                message: 'حاول تحديث الصفحة.',
              );
            },
            data: (activities) {
              if (activities.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'لا توجد أنشطة مسجلة',
                  message: 'ستظهر هنا كل الاتصالات والزيارات وتغييرات الحالة.',
                );
              }
              return Column(
                children: activities
                    .map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FollowUpActivityCard(
                          activity: activity,
                          showCaseInfo: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FollowUpCaseDetailsPage(
                                  serviceId: student.serviceId,
                                  caseId: activity.caseId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'السجل السابق (قبل نظام الحالات)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: ref.watch(followUpRepositoryProvider).watchForStudent(
              student.id,
              serviceId: student.serviceId,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('تعذر تحميل السجل السابق.');
              }
              if (!snapshot.hasData) {
                return const LoadingView(message: 'جاري تحميل السجل السابق...');
              }
              final legacyRecords = snapshot.data!;
              if (legacyRecords.isEmpty) {
                return const Text(
                  'لا توجد سجلات سابقة محفوظة.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return Column(
                children: legacyRecords.map((record) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      record.contactStatus == 'contacted'
                          ? Icons.call_made_rounded
                          : Icons.phone_missed_rounded,
                    ),
                    title: Text(
                      '${record.followUpDate} — ${record.contactStatus == 'contacted' ? 'تم التواصل' : 'لم يتم التواصل'}',
                    ),
                    subtitle: Text(
                      record.notes?.isNotEmpty == true
                          ? record.notes!
                          : (record.actionRequired?.isNotEmpty == true
                              ? record.actionRequired!
                              : 'لا توجد ملاحظات'),
                    ),
                    trailing: record.anotherFollowUpNeeded
                        ? const Tooltip(
                            message: 'متابعة أخرى مطلوبة',
                            child: Icon(Icons.event_repeat_rounded),
                          )
                        : null,
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

