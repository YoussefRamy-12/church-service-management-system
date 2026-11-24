part of '../spiritual_notebook_page.dart';

extension _SpiritualNotebookPageLayout on _SpiritualNotebookPageState {

  Widget _buildTopHeader(
      BuildContext context, {
      required bool isDark,
      required bool isMobile,
      required WeeklyPeriod period,
      required bool isCurrentWeek,
    }) {
      final theme = Theme.of(context);

      if (isMobile) {
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: isDark ? AppDesignColors.darkSurface : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppDesignColors.darkSurfaceSubtle : AppDesignColors.lightBorderSubtle,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Icon, Title, and Actions
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: appPrimary.withValues(alpha: isDark ? 0.25 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: appPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'النوتة الروحية',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Toggle metrics button on mobile (for student notebooks tab)
                  if (tab == 0)
                    IconButton(
                      icon: Icon(
                        _showMetrics
                            ? Icons.insights_rounded
                            : Icons.insights_outlined,
                        size: 20,
                      ),
                      color: _showMetrics ? appPrimary : AppDesignColors.darkMutedInk,
                      tooltip: _showMetrics
                          ? 'إخفاء الإحصائيات'
                          : 'إظهار الإحصائيات',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          setState(() => _showMetrics = !_showMetrics),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'تحديث',
                    visualDensity: VisualDensity.compact,
                    onPressed: refresh,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Week Selector Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    tooltip: 'الأسبوع السابق',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => setState(() => _weekOffset -= 1),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDesignColors.darkSurfaceSubtle
                          : AppDesignColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? AppDesignColors.darkBorder
                            : AppDesignColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: appPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          period.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: isDark ? Colors.white : appInk,
                          ),
                        ),
                        if (isCurrentWeek) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: appSuccess.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'الحالي',
                              style: TextStyle(
                                color: appSuccess,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    tooltip: 'الأسبوع القادم',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => setState(() => _weekOffset += 1),
                  ),
                  if (!isCurrentWeek)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: () => setState(() => _weekOffset = 0),
                      child: const Text('اليوم', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        );
      }

      // Desktop / Tablet Header
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
        decoration: BoxDecoration(
          color: isDark ? AppDesignColors.darkSurface : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppDesignColors.darkSurfaceSubtle : AppDesignColors.lightBorderSubtle,
              width: 1.2,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: appPrimary.withValues(alpha: isDark ? 0.25 : 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: appPrimary.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: appPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'النوتة الروحية',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'متابعة وتشجيع الحياة الروحية للتلاميذ وتوثيق الأنشطة أسبوعياً',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppDesignColors.darkMutedInk : appMutedInk,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'الأسبوع السابق',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _weekOffset -= 1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDesignColors.darkSurfaceSubtle
                        : AppDesignColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? AppDesignColors.darkBorder
                          : AppDesignColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: appPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        period.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isDark ? Colors.white : appInk,
                        ),
                      ),
                      if (isCurrentWeek) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: appSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'الحالي',
                            style: TextStyle(
                              color: appSuccess,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'الأسبوع القادم',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _weekOffset += 1),
                ),
                if (!isCurrentWeek)
                  TextButton(
                    onPressed: () => setState(() => _weekOffset = 0),
                    child: const Text('اليوم'),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'تحديث البيانات',
                  visualDensity: VisualDensity.compact,
                  onPressed: refresh,
                ),
              ],
            ),
          ],
        ),
      );
    }

  Widget _buildMetricsSection({
      required bool isMobile,
      required int totalStudents,
      required int registeredCount,
      required int pendingCount,
      required int weekTotalPoints,
      required int completionPercentage,
    }) {
      if (isMobile) {
        // Mobile: 2x2 compact grid (takes only ~105px total, eliminates any overflow)
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _CompactMetricTile(
                    label: 'إجمالي التلاميذ',
                    value: '$totalStudents',
                    icon: Icons.groups_rounded,
                    color: appPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactMetricTile(
                    label: 'المسجلون',
                    value: '$registeredCount',
                    icon: Icons.check_circle_rounded,
                    color: appSuccess,
                    badgeText: '$completionPercentage%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _CompactMetricTile(
                    label: 'بانتظار التسجيل',
                    value: '$pendingCount',
                    icon: Icons.pending_actions_rounded,
                    color: appWarning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactMetricTile(
                    label: 'نقاط الأسبوع',
                    value: '$weekTotalPoints',
                    icon: Icons.stars_rounded,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ],
        );
      }

      // Desktop / Tablet: 4 columns in 1 single row
      return Row(
        children: [
          Expanded(
            child: _CompactMetricTile(
              label: 'إجمالي التلاميذ',
              value: '$totalStudents',
              icon: Icons.groups_rounded,
              color: appPrimary,
              badgeText: 'مسجل',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompactMetricTile(
              label: 'المسجلون هذا الأسبوع',
              value: '$registeredCount',
              icon: Icons.check_circle_rounded,
              color: appSuccess,
              badgeText: '$completionPercentage%',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompactMetricTile(
              label: 'بانتظار التسجيل',
              value: '$pendingCount',
              icon: Icons.pending_actions_rounded,
              color: appWarning,
              badgeText: 'متبقي',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompactMetricTile(
              label: 'مجموع نقاط الأسبوع',
              value: '$weekTotalPoints',
              icon: Icons.stars_rounded,
              color: const Color(0xFF0369A1),
              badgeText: 'نقطة',
            ),
          ),
        ],
      );
    }

  Widget _buildTabBar({
      required bool isMobile,
      required int totalStudents,
      required bool canConfigure,
    }) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppDesignColors.darkSurfaceSubtle
                  : AppDesignColors.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: isMobile ? 'الدَّفاتر' : 'دفاتر التلاميذ',
                    count: '$totalStudents',
                    icon: Icons.menu_book_rounded,
                    selected: tab == 0,
                    onTap: () => setState(() => tab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'لوحة الشرف',
                    icon: Icons.workspace_premium_rounded,
                    selected: tab == 1,
                    onTap: () => setState(() => tab = 1),
                  ),
                ),
                if (canConfigure)
                  Expanded(
                    child: _TabButton(
                      label: isMobile ? 'الإعدادات' : 'الإعدادات والأنشطة',
                      icon: Icons.tune_rounded,
                      selected: tab == 2,
                      onTap: () => setState(() => tab = 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }
