import 'package:flutter/material.dart';
import '../../../../app/design/app_colors.dart';
import '../../domain/analytics_models.dart';

class ServantWorkloadTable extends StatelessWidget {
  const ServantWorkloadTable({
    super.key,
    required this.servantWorkloads,
  });

  final List<ServantWorkloadMetric> servantWorkloads;

  Widget _buildMobileCard(
    BuildContext context,
    ServantWorkloadMetric item,
  ) {
    final theme = Theme.of(context);
    final roleLabel = switch (item.role) {
      'overall_leader' => 'أمين الخدمة',
      'overall_helper' => 'مساعد أمين الخدمة',
      'stage_leader' => 'أمين المرحلة',
      'class_leader' => 'أمين الفصل',
      'class_servant' => 'خادم فصل',
      _ => item.role,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
            Text(item.servantName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    Icons.badge_outlined,
                    size: 15,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(roleLabel),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(Icons.groups_outlined, size: 15),
                  label: Text(item.className ?? 'إشراف عام'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _countMetric(context, 'حالات مسندة', item.assignedCasesCount),
                _countMetric(
                  context,
                  'أنشطة منفذة',
                  item.completedActivitiesCount,
                  valueColor: AppColors.of(context).present.foreground,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countMetric(
    BuildContext context,
    String label,
    int value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (servantWorkloads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('لا توجد بيانات أعباء مسجلة للخدام في هذا النطاق.'),
      );
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
                        Icons.diversity_3_rounded,
                        color: theme.colorScheme.primary,
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
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).present.foreground,
                        ),
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
                  for (final item in servantWorkloads)
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

