import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/report_filter.dart';
import '../report_providers.dart';

class ReportFilterBar extends ConsumerWidget {
  const ReportFilterBar({
    super.key,
    required this.serviceId,
    required this.stages,
    required this.classes,
    this.forceExpanded = false,
  });

  final String serviceId;
  final List<dynamic> stages;
  final List<dynamic> classes;
  final bool forceExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(reportFilterProvider);
    final filterNotifier = ref.read(reportFilterProvider.notifier);
    final scopeAsync = ref.watch(reportUserScopeProvider(serviceId));
    final scope = scopeAsync.value;

    final formatter = DateFormat('yyyy/MM/dd');

    // Filter available stages/classes by scope
    final availableStages = stages.where((s) {
      if (scope == null || scope.isServiceWide) return true;
      return scope.accessibleStageIds?.contains(s.id) ?? false;
    }).toList();

    final availableClasses = classes.where((c) {
      if (scope == null || scope.isServiceWide) {
        if (filter.stageId != null) return c.stageId == filter.stageId;
        return true;
      }
      if (filter.stageId != null && c.stageId != filter.stageId) return false;
      return scope.accessibleClassIds?.contains(c.id) ?? false;
    }).toList();

    final expandedContent = Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          // Period Selector Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 640;

                final buttons = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _periodButton(
                      context: context,
                      label: 'اجتماع الجمعة الماضي',
                      preset: ReportPeriodPreset.lastMeeting,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.lastMeeting),
                    ),
                    _periodButton(
                      context: context,
                      label: 'الشهر الحالي',
                      preset: ReportPeriodPreset.currentMonth,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.currentMonth),
                    ),
                    _periodButton(
                      context: context,
                      label: 'الترم الحالي',
                      preset: ReportPeriodPreset.currentTerm,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.currentTerm),
                    ),
                    _periodButton(
                      context: context,
                      label: 'السنة الخدمية',
                      preset: ReportPeriodPreset.serviceYear,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.serviceYear),
                    ),
                    _periodButton(
                      context: context,
                      label: 'فترة مخصصة',
                      icon: Icons.calendar_month_rounded,
                      preset: ReportPeriodPreset.custom,
                      currentPreset: filter.preset,
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: DateTimeRange(
                            start: filter.start,
                            end: filter.end,
                          ),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          filterNotifier.setCustomRange(
                            picked.start,
                            picked.end,
                          );
                        }
                      },
                    ),
                  ],
                );

                final dateIndicator = ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth < 640
                        ? constraints.maxWidth
                        : 360,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'الفترة: ${formatter.format(filter.start)} – ${formatter.format(filter.end)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buttons,
                      const SizedBox(height: 10),
                      dateIndicator,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: buttons),
                    const SizedBox(width: 12),
                    dateIndicator,
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Multi-Criteria Dropdown Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'تصفية:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                // Stage filter (only for overall roles or if multiple stages available)
                if (scope == null ||
                    scope.isServiceWide ||
                    availableStages.length > 1) ...[
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filter.stageId,
                      isDense: true,
                      isExpanded: true,
                      decoration: _dropdownDecoration(context, 'المرحلة'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('جميع المراحل', style: TextStyle(fontSize: 12)),
                        ),
                        for (final s in availableStages)
                          DropdownMenuItem(
                            value: s.id as String,
                            child: Text(
                              s.name as String,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                      onChanged: (val) => filterNotifier.setStage(val),
                    ),
                  ),
                ],
                // Class filter
                if (availableClasses.isNotEmpty) ...[
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filter.classId,
                      isDense: true,
                      isExpanded: true,
                      decoration: _dropdownDecoration(context, 'الفصل (الأسرة)'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('جميع الفصول المتاحة', style: TextStyle(fontSize: 12)),
                        ),
                        for (final c in availableClasses)
                          DropdownMenuItem(
                            value: c.id as String,
                            child: Text(
                              c.name as String,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                      onChanged: (val) => filterNotifier.setClass(val),
                    ),
                  ),
                ],
                // Compare with previous toggle
                InkWell(
                  onTap: () =>
                      filterNotifier.toggleComparison(!filter.compareWithPrevious),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: filter.compareWithPrevious,
                          onChanged: (v) =>
                              filterNotifier.toggleComparison(v ?? true),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'مقارنة بالفترة السابقة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Reset button
                TextButton.icon(
                  onPressed: () => filterNotifier.reset(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'إعادة ضبط',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (forceExpanded) return expandedContent;

    final periodLabel = switch (filter.preset) {
      ReportPeriodPreset.lastMeeting => 'اجتماع الجمعة الماضي',
      ReportPeriodPreset.currentMonth => 'الشهر الحالي',
      ReportPeriodPreset.currentTerm => 'الترم الحالي',
      ReportPeriodPreset.serviceYear => 'السنة الخدمية',
      ReportPeriodPreset.custom => 'فترة مخصصة',
    };
    final activeLabels = <String>[
      periodLabel,
      if (filter.stageId != null)
        _optionName(availableStages, filter.stageId!, 'مرحلة محددة'),
      if (filter.classId != null)
        _optionName(availableClasses, filter.classId!, 'فصل محدد'),
      if (filter.compareWithPrevious) 'مقارنة بالفترة السابقة',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) return expandedContent;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_alt_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الفلاتر النشطة',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (sheetContext) => SafeArea(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'تصفية التقارير',
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'إغلاق',
                                      onPressed: () => Navigator.pop(sheetContext),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ],
                                ),
                                ReportFilterBar(
                                  serviceId: serviceId,
                                  stages: stages,
                                  classes: classes,
                                  forceExpanded: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('تصفية'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final label in activeLabels)
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 15),
                      label: Text(label),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _periodButton({
    required BuildContext context,
    required String label,
    required ReportPeriodPreset preset,
    required ReportPeriodPreset currentPreset,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final isSelected = preset == currentPreset;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _optionName(List<dynamic> options, String id, String fallback) {
    for (final option in options) {
      if (option.id == id) return option.name as String;
    }
    return fallback;
  }

  InputDecoration _dropdownDecoration(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: scheme.outlineVariant,
        ),
      ),
    );
  }
}

