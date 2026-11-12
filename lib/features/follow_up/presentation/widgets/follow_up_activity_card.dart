import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
import '../../domain/entities/follow_up_activity.dart';

class FollowUpActivityCard extends StatelessWidget {
  const FollowUpActivityCard({
    super.key,
    required this.activity,
    this.showCaseInfo = false,
    this.onTap,
  });

  final FollowUpActivity activity;
  final bool showCaseInfo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = activity.activityType;

    return GlassCard(
      borderRadius: 12,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Header: Icon, Type, Date, Author
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: type.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(type.icon, size: 16, color: type.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.arabicLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: type.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          activity.authorName ?? 'خادم',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        if (activity.authorRole != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${formatRoleLabel(activity.authorRole)})',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Activity Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    activity.activityDate,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(activity.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            activity.description,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (showCaseInfo &&
              (activity.studentName != null || activity.caseTitle != null)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (activity.studentName != null) ...[
                    Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity.studentName!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (activity.caseTitle != null) ...[
                    Icon(
                      Icons.folder_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.caseTitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (onTap != null) ...[
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

