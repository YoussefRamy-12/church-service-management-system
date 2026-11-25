import 'package:flutter/material.dart';

class AttendanceCounters extends StatelessWidget {
  const AttendanceCounters({
    super.key,
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.earlyCount,
    required this.beforeMeetingCount,
    required this.normalCount,
  });

  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int earlyCount;
  final int beforeMeetingCount;
  final int normalCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        AttendanceKpiPill(
          label: 'إجمالي المقيدين',
          value: '$totalCount',
          icon: Icons.groups_rounded,
          color: const Color(0xFF00236F),
        ),
        AttendanceKpiPill(
          label: 'حاضر',
          value: '$presentCount',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF059669),
        ),
        AttendanceKpiPill(
          label: 'غائب',
          value: '$absentCount',
          icon: Icons.cancel_outlined,
          color: const Color(0xFFDC2626),
        ),
        AttendanceKpiPill(
          label: 'مبكر',
          value: '$earlyCount',
          icon: Icons.star_rounded,
          color: const Color(0xFFD97706),
        ),
        AttendanceKpiPill(
          label: 'قبل الاجتماع',
          value: '$beforeMeetingCount',
          icon: Icons.access_time_filled_rounded,
          color: const Color(0xFF00236F),
        ),
        AttendanceKpiPill(
          label: 'عادي',
          value: '$normalCount',
          icon: Icons.schedule_rounded,
          color: const Color(0xFF0D9488),
        ),
      ],
    );
  }
}

class AttendanceKpiPill extends StatelessWidget {
  const AttendanceKpiPill({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
