import 'package:flutter/material.dart';

class ReportKpiCard extends StatelessWidget {
  const ReportKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.changePercentage,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double? changePercentage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget? trendWidget;
    if (changePercentage != null) {
      final isPositive = changePercentage! > 0;
      final isZero = changePercentage! == 0;
      final trendColor = isZero
          ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
          : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444));
      final trendIcon = isZero
          ? Icons.remove_rounded
          : (isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded);
      final sign = isPositive ? '+' : '';

      trendWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: trendColor.withValues(alpha: isDark ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(trendIcon, size: 14, color: trendColor),
            const SizedBox(width: 4),
            Text(
              '$sign${changePercentage!.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: trendColor,
              ),
            ),
          ],
        ),
      );
    }

    final cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0x080F172A),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              ?trendWidget,
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return cardContent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: cardContent,
    );
  }
}

