import 'package:flutter/material.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    final total = expectedAttendance > 0 ? expectedAttendance : 1;
    final beforePct = (beforeCount * 100.0) / total;
    final earlyPct = (earlyCount * 100.0) / total;
    final normalPct = (normalCount * 100.0) / total;
    final absentPct = (absentCount * 100.0) / total;

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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timelapse_rounded,
                  color: Color(0xFF10B981),
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
                        color: const Color(0xFF047857),
                        alignment: Alignment.center,
                      ),
                    ),
                  if (earlyCount > 0)
                    Expanded(
                      flex: (earlyPct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: const Color(0xFF10B981),
                        alignment: Alignment.center,
                      ),
                    ),
                  if (normalCount > 0)
                    Expanded(
                      flex: (normalPct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: const Color(0xFF1E3A8A),
                        alignment: Alignment.center,
                      ),
                    ),
                  if (absentCount > 0)
                    Expanded(
                      flex: (absentPct * 10).toInt().clamp(1, 1000),
                      child: Container(
                        color: const Color(0xFFEF4444),
                        alignment: Alignment.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // 4 Stats indicators
          Row(
            children: [
              _statItem(
                label: 'قبل الموعد',
                count: beforeCount,
                pct: beforePct,
                color: const Color(0xFF047857),
                isDark: isDark,
              ),
              _statItem(
                label: 'مبكر',
                count: earlyCount,
                pct: earlyPct,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              _statItem(
                label: 'عادي',
                count: normalCount,
                pct: normalPct,
                color: const Color(0xFF1E3A8A),
                isDark: isDark,
              ),
              _statItem(
                label: 'غياب',
                count: absentCount,
                pct: absentPct,
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required int count,
    required double pct,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
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
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
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
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

