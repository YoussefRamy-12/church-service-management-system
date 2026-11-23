import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/ui/app_ui.dart';
import '../../../auth/domain/entities/session_identity.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/entities/case_status.dart';
import '../../domain/entities/follow_up_case.dart';
import '../follow_up_case_providers.dart';
import '../widgets/case_priority_badge.dart';
import '../widgets/case_status_badge.dart';
import '../widgets/follow_up_activity_card.dart';
import 'add_follow_up_activity_page.dart';
import 'assign_servants_dialog.dart';

class FollowUpCaseDetailsPage extends ConsumerWidget {
  const FollowUpCaseDetailsPage({
    super.key,
    required this.serviceId,
    required this.caseId,
  });

  final String serviceId;
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final caseAsync = ref.watch(followUpCaseByIdProvider(caseId));
    final assignmentsStream = ref.watch(caseAssignmentsProvider(caseId));
    final activitiesStream = ref.watch(caseActivitiesProvider(caseId));
    final profileAsync = ref.watch(currentServantProfileProvider);

    final profile = profileAsync.hasValue ? profileAsync.value : null;
    final userRole = profile?.role;
    final isLeader = userRole == 'overall_leader' ||
        userRole == 'overall_helper' ||
        userRole == 'stage_leader' ||
        userRole == 'class_leader';

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل حالة المتابعة'),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => invalidateFollowUpCaseData(
              ref,
              serviceId: serviceId,
              caseId: caseId,
            ),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.35,
        child: AppContent(
          maxWidth: 900,
          child: caseAsync.when(
            data: (caseItem) {
              if (caseItem == null) {
                return const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'حالة المتابعة غير موجودة',
                  message: 'ربما تم حذفها أو نقلها.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // 1. Case Header GlassCard
                  GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CasePriorityBadge(priority: caseItem.priority),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                caseItem.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CaseStatusBadge(status: caseItem.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Student & Class
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              caseItem.studentName ?? 'تلميذ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (caseItem.className != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.groups_rounded,
                                size: 15,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                caseItem.className!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (caseItem.description != null &&
                            caseItem.description!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              caseItem.description!,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        // Metadata & Status Changer Action
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'أنشأها: ${caseItem.creatorName ?? "خادم"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '•  ${DateFormat('yyyy-MM-dd').format(caseItem.createdAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            // Status Transition Button
                            _buildStatusChanger(context, ref, caseItem, userRole),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Assigned Servants Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.supervised_user_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'الخدام المكلفون بالمتابعة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (isLeader)
                        assignmentsStream.when(
                          data: (assignments) => TextButton.icon(
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: const Text('إدارة التكليفات'),
                            onPressed: () async {
                              await showDialog(
                                context: context,
                                builder: (_) => AssignServantsDialog(
                                  serviceId: serviceId,
                                  caseId: caseItem.id,
                                  classId: caseItem.classId,
                                  assignedByProfileId: profile?.id ?? '',
                                  currentAssignments: assignments,
                                ),
                              );
                              invalidateFollowUpCaseData(
                                ref,
                                serviceId: serviceId,
                                studentId: caseItem.studentId,
                                caseId: caseItem.id,
                              );
                            },
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  assignmentsStream.when(
                    data: (assignments) {
                      final activeAssignments =
                          assignments.where((a) => a.isActive).toList();

                      if (activeAssignments.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'لم يتم تكليف أي خادم بعد. يمكن لأمين الفصل أو المسؤولين تكليف خدام.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activeAssignments.map((a) {
                          return Chip(
                            avatar: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              child: Text(
                                a.servantName?.characters.first ?? 'خ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            label: Text(
                              '${a.servantName ?? "خادم"}${a.servantRole != null ? " (${formatRoleLabel(a.servantRole)})" : ""}',
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('خطأ في تحميل التكليفات: $err'),
                  ),
                  const SizedBox(height: 24),

                  // 3. Activity Timeline Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'سجل الأنشطة والاتصالات',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_comment_rounded, size: 16),
                        label: const Text('تسجيل متابعة'),
                        onPressed: () async {
                          final recorded = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddFollowUpActivityPage(
                                caseId: caseItem.id,
                                serviceId: serviceId,
                                caseTitle: caseItem.title,
                                studentName: caseItem.studentName ?? 'التلميذ',
                              ),
                            ),
                          );
                          if (recorded == true) {
                            invalidateFollowUpCaseData(
                              ref,
                              serviceId: serviceId,
                              studentId: caseItem.studentId,
                              caseId: caseItem.id,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  activitiesStream.when(
                    data: (activities) {
                      if (activities.isEmpty) {
                        return const EmptyState(
                          icon: Icons.rate_review_outlined,
                          title: 'لا توجد أنشطة مسجلة في هذه الحالة',
                          message: 'اضغط على "تسجيل متابعة" لإضافة مكالمة أو افتقاد أو ملاحظة.',
                        );
                      }

                      return Column(
                        children: activities
                            .map(
                              (act) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: FollowUpActivityCard(activity: act),
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
                      title: 'تعذر تحميل الأنشطة',
                      message: '$err',
                    ),
                  ),
                ],
              );
            },
            loading: () => const LoadingView(message: 'جاري تحميل تفاصيل الحالة...'),
            error: (err, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'تعذر تحميل الحالة',
              message: '$err',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChanger(
    BuildContext context,
    WidgetRef ref,
    FollowUpCase caseItem,
    String? userRole,
  ) {
    final allowed = caseItem.status.allowedTransitions(role: userRole);
    if (allowed.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<CaseStatus>(
      tooltip: 'تغيير حالة المتابعة',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync_alt_rounded, size: 14),
            const SizedBox(width: 4),
            Text(
              'تغيير الحالة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      onSelected: (newStatus) async {
        final profile = await ref.read(currentServantProfileProvider.future);
        final identity = await ref.read(currentSessionIdentityProvider.future);
        final actorId = profile?.id ??
            (identity is SuperAdminIdentity ? identity.profile.id : null);

        if (actorId == null) return;

        await ref.read(followUpCaseRepositoryProvider).updateCaseStatus(
              caseId: caseItem.id,
              newStatus: newStatus,
              actorId: actorId,
              actorRole: userRole ?? 'class_servant',
            );

        invalidateFollowUpCaseData(
          ref,
          serviceId: serviceId,
          studentId: caseItem.studentId,
          caseId: caseItem.id,
        );
      },
      itemBuilder: (context) {
        return allowed.map((status) {
          return PopupMenuItem<CaseStatus>(
            value: status,
            child: Row(
              children: [
                Icon(status.icon, size: 16, color: status.color),
                const SizedBox(width: 8),
                Text(status.arabicLabel),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
