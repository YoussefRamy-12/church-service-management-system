import 'package:flutter/material.dart';

import '../../../../../app/design/app_colors.dart';
import '../../../domain/preparation_status.dart';

class PreparationMetricsRow extends StatelessWidget {
  const PreparationMetricsRow({
    super.key,
    required this.counts,
    this.totalServants,
  });

  final Map<PreparationStatus, int> counts;
  final int? totalServants;

  @override
  Widget build(BuildContext context) {
    final pending = counts[PreparationStatus.submitted] ?? 0;
    final total = totalServants ?? counts.values.fold<int>(0, (a, b) => a + b);
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'إجمالي الخدام',
            value: total,
            icon: Icons.people_outline_rounded,
            foreground: colors.accent.foreground,
            background: colors.accent.background,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: 'بانتظار المراجعة',
            value: pending,
            icon: Icons.hourglass_top_rounded,
            foreground: colors.warning.foreground,
            background: colors.warning.background,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            label: 'تم الاعتماد',
            value: counts[PreparationStatus.approved] ?? 0,
            icon: Icons.check_circle_outline_rounded,
            foreground: colors.present.foreground,
            background: colors.present.background,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 5),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
