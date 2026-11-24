import 'package:flutter/material.dart';

import '../../../../app/design/app_colors.dart';
import '../../domain/analytics_models.dart';

class ClassComparisonTable extends StatelessWidget {
  const ClassComparisonTable({
    super.key,
    required this.classComparisons,
    this.onClassTap,
  });

  final List<ClassComparisonMetric> classComparisons;
  final ValueChanged<ClassComparisonMetric>? onClassTap;

  Widget _buildMobileCard(
    BuildContext context,
    ClassComparisonMetric item,
  ) {
    final theme = Theme.of(context);
    final rateColor = item.attendanceRate >= 75
        ? AppColors.of(context).present.foreground
        : item.attendanceRate >= 50
            ? AppColors.of(context).pending.foreground
            : AppColors.of(context).absent.foreground;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: InkWell(
        onTap: onClassTap == null ? null : () => onClassTap!(item),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.className, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                item.stageName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metric(context, 'التلاميذ', '${item.totalStudents}'),
                  _metric(
                    context,
                    'الحضور',
                    '${item.presentCount} / ${item.expectedAttendance}',
                  ),
                  _metric(
                    context,
                    'نسبة الحضور',
                    '${item.attendanceRate.toStringAsFixed(1)}%',
                    valueColor: rateColor,
                  ),
                  _metric(
                    context,
                    'حضور مبكر',
                    '${item.earlyRate.toStringAsFixed(0)}%',
                  ),
                  _metric(
                    context,
                    'غياب متكرر',
                    '${item.repeatedAbsencesCount}',
                    valueColor: item.repeatedAbsencesCount > 0
                        ? AppColors.of(context).absent.foreground
                        : AppColors.of(context).present.foreground,
                  ),
                  _metric(
                    context,
                    'إنجاز الافتقاد',
                    '${item.followUpCompletionRate.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (classComparisons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'مقارنة الحضور والالتزام بين فصول الخدمة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${classComparisons.length} فصول',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 768) {
                return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerLow,
              ),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 56,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('الفصل والمرحلة', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('التلاميذ', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('الحضور الفعلي', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('نسبة الحضور', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('حضور مبكر', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('غياب متكرر', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('إنجاز الافتقاد', style: TextStyle(fontWeight: FontWeight.w800))),
              ],
              rows: classComparisons.map((c) {
                final rate = c.attendanceRate;
                final rateColor = rate >= 75
                    ? AppColors.of(context).present.foreground
                    : (rate >= 50
                        ? AppColors.of(context).pending.foreground
                        : AppColors.of(context).absent.foreground);

                return DataRow(
                  onSelectChanged: onClassTap != null ? (_) => onClassTap!(c) : null,
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c.className,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            c.stageName,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text('${c.totalStudents}', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${c.presentCount} / ${c.expectedAttendance}')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: rateColor.withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${rate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: rateColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text('${c.earlyRate.toStringAsFixed(0)}%')),
                    DataCell(
                      c.repeatedAbsencesCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).absent.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${c.repeatedAbsencesCount}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.of(context).absent.foreground,
                                ),
                              ),
                            )
                          : Text('0', style: TextStyle(color: AppColors.of(context).present.foreground)),
                    ),
                    DataCell(
                      Text(
                        '${c.followUpCompletionRate.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
              }
              return Column(
                children: [
                  for (final item in classComparisons)
                    _buildMobileCard(context, item),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

