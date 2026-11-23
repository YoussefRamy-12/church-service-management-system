import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
import '../../domain/entities/follow_up_case.dart';
import 'case_priority_badge.dart';
import 'case_status_badge.dart';

class FollowUpCaseCard extends StatelessWidget {
  const FollowUpCaseCard({
    super.key,
    required this.caseItem,
    required this.onTap,
  });

  final FollowUpCase caseItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Priority, Title, Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CasePriorityBadge(priority: caseItem.priority, dense: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  caseItem.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              CaseStatusBadge(status: caseItem.status, dense: true),
            ],
          ),
          const SizedBox(height: 8),
          // Student and Class details
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Text(
                caseItem.studentName ?? 'تلميذ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (caseItem.className != null) ...[
                const SizedBox(width: 6),
                Text(
                  '•',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 6),
                Text(
                  caseItem.className!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (caseItem.description != null &&
              caseItem.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caseItem.description!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          // Footer: Assigned servants count & Latest activity author
          Row(
            children: [
              // Assigned Servants Info
              Icon(
                Icons.supervised_user_circle_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                caseItem.assignedServantCount == 0
                    ? 'غير مكلف لخادم'
                    : caseItem.assignedServantNames.isNotEmpty
                        ? caseItem.assignedServantNames.join('، ')
                        : '${caseItem.assignedServantCount} خدام مكلفين',
                style: TextStyle(
                  fontSize: 11,
                  color: caseItem.assignedServantCount == 0
                      ? const Color(0xFFD97706)
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: caseItem.assignedServantCount == 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Latest Activity
              if (caseItem.latestActivityAuthorName != null) ...[
                Icon(
                  Icons.edit_note_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'آخر تحديث: ${caseItem.latestActivityAuthorName}',
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
    );
  }
}

