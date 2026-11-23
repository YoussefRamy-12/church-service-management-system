import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/analytics_models.dart';

class RepeatedAbsencesTable extends StatelessWidget {
  const RepeatedAbsencesTable({
    super.key,
    required this.repeatedAbsences,
    this.onStudentTap,
  });

  final List<RepeatedAbsenceRecord> repeatedAbsences;
  final ValueChanged<RepeatedAbsenceRecord>? onStudentTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (repeatedAbsences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D33) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'لا توجد حالات غياب متكرر حالياً',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'جميع التلاميذ المسجلين يلتزمون بالحضور دون انقطاع مستمر.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_off_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'سجل الغياب المتكرر',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${repeatedAbsences.length} تلميذ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: repeatedAbsences.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = repeatedAbsences[index];
              final isSevere = item.consecutiveMissedMeetings >= 3;
              final badgeColor = isSevere
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF59E0B);

              return InkWell(
                onTap: onStudentTap != null ? () => onStudentTap!(item) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        child: Text(
                          '${item.consecutiveMissedMeetings}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.studentName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.className} • آخر حضور: ${item.lastAttendedDate ?? "لم يسجل حضور مؤخراً"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.phone != null && item.phone!.isNotEmpty) ...[
                        IconButton(
                          tooltip: 'الاتصال بالتلميذ / ولي الأمر',
                          icon: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          onPressed: () async {
                            final uri = Uri.parse('tel:${item.phone}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

