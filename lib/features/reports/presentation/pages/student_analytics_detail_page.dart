import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/ui/app_ui.dart';
import '../../domain/analytics_models.dart';

class StudentAnalyticsDetailPage extends ConsumerWidget {
  const StudentAnalyticsDetailPage({
    super.key,
    required this.student,
  });

  final RepeatedAbsenceRecord student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isSevere = student.consecutiveMissedMeetings >= 3;
    final badgeColor = isSevere ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.studentName),
      ),
      body: AmbientBackground(
        intensity: 0.4,
        child: AppContent(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Hero Student Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D33) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF00236F).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: Color(0xFF00236F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student.studentName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.className,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: badgeColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'غائب عن ${student.consecutiveMissedMeetings} اجتماعات متتالية',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (student.phone != null && student.phone!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('tel:${student.phone}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: Text('الاتصال بالتلميذ (${student.phone})'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Diagnostic Info
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D33) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المعلومات التشخيصية للغياب',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      'تاريخ آخر حضور مسجل',
                      student.lastAttendedDate ?? 'لا يوجد حضور مسجل في هذه الفترة',
                      isDark,
                    ),
                    const Divider(height: 16),
                    _infoRow(
                      'مستوى الخطورة الرعوية',
                      isSevere ? 'حرج (يتطلب زيارة عاجلة)' : 'متوسط (يتطلب مكالمة افتقاد)',
                      isDark,
                      textColor: badgeColor,
                    ),
                    const Divider(height: 16),
                    _infoRow(
                      'الإجراء الموصى به',
                      'تنسيق افتقاد مباشر مع خادم الفصل وتوثيق الحالة في سجل المتابعة.',
                      isDark,
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

  Widget _infoRow(String label, String value, bool isDark, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}

