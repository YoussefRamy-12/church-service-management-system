import 'package:flutter/material.dart';

import '../../../../app/design/app_colors.dart';

class EarlyRegularDistributionChart extends StatelessWidget {
  const EarlyRegularDistributionChart({
    super.key,
    required this.expectedAttendance,
    required this.beforeCount,
    required this.earlyCount,
    required this.normalCount,
    required this.absentCount,
  });

  final int expectedAttendance;
  final int beforeCount;
  final int earlyCount;
  final int normalCount;
  final int absentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = expectedAttendance > 0 ? expectedAttendance : 1;
    final beforePct = (beforeCount * 100.0) / total;
    final earlyPct = (earlyCount * 100.0) / total;
    final normalPct = (normalCount * 100.0) / total;
    final absentPct = (absentCount * 100.0) / total;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timelapse_rounded,
                  color: AppColors.of(context).present.foreground,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'توزيع الحضور الزمني والغياب',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Multi-segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  if (beforeCount > 0)
                    Expanded(
                      flex: (beforePct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: AppColors.of(context).present.foreground,
                        alignment: Alignment.center,
                      ),
                    ),
                  if (earlyCount > 0)
                    Expanded(
                      flex: (earlyPct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: AppColors.of(context).present.foreground,
                        alignment: Alignment.center,
                      ),
                    ),
                  if (normalCount > 0)
                    Expanded(
                      flex: (normalPct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: theme.colorScheme.primary,
                        alignment: Alignment.center,
                      ),
                    ),
                  if (absentCount > 0)
                    Expanded(
                      flex: (absentPct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: AppColors.of(context).absent.foreground,
                        alignment: Alignment.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // 4 Stats indicators — two columns on narrow screens.
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 768
                  ? (constraints.maxWidth - 36) / 4
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _statItem(
                      context: context,
                      label: 'قبل الموعد',
                      count: beforeCount,
                      pct: beforePct,
                      color: AppColors.of(context).present.foreground,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _statItem(
                      label: 'مبكر',
                      count: earlyCount,
                      pct: earlyPct,
                      color: AppColors.of(context).present.foreground,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _statItem(
                      label: 'عادي',
                      count: normalCount,
                      pct: normalPct,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _statItem(
                      label: 'غياب',
                      count: absentCount,
                      pct: absentPct,
                      color: AppColors.of(context).absent.foreground,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required BuildContext context,
    required String label,
    required int count,
    required double pct,
    required Color color,
  }) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count (${pct.toStringAsFixed(0)}%)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
    );
  }
}

