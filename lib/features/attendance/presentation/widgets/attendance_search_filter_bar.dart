import 'package:flutter/material.dart';
import '../../../../app/ui/app_ui.dart';
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
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final AttendanceFilter filter;
  final ValueChanged<AttendanceFilter> onFilterChanged;
  final int totalCount;
  final int presentCount;
  final int absentCount;

  @override
  Widget build(BuildContext context) {
    return SolidCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 12,
      child: Column(
        children: [
          TextField(
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 22,
              ),
              hintText: 'ابحث باسم التلميذ...',
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                      ),
                      onPressed: () => onQueryChanged(''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          const Divider(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AttendanceFilterChipButton(
                  label: 'الكل ($totalCount)',
                  selected: filter == AttendanceFilter.all,
                  onTap: () => onFilterChanged(AttendanceFilter.all),
                ),
                const SizedBox(width: 6),
                AttendanceFilterChipButton(
                  label: 'حاضر ($presentCount)',
                  selected: filter == AttendanceFilter.present,
                  color: const Color(0xFF059669),
                  onTap: () => onFilterChanged(AttendanceFilter.present),
                ),
                const SizedBox(width: 6),
                AttendanceFilterChipButton(
                  label: 'غائب ($absentCount)',
                  selected: filter == AttendanceFilter.absent,
                  color: const Color(0xFFDC2626),
                  onTap: () => onFilterChanged(AttendanceFilter.absent),
                ),
                const SizedBox(width: 6),
                AttendanceFilterChipButton(
                  label: 'بانتظار الاعتماد',
                  selected: filter == AttendanceFilter.pending,
                  color: const Color(0xFFD97706),
                  onTap: () => onFilterChanged(AttendanceFilter.pending),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceFilterChipButton extends StatelessWidget {
  const AttendanceFilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF00236F);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? effectiveColor
              : effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? effectiveColor
                : effectiveColor.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : effectiveColor,
          ),
        ),
      ),
    );
  }
}
