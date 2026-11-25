import 'package:flutter/material.dart';
import '../../../../app/design/app_colors.dart';
import '../../../../app/design/app_radii.dart';
import '../../../../app/design/app_spacing.dart';
import 'attendance_filter.dart';

class AttendanceSearchFilterBar extends StatelessWidget {
  const AttendanceSearchFilterBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.filter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    this.pendingCount = 0,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final AttendanceFilter filter;
  final ValueChanged<AttendanceFilter> onFilterChanged;
  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Field
          TextField(
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'ابحث عن تلميذ...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      tooltip: 'مسح البحث',
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => onQueryChanged(''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.control),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.control),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.control),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Filter Chips: الكل / حاضر / غير مسجل
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  key: const Key('attendance_filter_all'),
                  label: 'الكل ($totalCount)',
                  selected: filter == AttendanceFilter.all,
                  onTap: () => onFilterChanged(AttendanceFilter.all),
                  activeForeground: theme.colorScheme.onPrimary,
                  activeBackground: theme.colorScheme.primary,
                  inactiveForeground: theme.colorScheme.onSurface,
                  inactiveBackground: theme.colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  key: const Key('attendance_filter_present'),
                  label: 'حاضر ($presentCount)',
                  selected: filter == AttendanceFilter.present,
                  onTap: () => onFilterChanged(AttendanceFilter.present),
                  activeForeground: palette.present.foreground,
                  activeBackground: palette.present.background,
                  inactiveForeground: palette.present.foreground,
                  inactiveBackground: palette.present.background.withValues(alpha: 0.35),
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  key: const Key('attendance_filter_absent'),
                  label: 'غير مسجل ($absentCount)',
                  selected: filter == AttendanceFilter.absent,
                  onTap: () => onFilterChanged(AttendanceFilter.absent),
                  activeForeground: palette.absent.foreground,
                  activeBackground: palette.absent.background,
                  inactiveForeground: palette.absent.foreground,
                  inactiveBackground: palette.absent.background.withValues(alpha: 0.35),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    key: const Key('attendance_filter_pending'),
                    label: 'بانتظار الاعتماد ($pendingCount)',
                    selected: filter == AttendanceFilter.pending,
                    onTap: () => onFilterChanged(AttendanceFilter.pending),
                    activeForeground: palette.pending.foreground,
                    activeBackground: palette.pending.background,
                    inactiveForeground: palette.pending.foreground,
                    inactiveBackground: palette.pending.background.withValues(alpha: 0.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeForeground,
    required this.activeBackground,
    required this.inactiveForeground,
    required this.inactiveBackground,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeForeground;
  final Color activeBackground;
  final Color inactiveForeground;
  final Color inactiveBackground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.chip),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeBackground : inactiveBackground,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(
            color: selected
                ? activeForeground.withValues(alpha: 0.5)
                : Colors.transparent,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? activeForeground : inactiveForeground,
          ),
        ),
      ),
    );
  }
}
