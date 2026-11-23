import 'package:flutter/material.dart';
import '../../domain/analytics_models.dart';

class AttendanceTrendChart extends StatelessWidget {
  const AttendanceTrendChart({
    super.key,
    required this.meetingHistory,
    this.onMeetingTap,
  });

  final List<MeetingAttendanceItem> meetingHistory;
  final ValueChanged<MeetingAttendanceItem>? onMeetingTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (meetingHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'لا توجد اجتماعات كافية لعرض رسم بياني لتطور الحضور',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00236F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF00236F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'تطور الحضور عبر الاجتماعات',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _legendDot(const Color(0xFF10B981), 'حضور مبكر'),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF1E3A8A), 'حضور عادي'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in meetingHistory)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: onMeetingTap != null ? () => onMeetingTap!(item) : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${item.attendanceRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: item.attendanceRate >= 70
                                    ? const Color(0xFF10B981)
                                    : (item.attendanceRate >= 50
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxHeight = constraints.maxHeight;
                                  final totalRate = (item.attendanceRate / 100.0).clamp(0.0, 1.0);
                                  final barHeight = maxHeight * totalRate;

                                  final earlyFraction = item.presentCount == 0
                                      ? 0.0
                                      : (item.earlyCount + item.beforeCount) / item.presentCount;
                                  final normalFraction = 1.0 - earlyFraction;

                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 28,
                                      height: barHeight < 6 ? 6 : barHeight,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFF1F5F9),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              flex: (normalFraction * 100).toInt(),
                                              child: Container(
                                                color: const Color(0xFF1E3A8A),
                                              ),
                                            ),
                                            Expanded(
                                              flex: (earlyFraction * 100).toInt(),
                                              child: Container(
                                                color: const Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _shortDate(item.meetingDate),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _shortDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        return '${parts[2]}/${parts[1]}';
      }
    } catch (_) {}
    return dateStr;
  }
}

