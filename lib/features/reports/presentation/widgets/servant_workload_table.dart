import 'package:flutter/material.dart';
import '../../domain/analytics_models.dart';

class ServantWorkloadTable extends StatelessWidget {
  const ServantWorkloadTable({
    super.key,
    required this.servantWorkloads,
  });

  final List<ServantWorkloadMetric> servantWorkloads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (servantWorkloads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('لا توجد بيانات أعباء مسجلة للخدام في هذا النطاق.'),
      );
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
                        Icons.diversity_3_rounded,
                        color: Color(0xFF00236F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'أعباء وأنشطة الخدام الافتقادية',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${servantWorkloads.length} خدام',
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
              columnSpacing: 28,
              columns: const [
                DataColumn(label: Text('اسم الخادم', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('الدور والمسؤولية', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('الفصل', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('حالات الافتقاد المسندة', style: TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text('الأنشطة المنجزة', style: TextStyle(fontWeight: FontWeight.w800))),
              ],
              rows: servantWorkloads.map((sw) {
                final roleLabel = switch (sw.role) {
                  'overall_leader' => 'أمين الخدمة',
                  'overall_helper' => 'مساعد أمين الخدمة',
                  'stage_leader' => 'أمين المرحلة',
                  'class_leader' => 'أمين الفصل',
                  'class_servant' => 'خادم فصل',
                  _ => sw.role,
                };

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        sw.servantName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00236F).withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00236F),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(sw.className ?? 'إشراف عام')),
                    DataCell(
                      Text(
                        '${sw.assignedCasesCount}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${sw.completedActivitiesCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
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

