import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../app/ui/app_ui.dart';
import 'attendance_providers.dart';

class AttendancePage extends ConsumerWidget {
  const AttendancePage({
    super.key,
    required this.meetingId,
    required this.classId,
    required this.recordedBy,
    required this.students,
  });

  final String meetingId;
  final String classId;
  final String recordedBy;
  final List<({String id, String name})> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(attendanceRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل حضور الفصل'),
      ),
      body: StreamBuilder(
        stream: repository.watchForMeeting(meetingId),
        builder: (context, snapshot) {
          final checked = {
            for (final row in snapshot.data ?? const []) row.studentId,
          };
          final checkedCount = checked.length;
          final totalCount = students.length;
          final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

          if (students.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.groups_outlined,
                title: 'لا يوجد تلاميذ في هذا الفصل',
                message: 'تأكد من إضافة التلاميذ إلى هذا الفصل في شاشة الإعدادات أو قائمة التلاميذ.',
              ),
            );
          }

          return AppContent(
            maxWidth: 800,
            child: ListView(
              children: [
                // Attendance Summary Banner
                SolidCard(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: appSuccess.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fact_check_rounded,
                              color: appSuccess,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'نسبة الحضور الحالية',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: appMutedInk,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$checkedCount من أصل $totalCount تلميذ (${(progress * 100).toInt()}%)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GlassBadge(
                            label: '${(progress * 100).toInt()}%',
                            color: progress >= 0.75
                                ? appSuccess
                                : (progress >= 0.40 ? appWarning : appPrimary),
                            showDot: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : appMistBlue,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 0.75 ? appSuccess : appPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const ModernSectionHeader(
                  title: 'قائمة تلاميذ الفصل',
                  subtitle: 'اضغط على زر التسجيل لرصد حضور التلميذ فورياً',
                ),
                const SizedBox(height: 8),

                for (final student in students) ...[
                  Builder(
                    builder: (context) {
                      final present = checked.contains(student.id);
                      final name = student.name;
                      return SolidCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        borderRadius: 14,
                        color: present
                            ? appSuccess.withValues(alpha: isDark ? 0.10 : 0.04)
                            : null,
                        border: present
                            ? Border.all(
                                color: appSuccess.withValues(alpha: 0.30),
                                width: 1.2,
                              )
                            : null,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: (present ? appSuccess : appPrimary)
                                  .withValues(alpha: 0.12),
                              foregroundColor: present ? appSuccess : appPrimary,
                              child: Text(
                                name.trim().isNotEmpty
                                    ? name.trim().characters.first
                                    : 'ت',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: present ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (present)
                              const GlassBadge(
                                label: 'حاضر',
                                color: appSuccess,
                                icon: Icons.check_circle_rounded,
                                showDot: false,
                              )
                            else
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(100, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                                label: const Text('تسجيل'),
                                onPressed: () async {
                                  await repository.checkIn(
                                    meetingId: meetingId,
                                    studentId: student.id,
                                    classIdAtAttendance: classId,
                                    recordedBy: recordedBy,
                                    checkedInAt: DateTime.now(),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
