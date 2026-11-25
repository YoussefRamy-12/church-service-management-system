import 'package:flutter/material.dart';
import '../../../../app/design/app_colors.dart';
import '../../../../app/design/app_radii.dart';
import '../../../../app/design/app_spacing.dart';
import '../../../../app/ui/components/status_chip.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/attendance_record.dart';

class AttendanceStudentTile extends StatelessWidget {
  const AttendanceStudentTile({
    super.key,
    required this.student,
    required this.record,
    required this.isBusy,
    required this.readOnly,
    required this.classColor,
    required this.classLabel,
    required this.attendanceTimingLabel,
    required this.onCheckIn,
    required this.onEditTime,
  });

  final Student student;
  final AttendanceRecord? record;
  final bool isBusy;
  final bool readOnly;
  final Color classColor;
  final String classLabel;
  final String attendanceTimingLabel;
  final VoidCallback onCheckIn;
  final VoidCallback onEditTime;

  @override
  Widget build(BuildContext context) {
    final isPresent = record != null;
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final statusWidget = isPresent
        ? StatusChip(
            status: AppStatus.present,
            label: attendanceTimingLabel.isNotEmpty
                ? 'حاضر • $attendanceTimingLabel'
                : 'حاضر',
          )
        : const StatusChip(status: AppStatus.notMarked, label: 'غير مسجل');

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        key: ValueKey('student_tile_${student.id}'),
        onTap: readOnly ? null : (isPresent ? onEditTime : onCheckIn),
        onLongPress: readOnly ? null : (isPresent ? onEditTime : null),
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: isPresent
                  ? palette.present.foreground.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with initials / first character
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPresent
                      ? palette.present.background
                      : (student.isPending
                            ? palette.pending.background
                            : theme.colorScheme.surfaceContainerHighest),
                  border: Border.all(
                    color: isPresent
                        ? palette.present.foreground.withValues(alpha: 0.4)
                        : (student.isPending
                              ? palette.pending.foreground.withValues(
                                  alpha: 0.3,
                                )
                              : theme.colorScheme.outlineVariant),
                  ),
                ),
                alignment: Alignment.center,
                child: isPresent
                    ? Icon(
                        Icons.check_rounded,
                        color: palette.present.foreground,
                        size: 20,
                      )
                    : Text(
                        student.name.isNotEmpty
                            ? student.name.characters.first
                            : 'ت',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: student.isPending
                              ? palette.pending.foreground
                              : theme.colorScheme.onSurface,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Student Details: Name, class chip, pending chip, check-in time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      student.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (classLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: classColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppRadii.chip,
                              ),
                            ),
                            child: Text(
                              classLabel,
                              style: TextStyle(
                                color: classColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (student.isPending)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.pending.background,
                              borderRadius: BorderRadius.circular(
                                AppRadii.chip,
                              ),
                            ),
                            child: Text(
                              'بانتظار الاعتماد',
                              style: TextStyle(
                                color: palette.pending.foreground,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (isPresent)
                          Text(
                            TimeOfDay.fromDateTime(
                              record!.checkedInAt,
                            ).format(context),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // Status Chip (icon + Arabic label + color)
              statusWidget,

              // Trailing action button (Edit time when present, checkmark when not marked, spinner when busy)
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (isPresent && !readOnly)
                IconButton(
                  icon: const Icon(Icons.access_time_rounded, size: 18),
                  tooltip: 'تعديل وقت الحضور',
                  onPressed: onEditTime,
                  style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                )
              else if (!isPresent && !readOnly)
                IconButton(
                  key: ValueKey('checkin_btn_${student.id}'),
                  icon: Icon(
                    Icons.how_to_reg_outlined,
                    size: 20,
                    color: palette.present.foreground,
                  ),
                  tooltip: 'تسجيل الحضور',
                  onPressed: onCheckIn,
                  style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
