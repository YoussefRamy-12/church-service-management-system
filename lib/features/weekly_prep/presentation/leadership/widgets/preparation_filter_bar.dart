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
    required this.counts,
  });

  final List<Stage> stages;
  final Stage? selectedStage;
  final ValueChanged<Stage?> onStageChanged;
  final PreparationStatus? selectedStatus;
  final ValueChanged<PreparationStatus?> onStatusChanged;
  final List<DateTime> weeks;
  final DateTime? selectedWeek;
  final ValueChanged<DateTime?> onWeekChanged;
  final Map<PreparationStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final weekIndex = selectedWeek == null
        ? -1
        : weeks.indexWhere((week) => _sameDay(week, selectedWeek!));
    final selectedLabel = selectedWeek == null
        ? 'جميع الأسابيع'
        : PrepDateFormatter.formatWeek(selectedWeek!);
    final statuses = <(PreparationStatus?, String, int)>[
      (
        PreparationStatus.submitted,
        'بانتظار المراجعة',
        counts[PreparationStatus.submitted] ?? 0,
      ),
      (
        PreparationStatus.notSubmitted,
        'لم يسلم',
        counts[PreparationStatus.notSubmitted] ?? 0,
      ),
      (
        PreparationStatus.approved,
        'معتمد',
        counts[PreparationStatus.approved] ?? 0,
      ),
      (null, 'الكل', counts.values.fold<int>(0, (a, b) => a + b)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'الأسبوع التالي',
              onPressed: weekIndex == -1 && weeks.isNotEmpty
                  ? () => onWeekChanged(weeks.first)
                  : weekIndex > 0
                  ? () => onWeekChanged(weeks[weekIndex - 1])
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            Expanded(
              child: Text(
                selectedLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'الأسبوع السابق',
              onPressed: weekIndex >= 0 && weekIndex + 1 < weeks.length
                  ? () => onWeekChanged(weeks[weekIndex + 1])
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            OutlinedButton.icon(
              onPressed: () => _openFilterSheet(context),
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              label: const Text('تصفية'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            for (final option in statuses)
              ChoiceChip(
                label: Text('${option.$2} (${option.$3})'),
                selected: selectedStatus == option.$1,
                onSelected: (_) => onStatusChanged(option.$1),
              ),
          ],
        ),
        if (selectedStage != null || selectedWeek != null) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              if (selectedStage != null)
                InputChip(
                  label: Text(selectedStage!.name),
                  onDeleted: () => onStageChanged(null),
                ),
              if (selectedWeek != null)
                InputChip(
                  label: Text(selectedLabel),
                  onDeleted: () => onWeekChanged(null),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    var stage = selectedStage;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تصفية التحضيرات',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Stage?>(
                initialValue: stage,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'المرحلة'),
                items: [
                  const DropdownMenuItem<Stage?>(
                    value: null,
                    child: Text('كل المراحل'),
                  ),
                  for (final item in stages)
                    DropdownMenuItem<Stage?>(
                      value: item,
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setSheetState(() => stage = value),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  onStageChanged(stage);
                  Navigator.pop(sheetContext);
                },
                child: const Text('تطبيق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
