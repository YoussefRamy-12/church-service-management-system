import 'package:flutter/material.dart';

import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import '../../../domain/prep_date_formatter.dart';
import '../../../domain/preparation_status.dart';

class PreparationFilterBar extends StatelessWidget {
  const PreparationFilterBar({
    super.key,
    required this.stages,
    required this.selectedStage,
    required this.onStageChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.weeks,
    required this.selectedWeek,
    required this.onWeekChanged,
  });

  final List<Stage> stages;
  final Stage? selectedStage;
  final ValueChanged<Stage?> onStageChanged;
  final PreparationStatus? selectedStatus;
  final ValueChanged<PreparationStatus?> onStatusChanged;
  final List<DateTime> weeks;
  final DateTime? selectedWeek;
  final ValueChanged<DateTime?> onWeekChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1.1,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Stage dropdown
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<Stage?>(
              initialValue: selectedStage,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'المرحلة',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<Stage?>(
                  value: null,
                  child: Text('كل المراحل'),
                ),
                for (final stage in stages)
                  DropdownMenuItem<Stage?>(
                    value: stage,
                    child: Text(stage.name),
                  ),
              ],
              onChanged: onStageChanged,
            ),
          ),

          // Week dropdown
          SizedBox(
            width: 230,
            child: DropdownButtonFormField<DateTime?>(
              initialValue: selectedWeek,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'الأسبوع',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<DateTime?>(
                  value: null,
                  child: Text('جميع الأسابيع'),
                ),
                for (final w in weeks)
                  DropdownMenuItem<DateTime?>(
                    value: w,
                    child: Text(
                      PrepDateFormatter.formatWeek(w),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onWeekChanged,
            ),
          ),

          // Status filter
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<PreparationStatus?>(
              initialValue: selectedStatus,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'حالة التحضير',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<PreparationStatus?>(
                  value: null,
                  child: Text('جميع الحالات'),
                ),
                for (final status in PreparationStatus.values)
                  DropdownMenuItem<PreparationStatus?>(
                    value: status,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.icon, size: 14, color: status.color),
                        const SizedBox(width: 6),
                        Text(status.labelArabic),
                      ],
                    ),
                  ),
              ],
              onChanged: onStatusChanged,
            ),
          ),
        ],
      ),
    );
  }
}
