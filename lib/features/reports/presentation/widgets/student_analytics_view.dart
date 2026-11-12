import 'package:flutter/material.dart';
import '../../domain/analytics_models.dart';

class StudentAnalyticsView extends StatelessWidget {
  const StudentAnalyticsView({
    super.key,
    required this.analytics,
    required this.totalStudents,
  });

  final StudentAnalytics? analytics;
  final int totalStudents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeCount = analytics?.activeStudents ?? totalStudents;
    final pendingCount = analytics?.pendingStudents ?? 0;
    final tiers = analytics?.attendanceTiers ??
        {'90-100%': 0, '75-89%': 0, '50-74%': 0, '<50%': 0};

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
                  color: const Color(0xFF00236F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF00236F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'توزيع انتظام التلاميذ ونمو المخدومين',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Student status cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التلاميذ المعتمدون والنشطون',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE932C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تلاميذ قيد الاعتماد',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'شرائح انتظام الحضور خلال الفترة:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          // 4 Tiers
          Row(
            children: [
              _tierItem(
                label: 'التزام كامل (٩٠-١٠٠٪)',
                count: tiers['90-100%'] ?? 0,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _tierItem(
                label: 'التزام جيد (٧٥-٨٩٪)',
                count: tiers['75-89%'] ?? 0,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _tierItem(
                label: 'متوسط (٥٠-٧٤٪)',
                count: tiers['50-74%'] ?? 0,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _tierItem(
                label: 'يحتاج افتقاد (<٥٠٪)',
                count: tiers['<50%'] ?? 0,
                color: const Color(0xFFEF4444),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tierItem({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

