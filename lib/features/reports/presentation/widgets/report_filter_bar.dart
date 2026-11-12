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
  });

  final String serviceId;
  final List<dynamic> stages;
  final List<dynamic> classes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
                      label: 'اجتماع الجمعة الماضي',
                      preset: ReportPeriodPreset.lastMeeting,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.lastMeeting),
                    ),
                    _periodButton(
                      label: 'الشهر الحالي',
                      preset: ReportPeriodPreset.currentMonth,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.currentMonth),
                    ),
                    _periodButton(
                      label: 'الترم الحالي',
                      preset: ReportPeriodPreset.currentTerm,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.currentTerm),
                    ),
                    _periodButton(
                      label: 'السنة الخدمية',
                      preset: ReportPeriodPreset.serviceYear,
                      currentPreset: filter.preset,
                      onTap: () =>
                          filterNotifier.setPreset(ReportPeriodPreset.serviceYear),
                    ),
                    _periodButton(
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

                final dateIndicator = Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_available_rounded,
                        size: 16,
                        color: Color(0xFF00236F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الفترة: ${formatter.format(filter.start)} – ${formatter.format(filter.end)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ],
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
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                      decoration: _dropdownDecoration('المرحلة', isDark),
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
                      decoration: _dropdownDecoration('الفصل (الأسرة)', isDark),
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
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
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
  }

  Widget _periodButton({
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
              ? const Color(0xFF00236F)
              : const Color(0xFF00236F).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF00236F),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF00236F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 11,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

