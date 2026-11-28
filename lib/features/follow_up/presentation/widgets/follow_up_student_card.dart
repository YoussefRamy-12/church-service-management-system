import 'package:flutter/material.dart';
import '../../../../app/design/app_colors.dart';
import '../../../../app/ui/app_ui.dart';
import '../../../../core/ui/phone_contact_actions.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../domain/entities/follow_up_student_item.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Avatar, name, class
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                      fontSize: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 13,
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
          const SizedBox(height: 8),
          // Row 2: Reason chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
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
                    const SizedBox(width: 4),
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
              if (item.activeCasesCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 13,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatOpenCasesCount(item.activeCasesCount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 3: Last contact on one line
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.latestFollowUpDate != null
                      ? 'آخر متابعة: ${AppDateFormatter.formatString(item.latestFollowUpDate)}${item.latestFollowUpAuthor != null ? ' (${item.latestFollowUpAuthor})' : ''}'
                      : 'لم تتم متابعته بعد',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 4: [call] [WhatsApp] (48px) + primary "تسجيل متابعة"
          Row(
            children: [
              if (item.student.phone != null && item.student.phone!.isNotEmpty)
                PhoneContactActions(phone: item.student.phone!, compact: false),
              const Spacer(),
              if (onLogFollowUp != null)
                FilledButton.icon(
                  onPressed: onLogFollowUp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('تسجيل متابعة'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
