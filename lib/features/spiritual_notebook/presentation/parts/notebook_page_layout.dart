// ignore_for_file: invalid_use_of_protected_member
part of '../spiritual_notebook_page.dart';

extension _SpiritualNotebookPageLayout on _SpiritualNotebookPageState {
  Widget _buildWeekSummary({
    required WeeklyPeriod period,
    required bool isCurrentWeek,
    required int registeredCount,
    required int totalStudents,
    required int weekTotalPoints,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: 'الأسبوع السابق',
                child: IconButton(
                  tooltip: 'الأسبوع السابق',
                  onPressed: () => setState(() => _weekOffset -= 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                  constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'الأسبوع المحدد: ${period.label}${isCurrentWeek ? '، الحالي' : ''}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(period.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                      if (isCurrentWeek) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(99)),
                          child: Text('الحالي', style: TextStyle(color: scheme.onSecondaryContainer, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'الأسبوع القادم',
                child: IconButton(
                  tooltip: 'الأسبوع القادم',
                  onPressed: () => setState(() => _weekOffset += 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                  constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'المزيد من الخيارات',
                onSelected: (value) {
                  if (value == 'refresh') refresh();
                  if (value == 'points') setState(() => _showWeeklyPoints = !_showWeeklyPoints);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'refresh', child: Text('تحديث')),
                  PopupMenuItem(value: 'points', child: Text(_showWeeklyPoints ? 'إخفاء إحصائيات الأسبوع' : 'عرض إحصائيات الأسبوع')),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 2, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('تم تسجيل $registeredCount من $totalStudents', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: totalStudents == 0 ? 0 : (registeredCount / totalStudents).clamp(0, 1),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(99),
                ),
                if (_showWeeklyPoints)
                  Padding(padding: const EdgeInsetsDirectional.only(top: 4), child: Text('نقاط الأسبوع: $weekTotalPoints', style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar({required bool isMobile, required int totalStudents, required bool canConfigure}) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(isMobile ? 12 : 20, 4, isMobile ? 12 : 20, 4),
      child: Row(children: [
        Expanded(child: _TabButton(label: 'الدفاتر', icon: Icons.menu_book_rounded, selected: tab == 0, onTap: () => setState(() => tab = 0))),
        const SizedBox(width: 6),
        Expanded(child: _TabButton(label: 'لوحة الشرف', icon: Icons.workspace_premium_rounded, selected: tab == 1, onTap: () => setState(() => tab = 1))),
        if (canConfigure) ...[
          const SizedBox(width: 6),
          Expanded(child: _TabButton(label: 'الإعدادات', icon: Icons.tune_rounded, selected: tab == 2, onTap: () => setState(() => tab = 2))),
        ],
      ]),
    );
  }
}
