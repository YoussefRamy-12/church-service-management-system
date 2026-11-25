import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../domain/entities/follow_up_student_item.dart';
import '../../../../core/ui/phone_contact_actions.dart';
import '../../../../app/design/app_colors.dart';

class FollowUpStudentCard extends StatelessWidget {
  const FollowUpStudentCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLogFollowUp,
  });

  final FollowUpStudentItem item;
  final VoidCallback onTap;
  final VoidCallback? onLogFollowUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHighAbsence = item.absenceCount >= 2;
    final semantic = AppColors.of(context);
    final reason = item.activeCasesCount > 0
        ? 'حالة متابعة مفتوحة'
        : hasHighAbsence
        ? 'غياب متكرر'
        : 'متابعة دورية';
    final reasonColor = item.needsFollowUp
        ? semantic.warning.foreground
        : theme.colorScheme.onSurfaceVariant;

    return AppCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  child: Text(
                    item.student.name.isNotEmpty
                        ? item.student.name.characters.first
                        : '؟',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Student Name & Class
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.className,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Follow-up reason/status
              Chip(
                avatar: Icon(
                  item.needsFollowUp
                      ? Icons.priority_high_rounded
                      : Icons.schedule_rounded,
                  size: 15,
                  color: reasonColor,
                ),
                label: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: reasonColor,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: item.needsFollowUp
                    ? semantic.warning.background
                    : theme.colorScheme.surfaceContainerHighest,
                side: BorderSide(
                  color: item.needsFollowUp
                      ? semantic.warning.foreground.withValues(alpha: 0.35)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              // Absence Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: hasHighAbsence
                      ? semantic.absent.background
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasHighAbsence
                        ? semantic.absent.foreground.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasHighAbsence
                          ? Icons.warning_amber_rounded
                          : Icons.event_busy_rounded,
                      size: 14,
                      color: hasHighAbsence
                          ? semantic.absent.foreground
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'غياب: ${item.absenceCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: hasHighAbsence
                            ? semantic.absent.foreground
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.6),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (item.student.phone != null && item.student.phone!.isNotEmpty)
                  PhoneContactActions(phone: item.student.phone!, compact: true),
                if (onLogFollowUp != null)
                  FilledButton.tonalIcon(
                    onPressed: onLogFollowUp,
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('تسجيل متابعة'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Footer Info: Active Cases + Latest Follow-up
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Active Cases Badge
              if (item.activeCasesCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatOpenCasesCount(item.activeCasesCount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Text(
                  item.totalCasesCount == 0
                      ? 'لا توجد حالات متابعة'
                      : 'الحالات السابقة: ${item.totalCasesCount}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Latest Follow-up
              if (item.latestFollowUpDate != null) ...[
                Icon(
                  Icons.history_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'آخر متابعة: ${AppDateFormatter.formatString(item.latestFollowUpDate)}${item.latestFollowUpAuthor != null ? ' (${item.latestFollowUpAuthor})' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else
                Text(
                  'لم تتم متابعته بعد',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
