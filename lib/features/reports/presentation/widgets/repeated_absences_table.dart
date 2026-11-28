import 'package:flutter/material.dart';
import '../../../../core/ui/phone_contact_actions.dart';
import '../../../../app/design/app_colors.dart';
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

    if (repeatedAbsences.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
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
                  color: AppColors.of(context).present.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.of(context).present.foreground,
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
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).absent.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_off_rounded,
                          color: AppColors.of(context).absent.foreground,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'سجل الغياب المتكرر',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).absent.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${repeatedAbsences.length} تلميذ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).absent.foreground,
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
                  ? AppColors.of(context).absent.foreground
                  : AppColors.of(context).pending.foreground;

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
                            badgeColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1),
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
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.phone != null && item.phone!.isNotEmpty) ...[
                        PhoneContactActions(
                          phone: item.phone!,
                          compact: true,
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
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

