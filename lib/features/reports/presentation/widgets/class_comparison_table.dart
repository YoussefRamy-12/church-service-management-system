import 'package:flutter/material.dart';
import '../../domain/analytics_models.dart';

class ClassComparisonTable extends StatelessWidget {
  const ClassComparisonTable({
    super.key,
    required this.classComparisons,
    this.onClassTap,
  });

  final List<ClassComparisonMetric> classComparisons;
  final ValueChanged<ClassComparisonMetric>? onClassTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (classComparisons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
                        color: const Color(0xFF00236F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        color: Color(0xFF00236F),
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
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF182234) : const Color(0xFFF8FAFC),
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
                    ? const Color(0xFF10B981)
                    : (rate >= 50
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444));

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
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
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
                                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${c.repeatedAbsencesCount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            )
                          : const Text('0', style: TextStyle(color: Color(0xFF10B981))),
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
          ),
        ],
      ),
    );
  }
}

