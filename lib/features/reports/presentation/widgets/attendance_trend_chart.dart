import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/design/app_colors.dart';
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

    if (meetingHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'لا توجد اجتماعات كافية لعرض رسم بياني لتطور الحضور',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'تطور الحضور عبر الاجتماعات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _legendItem(AppColors.of(context).present.foreground, Icons.schedule_rounded, 'حضور مبكر'),
                  _legendItem(theme.colorScheme.primary, Icons.check_circle_outline_rounded, 'حضور عادي'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = math.max(
                constraints.maxWidth,
                meetingHistory.length * 58.0,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
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
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: item.attendanceRate >= 70
                                    ? AppColors.of(context).present.foreground
                                    : (item.attendanceRate >= 50
                                        ? AppColors.of(context).pending.foreground
                                        : AppColors.of(context).absent.foreground),
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
                                        color: theme.colorScheme.surfaceContainerHighest,
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
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            Expanded(
                                              flex: (earlyFraction * 100).toInt(),
                                              child: Container(
                                                color: AppColors.of(context).present.foreground,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

