import 'package:flutter/material.dart';

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
    final approved = counts[PreparationStatus.approved] ?? 0;
    final revision = counts[PreparationStatus.needsRevision] ?? 0;
    final notSubmitted = counts[PreparationStatus.notSubmitted] ?? 0;
    final total =
        totalServants ?? (pending + approved + revision + notSubmitted);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 780;

        final items = [
          _MetricCard(
            label: 'إجمالي الخدام',
            value: total.toString(),
            icon: Icons.people_outline_rounded,
            color: const Color(0xFF6366F1), // indigo
            bgColor: const Color(0xFFEEF2FF),
          ),
          _MetricCard(
            label: 'بانتظار المراجعة',
            value: pending.toString(),
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFF59E0B), // amber
            bgColor: const Color(0xFFFEF3C7),
          ),
          _MetricCard(
            label: 'تم الاعتماد',
            value: approved.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981), // emerald
            bgColor: const Color(0xFFD1FAE5),
          ),
          _MetricCard(
            label: 'يحتاج لتعديل',
            value: revision.toString(),
            icon: Icons.edit_note_rounded,
            color: const Color(0xFFEF4444), // red
            bgColor: const Color(0xFFFEE2E2),
          ),
          _MetricCard(
            label: 'لم يتم الإرسال',
            value: notSubmitted.toString(),
            icon: Icons.cancel_outlined,
            color: const Color(0xFF94A3B8), // slate
            bgColor: const Color(0xFFF1F5F9),
          ),
        ];

        if (isCompact) {
          return SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  SizedBox(width: 140, child: items[index]),
            ),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(child: items[i]),
              if (i < items.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
