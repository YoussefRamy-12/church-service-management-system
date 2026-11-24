import 'package:flutter/material.dart';
import '../../../../app/design/app_colors.dart';
import '../../../../app/design/app_radii.dart';
import '../../../../app/design/app_spacing.dart';
import '../../../../app/ui/components/sync_badge.dart';

class AttendanceSessionHeader extends StatelessWidget {
  const AttendanceSessionHeader({
    super.key,
    required this.className,
    required this.meetingName,
    required this.meetingDateFormatted,
    required this.presentCount,
    required this.absentCount,
    required this.totalCount,
    required this.isPendingSync,
    required this.readOnly,
    this.onSyncNow,
  });

  final String className;
  final String meetingName;
  final String meetingDateFormatted;
  final int presentCount;
  final int absentCount;
  final int totalCount;
  final bool isPendingSync;
  final bool readOnly;
  final VoidCallback? onSyncNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Read-only banner
          if (readOnly)
            Container(
              key: const Key('attendance_read_only_banner'),
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: palette.warning.background,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: palette.warning.foreground.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: palette.warning.foreground,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'عرض فقط — اجتماع سابق، تم إيقاف تعديل وتسجيل الحضور.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.warning.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Top Title Row: Class Name, Meeting date, SyncBadge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      className,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$meetingName • $meetingDateFormatted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              SyncBadge(
                state: isPendingSync ? SyncState.pending : SyncState.synced,
                label: isPendingSync ? 'تم التسجيل محليًا' : 'تمت المزامنة',
                onTap: onSyncNow,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Live Counters: Present / Not Marked / Total
          Row(
            children: [
              Expanded(
                child: _LiveCounterPill(
                  label: 'حاضر',
                  value: '$presentCount',
                  icon: Icons.check_circle_rounded,
                  foreground: palette.present.foreground,
                  background: palette.present.background,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _LiveCounterPill(
                  label: 'غير مسجل',
                  value: '$absentCount',
                  icon: Icons.cancel_outlined,
                  foreground: palette.absent.foreground,
                  background: palette.absent.background,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _LiveCounterPill(
                  label: 'إجمالي',
                  value: '$totalCount',
                  icon: Icons.groups_rounded,
                  foreground: theme.colorScheme.onSurface,
                  background: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveCounterPill extends StatelessWidget {
  const _LiveCounterPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: foreground.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
