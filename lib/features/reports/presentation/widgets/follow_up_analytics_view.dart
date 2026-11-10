import 'package:flutter/material.dart';
import '../../domain/analytics_models.dart';

class FollowUpAnalyticsView extends StatelessWidget {
  const FollowUpAnalyticsView({
    super.key,
    required this.analytics,
    required this.legacyFollowUpsCount,
  });

  final FollowUpAnalytics? analytics;
  final int legacyFollowUpsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalCases = analytics?.totalCases ?? 0;
    final completionRate = analytics?.completionRate ?? 100.0;
    final openCases = analytics?.openCases ?? 0;
    final inProgressCases = analytics?.inProgressCases ?? 0;
    final resolvedCases = (analytics?.resolvedCases ?? 0) + (analytics?.closedCases ?? 0);
    final urgentCases = analytics?.urgentOrHighPriorityCases ?? 0;
    final totalActivities = analytics?.totalActivities ?? legacyFollowUpsCount;

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
                  color: const Color(0xFF904D00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mark_chat_read_rounded,
                  color: Color(0xFF904D00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'مؤشرات الأداء الرعوي والافتفاد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Ring and High level metrics
          Row(
            children: [
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (completionRate / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor:
                          const Color(0xFF10B981).withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF10B981),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${completionRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نسبة إنجاز حالات الافتقاد',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تم حسم $resolvedCases من إجمالي $totalCases حالة متابعة مسجلة، بالإضافة إلى $totalActivities نشاط افتقادي منفذ.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 4 Grid status cards
          Row(
            children: [
              _statusBox('حالات معلقة', '$openCases', const Color(0xFFEF4444), isDark),
              const SizedBox(width: 10),
              _statusBox('قيد المتابعة', '$inProgressCases', const Color(0xFFF59E0B), isDark),
              const SizedBox(width: 10),
              _statusBox('حالات محسومة', '$resolvedCases', const Color(0xFF10B981), isDark),
              const SizedBox(width: 10),
              _statusBox('حالات عاجلة', '$urgentCases', const Color(0xFFDC2626), isDark),
            ],
          ),
          if (analytics != null && analytics!.activityTypeCounts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'توزيع الأنشطة الافتقادية المنفذة:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: analytics!.activityTypeCounts.entries.map((e) {
                final label = switch (e.key) {
                  'call' => 'مكالمات هاتفية',
                  'visit' => 'زيارات منزلية',
                  'message' => 'رسائل',
                  'in_person' => 'لقاءات شخصية',
                  'note' => 'ملاحظات',
                  _ => e.key,
                };
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF182234) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '$label: ${e.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBox(String title, String count, Color color, bool isDark) {
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
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
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

