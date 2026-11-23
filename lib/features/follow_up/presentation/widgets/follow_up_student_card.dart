import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
import '../../domain/entities/follow_up_student_item.dart';

class FollowUpStudentCard extends StatelessWidget {
  const FollowUpStudentCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final FollowUpStudentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHighAbsence = item.absenceCount >= 2;

    return GlassCard(
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
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                      color: theme.colorScheme.primary,
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
                        Text(
                          item.className,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Absence Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasHighAbsence
                      ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasHighAbsence
                        ? const Color(0xFFDC2626).withValues(alpha: 0.3)
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
                          ? const Color(0xFFDC2626)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'غياب: ${item.absenceCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: hasHighAbsence
                            ? const Color(0xFFDC2626)
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
          // Footer Info: Active Cases + Latest Follow-up
          Row(
            children: [
              // Active Cases Badge
              if (item.activeCasesCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.folder_open_rounded,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.activeCasesCount} حالات مفتوحة',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
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
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              // Latest Follow-up
              if (item.latestFollowUpDate != null) ...[
                Icon(
                  Icons.history_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'آخر متابعة: ${item.latestFollowUpDate}${item.latestFollowUpAuthor != null ? ' (${item.latestFollowUpAuthor})' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ] else
                Text(
                  'لم تتم متابعته بعد',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

