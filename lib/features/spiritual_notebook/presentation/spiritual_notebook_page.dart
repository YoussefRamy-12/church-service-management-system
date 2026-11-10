import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../app/ui/app_ui.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../data/spiritual_notebook_repository.dart';
import '../domain/weekly_period.dart';

final spiritualNotebookRepositoryProvider = Provider(
  (ref) => SpiritualNotebookRepository(Supabase.instance.client),
);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Color _avatarColor(String name) {
  const palette = <Color>[
    Color(0xFF00236F),
    Color(0xFF0D9488),
    Color(0xFFB45309),
    Color(0xFF475569),
    Color(0xFF0369A1),
    Color(0xFF7C3AED),
    Color(0xFF059669),
  ];
  if (name.isEmpty) return palette.first;
  final code = name.codeUnits.fold<int>(0, (v, u) => v + u);
  return palette[code % palette.length];
}

class SpiritualNotebookPage extends ConsumerStatefulWidget {
  const SpiritualNotebookPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<SpiritualNotebookPage> createState() =>
      _SpiritualNotebookPageState();
}

class _SpiritualNotebookPageState extends ConsumerState<SpiritualNotebookPage> {
  int tab = 0;
  int _weekOffset = 0;
  bool _showMetrics = true;
  late Future<_NotebookData> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  WeeklyPeriod get _selectedPeriod {
    final now = DateTime.now();
    return WeeklyPeriod.offset(now, _weekOffset);
  }

  Future<_NotebookData> _load() async {
    final repo = ref.read(spiritualNotebookRepositoryProvider);
    final results = await Future.wait([
      repo.students(widget.serviceId),
      repo.activities(widget.serviceId),
      repo.submissions(widget.serviceId),
      repo.settings(widget.serviceId),
    ]);
    return _NotebookData(
      results[0] as List<Map<String, dynamic>>,
      results[1] as List<Map<String, dynamic>>,
      results[2] as List<Map<String, dynamic>>,
      results[3] as Map<String, dynamic>?,
    );
  }

  void refresh() {
    if (!mounted) return;
    setState(() {
      data = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentServantProfileProvider).value;
    final isSuper = ref.watch(isSuperAdminProvider);
    final canConfigure =
        isSuper ||
        profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final period = _selectedPeriod;
    final isCurrentWeek = _weekOffset == 0;

    return FutureBuilder<_NotebookData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر تحميل بيانات النوتة الروحية',
                message: '${snap.error}',
                action: FilledButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child: LoadingView(message: 'جاري تحميل سجلات النوتة الروحية...'),
            ),
          );
        }

        final d = snap.data!;
        final weekStartStr = _date(period.start);

        // Calculate weekly metrics
        final currentWeekSubs = d.submissions
            .where((r) => r['period_start'] == weekStartStr)
            .toList();
        final registeredCount = currentWeekSubs.length;
        final totalStudents = d.students.length;
        final pendingCount = (totalStudents - registeredCount).clamp(
          0,
          totalStudents,
        );
        final weekTotalPoints = currentWeekSubs.fold<int>(
          0,
          (sum, r) => sum + (r['total_points'] as int? ?? 0),
        );
        final completionPercentage = totalStudents > 0
            ? ((registeredCount / totalStudents) * 100).round()
            : 0;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;

                return Column(
                  children: [
                    // Top Responsive Header
                    _buildTopHeader(
                      context,
                      isDark: isDark,
                      isMobile: isMobile,
                      period: period,
                      isCurrentWeek: isCurrentWeek,
                    ),

                    // Metrics Grid (shown on student notebooks tab, collapsible)
                    if (_showMetrics && tab == 0)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 12 : 20,
                          isMobile ? 8 : 12,
                          isMobile ? 12 : 20,
                          isMobile ? 6 : 8,
                        ),
                        child: _buildMetricsSection(
                          isMobile: isMobile,
                          totalStudents: totalStudents,
                          registeredCount: registeredCount,
                          pendingCount: pendingCount,
                          weekTotalPoints: weekTotalPoints,
                          completionPercentage: completionPercentage,
                        ),
                      ),

                    // Tab Navigation
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 12 : 20,
                        2,
                        isMobile ? 12 : 20,
                        isMobile ? 6 : 10,
                      ),
                      child: _buildTabBar(
                        isMobile: isMobile,
                        totalStudents: totalStudents,
                        canConfigure: canConfigure,
                      ),
                    ),

                    // Active Tab Content
                    Expanded(
                      child: switch (tab) {
                        0 => _StudentList(
                          students: d.students,
                          submissions: d.submissions,
                          period: period,
                          isMobile: isMobile,
                          onOpen: (s) => context.go(
                            '/service/${widget.serviceId}/spiritual-notebook/student/${s['id']}',
                          ),
                        ),
                        1 => _Leaderboard(
                          students: d.students,
                          submissions: d.submissions,
                          weekStart: weekStartStr,
                          isMobile: isMobile,
                        ),
                        _ => _NotebookSettings(
                          serviceId: widget.serviceId,
                          activities: d.activities,
                          settings: d.settings,
                          isMobile: isMobile,
                          onSaved: refresh,
                        ),
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

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
          color: isDark ? const Color(0xFF131D33) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
                    color: _showMetrics ? appPrimary : const Color(0xFF94A3B8),
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
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
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
        color: isDark ? const Color(0xFF131D33) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
                    color: isDark ? const Color(0xFF94A3B8) : appMutedInk,
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
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
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
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
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

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? appPrimary : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? (isDark ? Colors.white : appPrimary)
                    : (isDark ? const Color(0xFF94A3B8) : appMutedInk),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? (isDark ? Colors.white : appPrimary)
                        : (isDark ? const Color(0xFF94A3B8) : appMutedInk),
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : appPrimary.withValues(alpha: 0.1))
                        : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? (isDark ? Colors.white : appPrimary)
                          : (isDark ? const Color(0xFF94A3B8) : appMutedInk),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.badgeText,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D33) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.25)
              : color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : appMutedInk,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : appInk,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          badgeText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookData {
  const _NotebookData(
    this.students,
    this.activities,
    this.submissions,
    this.settings,
  );
  final List<Map<String, dynamic>> students, activities, submissions;
  final Map<String, dynamic>? settings;
}

class _StudentList extends StatefulWidget {
  const _StudentList({
    required this.students,
    required this.submissions,
    required this.period,
    required this.isMobile,
    required this.onOpen,
  });

  final List<Map<String, dynamic>> students, submissions;
  final WeeklyPeriod period;
  final bool isMobile;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  State<_StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<_StudentList> {
  String query = '';
  int statusFilter = 0; // 0 = all, 1 = registered, 2 = pending
  String? selectedClassId; // null = all classes
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekStartStr = _date(widget.period.start);

    final currentSubs = widget.submissions.where(
      (r) => r['period_start'] == weekStartStr,
    );
    final thisWeekPoints = {
      for (final r in currentSubs) r['student_id']: r['total_points'] as int,
    };

    final totalPointsMap = <String, int>{};
    for (final r in widget.submissions) {
      totalPointsMap.update(
        r['student_id'] as String,
        (v) => v + (r['total_points'] as int),
        ifAbsent: () => r['total_points'] as int,
      );
    }

    // Extract all unique classes and counts
    final classMap = <String, String>{};
    final classCounts = <String, int>{};
    for (final s in widget.students) {
      final cls = s['classes'] as Map<String, dynamic>?;
      final classId =
          s['current_class_id'] as String? ??
          cls?['id'] as String? ??
          'unassigned';
      final className = cls?['name'] as String? ?? 'بدون فصل';
      classMap[classId] = className;
      classCounts[classId] = (classCounts[classId] ?? 0) + 1;
    }
    final sortedClasses = classMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Students filtered by class
    final classScopedStudents = selectedClassId == null
        ? widget.students
        : widget.students.where((s) {
            final cls = s['classes'] as Map<String, dynamic>?;
            final classId =
                s['current_class_id'] as String? ??
                cls?['id'] as String? ??
                'unassigned';
            return classId == selectedClassId;
          }).toList();

    final registeredCount = classScopedStudents
        .where((s) => thisWeekPoints.containsKey(s['id']))
        .length;
    final pendingCount = classScopedStudents.length - registeredCount;

    final filteredStudents = classScopedStudents.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final cls = s['classes'] as Map<String, dynamic>?;
      final className = (cls?['name'] as String? ?? '').toLowerCase();

      final matchesQuery =
          name.contains(query.toLowerCase()) ||
          className.contains(query.toLowerCase());
      if (!matchesQuery) return false;

      final isDone = thisWeekPoints.containsKey(s['id']);
      if (statusFilter == 1 && !isDone) return false;
      if (statusFilter == 2 && isDone) return false;

      return true;
    }).toList();

    return Column(
      children: [
        // Controls Row (Search + Status Chips + Class Filter Buttons)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 12 : 20,
            vertical: 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: AppSearchField(
                  controller: searchController,
                  hintText: 'ابحث باسم التلميذ أو الفصل...',
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              const SizedBox(height: 6),

              // Filter Row 1: Status Chips (الكل، المسجلون، بانتظار التسجيل)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      label: 'الكل',
                      count: classScopedStudents.length,
                      selected: statusFilter == 0,
                      onTap: () => setState(() => statusFilter = 0),
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      label: 'المسجلون',
                      count: registeredCount,
                      color: appSuccess,
                      selected: statusFilter == 1,
                      onTap: () => setState(() => statusFilter = 1),
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      label: 'بانتظار التسجيل',
                      count: pendingCount,
                      color: appWarning,
                      selected: statusFilter == 2,
                      onTap: () => setState(() => statusFilter = 2),
                    ),
                  ],
                ),
              ),

              // Filter Row 2: Ready Class Filter Buttons (فصول الخدمة)
              if (sortedClasses.isNotEmpty) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : appMutedInk,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'الفصل:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : appMutedInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      _classFilterChip(
                        label: 'جميع الفصول',
                        count: widget.students.length,
                        selected: selectedClassId == null,
                        onTap: () => setState(() => selectedClassId = null),
                        isDark: isDark,
                      ),
                      for (final entry in sortedClasses) ...[
                        const SizedBox(width: 6),
                        _classFilterChip(
                          label: entry.value,
                          count: classCounts[entry.key] ?? 0,
                          selected: selectedClassId == entry.key,
                          onTap: () =>
                              setState(() => selectedClassId = entry.key),
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Active Class Filter Notification Banner
              if (selectedClassId != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appPrimary.withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: appPrimary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_rounded,
                        size: 14,
                        color: appPrimary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تصفية حسب: ${classMap[selectedClassId] ?? ''} (${filteredStudents.length} تلميذ)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: appPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => selectedClassId = null),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: appPrimary,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: appPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Students Roster
        Expanded(
          child: filteredStudents.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'لم يتم العثور على تلاميذ',
                            message: query.isNotEmpty
                                ? 'لا يوجد تلميذ يطابق بحثك "$query"'
                                : 'لا توجد سجلات تلاميذ تحت هذا التصنيف في هذا الأسبوع.',
                            action: query.isNotEmpty
                                ? OutlinedButton(
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() => query = '');
                                    },
                                    child: const Text('إعادة ضبط البحث'),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    widget.isMobile ? 12 : 20,
                    6,
                    widget.isMobile ? 12 : 20,
                    24,
                  ),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, i) {
                    final s = filteredStudents[i];
                    final cls = s['classes'] as Map<String, dynamic>?;
                    final stage = cls?['stages'] as Map<String, dynamic>?;
                    final done = thisWeekPoints.containsKey(s['id']);
                    final studentName = s['name'] as String? ?? 'بدون اسم';
                    final weekPts = thisWeekPoints[s['id']] ?? 0;
                    final totalPts = totalPointsMap[s['id']] ?? 0;
                    final avatarBg = _avatarColor(studentName);

                    return SolidCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.zero,
                      borderRadius: 12,
                      child: InkWell(
                        onTap: () => widget.onOpen(s),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isMobile ? 12 : 16,
                            vertical: widget.isMobile ? 10 : 12,
                          ),
                          child: Row(
                            children: [
                              // Avatar with Initial
                              CircleAvatar(
                                radius: widget.isMobile ? 18 : 22,
                                backgroundColor: avatarBg.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                ),
                                foregroundColor: avatarBg,
                                child: Text(
                                  studentName.trim().isNotEmpty
                                      ? studentName.trim().characters.first
                                      : 'ت',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: widget.isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: widget.isMobile ? 10 : 14),

                              // Name & Class
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            studentName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: widget.isMobile
                                                  ? 14
                                                  : 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (done)
                                          GlassBadge(
                                            label: widget.isMobile
                                                ? 'مسجل'
                                                : 'تم التسجيل',
                                            color: appSuccess,
                                            icon: Icons.check_circle_rounded,
                                          )
                                        else
                                          GlassBadge(
                                            label: widget.isMobile
                                                ? 'بانتظار'
                                                : 'بانتظار التسجيل',
                                            color: appWarning,
                                            icon: Icons.access_time_rounded,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${cls?['name'] ?? 'بدون فصل'} • ${stage?['name'] ?? 'بدون مرحلة'}',
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: widget.isMobile ? 11 : 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Weekly & Total Points
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: done
                                          ? appSuccess.withValues(alpha: 0.12)
                                          : (isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      done ? '+$weekPts ن' : '—',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: done
                                            ? appSuccess
                                            : (isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : appMutedInk),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'إجمالي: $totalPts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : appMutedInk,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_left_rounded,
                                color: const Color(0xFF94A3B8),
                                size: widget.isMobile ? 18 : 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = color ?? appPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? activeColor
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? (isDark ? Colors.white : activeColor)
                      : (isDark ? const Color(0xFF94A3B8) : appMutedInk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classFilterChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? appPrimary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? appPrimary
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white : appInk),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : appMutedInk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpiritualNotebookStudentPage extends ConsumerStatefulWidget {
  const SpiritualNotebookStudentPage({
    super.key,
    required this.serviceId,
    required this.studentId,
  });
  final String serviceId, studentId;

  @override
  ConsumerState<SpiritualNotebookStudentPage> createState() =>
      _SpiritualNotebookStudentPageState();
}

class _SpiritualNotebookStudentPageState
    extends ConsumerState<SpiritualNotebookStudentPage> {
  late Future<_StudentFormData> data;
  final selected = <String>{};
  final bonus = TextEditingController();
  final reason = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<_StudentFormData> _load() async {
    final client = Supabase.instance.client;
    final repo = ref.read(spiritualNotebookRepositoryProvider);
    final results = await Future.wait<dynamic>([
      client
          .from('students')
          .select(
            'id,name,current_class_id,classes!students_current_class_id_fkey(name,stages(name))',
          )
          .eq('id', widget.studentId)
          .single(),
      repo.activities(widget.serviceId),
      repo.submissions(widget.serviceId),
      repo.settings(widget.serviceId),
    ]);
    final period = WeeklyPeriod.containing(DateTime.now());
    final existing = (results[2] as List<Map<String, dynamic>>)
        .where(
          (r) =>
              r['student_id'] == widget.studentId &&
              r['period_start'] == _date(period.start),
        )
        .firstOrNull;
    return _StudentFormData(
      results[0] as Map<String, dynamic>,
      results[1] as List<Map<String, dynamic>>,
      existing,
      results[3] as Map<String, dynamic>?,
    );
  }

  @override
  void dispose() {
    bonus.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentServantProfileProvider).value?.role;
    final period = WeeklyPeriod.containing(DateTime.now());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<_StudentFormData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر فتح دفتر التلميذ',
                message: '${snap.error}',
                action: FilledButton(
                  onPressed: () => setState(() => data = _load()),
                  child: const Text('إعادة المحاولة'),
                ),
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child: LoadingView(message: 'جاري فتح دفتر التلميذ...'),
            ),
          );
        }

        final d = snap.data!;
        final cls = d.student['classes'] as Map<String, dynamic>?;
        final stage = cls?['stages'] as Map<String, dynamic>?;
        final existing = d.existing;
        final bonusAllowed =
            (d.settings?['bonus_roles'] as List<dynamic>? ?? []).contains(role);
        final maxBonus = (d.settings?['max_bonus_points'] as int?) ?? 0;
        final b = int.tryParse(bonus.text) ?? 0;
        final selectedPoints = d.activities
            .where((a) => selected.contains(a['id']))
            .fold<int>(0, (sum, a) => sum + (a['points'] as int));
        final grandTotal = selectedPoints + (bonusAllowed ? b : 0);
        final studentName = d.student['name'] as String? ?? 'التلميذ';
        final avatarBg = _avatarColor(studentName);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع',
              onPressed: () => context.pop(),
            ),
            title: const Text('دفتر التلميذ الروحي'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: GlassBadge(
                    label: period.label,
                    color: appPrimary,
                    icon: Icons.calendar_month_rounded,
                    showDot: false,
                  ),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return AppContent(
                maxWidth: 760,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 12,
                ),
                child: ListView(
                  children: [
                    // Student Profile Header Card
                    SolidCard(
                      padding: EdgeInsets.all(isMobile ? 14 : 20),
                      borderRadius: 14,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 24 : 30,
                            backgroundColor: avatarBg.withValues(
                              alpha: isDark ? 0.25 : 0.12,
                            ),
                            foregroundColor: avatarBg,
                            child: Text(
                              studentName.trim().isNotEmpty
                                  ? studentName.trim().characters.first
                                  : 'ت',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isMobile ? 20 : 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: isMobile ? 16 : 18,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cls?['name'] ?? 'بدون فصل'} • ${stage?['name'] ?? 'بدون مرحلة'}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (existing != null)
                            const GlassBadge(
                              label: 'معتمد',
                              color: appSuccess,
                              icon: Icons.check_circle_rounded,
                            )
                          else
                            const GlassBadge(
                              label: 'بانتظار التسجيل',
                              color: appWarning,
                              icon: Icons.access_time_rounded,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (existing != null) ...[
                      const StatusBanner(
                        icon: Icons.lock_rounded,
                        tone: StatusTone.success,
                        title: 'تم اعتماد النوتة الروحية لهذا الأسبوع',
                        message:
                            'تم رصد واعتماد درجات التلميذ لهذا الأسبوع بنجاح. لا يمكن تعديل السجل بعد الاعتماد.',
                      ),
                      const SizedBox(height: 14),
                      SolidCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ملخص درجات الأسبوع المسجلة',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: appSuccess.withValues(
                                        alpha: isDark ? 0.15 : 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: appSuccess.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'إجمالي النقاط المعتمدة',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: appSuccess,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${existing['total_points']} نقطة',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: appSuccess,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if ((existing['bonus_points'] as int? ?? 0) >
                                    0) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: appPrimary.withValues(
                                          alpha: isDark ? 0.15 : 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: appPrimary.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'نقاط تشجيعية',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: appPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+${existing['bonus_points']} ن',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: appPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (existing['submitted_at'] != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'تاريخ ووقت الحفظ: ${existing['submitted_at']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      ModernSectionHeader(
                        title: 'الأنشطة الروحية',
                        subtitle:
                            'حدد الأنشطة التي التزم بها التلميذ هذا الأسبوع',
                        badge: GlassBadge(
                          label: '$selectedPoints نقطة',
                          color: appPrimary,
                          showDot: false,
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (d.activities.isEmpty)
                        const SolidCard(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'لا توجد أنشطة روحية مفعلة حالياً في النظام.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                      for (final a in d.activities) ...[
                        Builder(
                          builder: (context) {
                            final isChecked = selected.contains(a['id']);
                            return SolidCard(
                              margin: const EdgeInsets.only(bottom: 8),
                              borderRadius: 12,
                              padding: EdgeInsets.zero,
                              color: isChecked
                                  ? appPrimary.withValues(
                                      alpha: isDark ? 0.12 : 0.05,
                                    )
                                  : null,
                              border: isChecked
                                  ? Border.all(color: appPrimary, width: 1.5)
                                  : null,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      selected.remove(a['id'] as String);
                                    } else {
                                      selected.add(a['id'] as String);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              selected.add(a['id'] as String);
                                            } else {
                                              selected.remove(
                                                a['id'] as String,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a['name'] as String,
                                              style: TextStyle(
                                                fontWeight: isChecked
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (a['description'] != null &&
                                                (a['description'] as String)
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 1),
                                              Text(
                                                a['description'].toString(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? appPrimary
                                              : appPrimary.withValues(
                                                  alpha: 0.08,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '+${a['points']} ن',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: isChecked
                                                ? Colors.white
                                                : appPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      if (bonusAllowed) ...[
                        const SizedBox(height: 14),
                        SolidCard(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ModernSectionHeader(
                                title: 'نقاط تشجيعية إضافية',
                                subtitle:
                                    'يمكنك إضافة نقاط إضافية مع ذكر السبب',
                              ),
                              const SizedBox(height: 10),
                              if (isMobile) ...[
                                TextField(
                                  controller: bonus,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'النقاط (أقصى $maxBonus)',
                                    prefixIcon: const Icon(
                                      Icons.star_outline_rounded,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: reason,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'سبب الإضافة (مطلوب إذا وضعت نقاط)',
                                    prefixIcon: Icon(Icons.comment_outlined),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: TextField(
                                        controller: bonus,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'النقاط (أقصى $maxBonus)',
                                          prefixIcon: const Icon(
                                            Icons.star_outline_rounded,
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: reason,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'سبب الإضافة (مطلوب إذا وضعت نقاط)',
                                          prefixIcon: Icon(
                                            Icons.comment_outlined,
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Bottom Action Summary Card (Responsive for thumb reach)
                      SolidCard(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(16),
                        color: isDark ? const Color(0xFF1E293B) : appSoftBlue,
                        border: Border.all(
                          color: appPrimary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'مجموع نقاط الأسبوع:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: appMutedInk,
                                        ),
                                      ),
                                      Text(
                                        '$grandTotal نقطة',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                          color: appPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: appPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: saving ? null : _submitRecord,
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                    ),
                                    label: Text(
                                      saving
                                          ? 'جارٍ الاعتماد...'
                                          : 'اعتماد وحفظ السجل',
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'مجموع نقاط الأسبوع',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: appMutedInk,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$grandTotal نقطة',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 24,
                                            color: appPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: appPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: saving ? null : _submitRecord,
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                    ),
                                    label: Text(
                                      saving
                                          ? 'جارٍ الاعتماد...'
                                          : 'اعتماد وحفظ السجل',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submitRecord() async {
    final d = (await data);
    final period = WeeklyPeriod.containing(DateTime.now());
    final role = ref.read(currentServantProfileProvider).value?.role;
    final bonusAllowed = (d.settings?['bonus_roles'] as List<dynamic>? ?? [])
        .contains(role);
    final maxBonus = (d.settings?['max_bonus_points'] as int?) ?? 0;
    final b = int.tryParse(bonus.text) ?? 0;
    final studentName = d.student['name'] as String? ?? 'التلميذ';
    final selectedPoints = d.activities
        .where((a) => selected.contains(a['id']))
        .fold<int>(0, (sum, a) => sum + (a['points'] as int));
    final grandTotal = selectedPoints + (bonusAllowed ? b : 0);

    if (selected.isEmpty && (d.settings?['allow_zero_submissions'] != true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر نشاطاً واحداً على الأقل للتلميذ')),
      );
      return;
    }

    if (b < 0 || b > maxBonus || (b > 0 && reason.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تحقق من قيمة النقاط الإضافية وسبب إضافتها'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: appPrimary),
            SizedBox(width: 8),
            Text('تأكيد اعتماد النوتة الروحية'),
          ],
        ),
        content: Text(
          'هل تود اعتماد $grandTotal نقطة للتلميذ «$studentName» لهذا الأسبوع (${period.label})؟\n\nتنبيه: بعد الاعتماد لا يمكن تعديل السجل.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('مراجعة'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('تأكيد واعتماد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => saving = true);

    try {
      await ref
          .read(spiritualNotebookRepositoryProvider)
          .submit(
            studentId: widget.studentId,
            period: period,
            activityIds: selected.toList(),
            bonusPoints: bonusAllowed ? b : 0,
            bonusReason: reason.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم اعتماد النوتة الروحية للتلميذ بنجاح'),
            backgroundColor: appSuccess,
          ),
        );
        setState(() {
          data = _load();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الحفظ: $e'), backgroundColor: appError),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _StudentFormData {
  const _StudentFormData(
    this.student,
    this.activities,
    this.existing,
    this.settings,
  );
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? existing, settings;
}

class _Leaderboard extends StatefulWidget {
  const _Leaderboard({
    required this.students,
    required this.submissions,
    required this.weekStart,
    required this.isMobile,
  });

  final List<Map<String, dynamic>> students, submissions;
  final String weekStart;
  final bool isMobile;

  @override
  State<_Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<_Leaderboard> {
  String? selectedClassId; // null = all classes
  bool get isMobile => widget.isMobile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract all unique classes and counts for Leaderboard
    final classMap = <String, String>{};
    final classCounts = <String, int>{};
    for (final s in widget.students) {
      final cls = s['classes'] as Map<String, dynamic>?;
      final classId =
          s['current_class_id'] as String? ??
          cls?['id'] as String? ??
          'unassigned';
      final className = cls?['name'] as String? ?? 'بدون فصل';
      classMap[classId] = className;
      classCounts[classId] = (classCounts[classId] ?? 0) + 1;
    }
    final sortedClasses = classMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub Tabs (Weekly vs All-Time)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 12 : 24,
              vertical: 4,
            ),
            child: const TabBar(
              indicatorColor: appPrimary,
              labelColor: appPrimary,
              unselectedLabelColor: appMutedInk,
              tabs: [
                Tab(
                  icon: Icon(Icons.calendar_today_rounded, size: 16),
                  text: 'شرف الأسبوع',
                ),
                Tab(
                  icon: Icon(Icons.emoji_events_rounded, size: 16),
                  text: 'الترتيب العام',
                ),
              ],
            ),
          ),

          // Ready Class Filter Buttons for Leaderboard
          if (sortedClasses.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12 : 24,
                vertical: 4,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : appMutedInk,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'الفصل:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : appMutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _classFilterPill(
                      label: 'جميع الفصول',
                      count: widget.students.length,
                      selected: selectedClassId == null,
                      onTap: () => setState(() => selectedClassId = null),
                      isDark: isDark,
                    ),
                    for (final entry in sortedClasses) ...[
                      const SizedBox(width: 6),
                      _classFilterPill(
                        label: entry.value,
                        count: classCounts[entry.key] ?? 0,
                        selected: selectedClassId == entry.key,
                        onTap: () =>
                            setState(() => selectedClassId = entry.key),
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),

          Expanded(
            child: TabBarView(
              children: [
                _buildLeaderboardView(
                  context,
                  weekly: true,
                  classMap: classMap,
                ),
                _buildLeaderboardView(
                  context,
                  weekly: false,
                  classMap: classMap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _classFilterPill({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? appPrimary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? appPrimary
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white : appInk),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : (isDark ? const Color(0xFF94A3B8) : appMutedInk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardView(
    BuildContext context, {
    required bool weekly,
    required Map<String, String> classMap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scores = <String, int>{};
    for (final r in widget.submissions) {
      if (!weekly || r['period_start'] == widget.weekStart) {
        scores.update(
          r['student_id'] as String,
          (v) => v + (r['total_points'] as int),
          ifAbsent: () => r['total_points'] as int,
        );
      }
    }

    // Filter students by selected class if set
    final classScopedStudents = selectedClassId == null
        ? widget.students
        : widget.students.where((s) {
            final cls = s['classes'] as Map<String, dynamic>?;
            final classId =
                s['current_class_id'] as String? ??
                cls?['id'] as String? ??
                'unassigned';
            return classId == selectedClassId;
          }).toList();

    final scoredStudents =
        classScopedStudents
            .where(
              (s) => scores.containsKey(s['id']) && (scores[s['id']] ?? 0) > 0,
            )
            .toList()
          ..sort(
            (a, b) => (scores[b['id']] ?? 0).compareTo(scores[a['id']] ?? 0),
          );

    if (scoredStudents.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: EmptyState(
                  icon: Icons.workspace_premium_outlined,
                  title: weekly
                      ? (selectedClassId != null
                            ? 'لا توجد درجات لهذا الفصل هذا الأسبوع'
                            : 'لا توجد درجات مسجلة لهذا الأسبوع')
                      : (selectedClassId != null
                            ? 'لا توجد بيانات شرف لهذا الفصل بعد'
                            : 'لا توجد بيانات شرف بعد'),
                  message: weekly
                      ? 'قم برصد دفاتر التلاميذ لتظهر أسماء المتفوقين في لوحة الشرف.'
                      : 'ابدأ برصد درجات النوتة الروحية للتلاميذ ليتم حساب الترتيب.',
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        widget.isMobile ? 12 : 20,
        10,
        widget.isMobile ? 12 : 20,
        24,
      ),
      children: [
        // Active class indicator
        if (selectedClassId != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: appPrimary.withValues(alpha: isDark ? 0.20 : 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appPrimary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded, size: 14, color: appPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'لوحة شرف فصل: ${classMap[selectedClassId] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: appPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => selectedClassId = null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: appPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Podium for Top 3
        _buildPodium(context, scoredStudents, scores, isDark),
        const SizedBox(height: 14),

        ModernSectionHeader(
          title: selectedClassId != null
              ? 'متفوقو ${classMap[selectedClassId] ?? 'الفصل'}'
              : 'قائمة المتفوقين',
          subtitle: 'ترتيب التلاميذ بحسب مجموع النقاط',
          badge: GlassBadge(
            label: '${scoredStudents.length} تلميذ',
            color: appPrimary,
            showDot: false,
          ),
        ),
        const SizedBox(height: 6),

        for (int i = 0; i < scoredStudents.length; i++) ...[
          _buildRankItem(
            context,
            student: scoredStudents[i],
            rank: i + 1,
            score: scores[scoredStudents[i]['id']] ?? 0,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildPodium(
    BuildContext context,
    List<Map<String, dynamic>> sorted,
    Map<String, int> scores,
    bool isDark,
  ) {
    if (sorted.isEmpty) return const SizedBox.shrink();

    final first = sorted.isNotEmpty ? sorted[0] : null;
    final second = sorted.length > 1 ? sorted[1] : null;
    final third = sorted.length > 2 ? sorted[2] : null;

    final h1 = isMobile ? 85.0 : 130.0;
    final h2 = isMobile ? 68.0 : 105.0;
    final h3 = isMobile ? 55.0 : 90.0;

    return SolidCard(
      borderRadius: 14,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 16,
        vertical: isMobile ? 12 : 16,
      ),
      color: isDark ? const Color(0xFF131D33) : Colors.white,
      border: Border.all(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        width: 1.2,
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'منصة التكريم والتميز',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Rank 2: Silver
              if (second != null)
                Expanded(
                  child: _podiumColumn(
                    name: second['name'] as String? ?? '',
                    score: scores[second['id']] ?? 0,
                    rank: 2,
                    rankLabel: 'المركز الثاني',
                    accentColor: const Color(0xFF64748B),
                    icon: Icons.military_tech_rounded,
                    height: h2,
                    isDark: isDark,
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),

              // Rank 1: Gold (Center & Taller)
              if (first != null)
                Expanded(
                  child: _podiumColumn(
                    name: first['name'] as String? ?? '',
                    score: scores[first['id']] ?? 0,
                    rank: 1,
                    rankLabel: 'المركز الأول',
                    accentColor: const Color(0xFFD97706),
                    icon: Icons.workspace_premium_rounded,
                    height: h1,
                    isDark: isDark,
                    isWinner: true,
                  ),
                ),

              // Rank 3: Bronze
              if (third != null)
                Expanded(
                  child: _podiumColumn(
                    name: third['name'] as String? ?? '',
                    score: scores[third['id']] ?? 0,
                    rank: 3,
                    rankLabel: 'المركز الثالث',
                    accentColor: const Color(0xFFB45309),
                    icon: Icons.military_tech_rounded,
                    height: h3,
                    isDark: isDark,
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumColumn({
    required String name,
    required int score,
    required int rank,
    required String rankLabel,
    required Color accentColor,
    required IconData icon,
    required double height,
    required bool isDark,
    bool isWinner = false,
  }) {
    final badgeSize = isMobile
        ? (isWinner ? 38.0 : 32.0)
        : (isWinner ? 48.0 : 40.0);
    final iconSize = isMobile
        ? (isWinner ? 20.0 : 17.0)
        : (isWinner ? 26.0 : 22.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: accentColor, size: iconSize),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isWinner ? FontWeight.w800 : FontWeight.w700,
            fontSize: isMobile ? 11 : (isWinner ? 14 : 13),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '$score ن',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: accentColor,
            fontSize: isMobile ? 12 : (isWinner ? 15 : 13),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.20 : 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile
                      ? (isWinner ? 18 : 14)
                      : (isWinner ? 24 : 18),
                  color: accentColor,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(height: 2),
                Text(
                  rankLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : appMutedInk,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankItem(
    BuildContext context, {
    required Map<String, dynamic> student,
    required int rank,
    required int score,
    required bool isDark,
  }) {
    final cls = student['classes'] as Map<String, dynamic>?;
    final stage = cls?['stages'] as Map<String, dynamic>?;
    final studentName = student['name'] as String? ?? 'بدون اسم';

    final (Color badgeColor, IconData rankIcon) = switch (rank) {
      1 => (const Color(0xFFD97706), Icons.workspace_premium_rounded),
      2 => (const Color(0xFF64748B), Icons.military_tech_rounded),
      3 => (const Color(0xFFB45309), Icons.military_tech_rounded),
      _ => (appPrimary, Icons.numbers_rounded),
    };

    return SolidCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 10,
      ),
      borderRadius: 10,
      child: Row(
        children: [
          Container(
            width: isMobile ? 28 : 32,
            height: isMobile ? 28 : 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isDark ? 0.20 : 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: rank <= 3
                ? Icon(rankIcon, size: isMobile ? 16 : 18, color: badgeColor)
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      fontSize: isMobile ? 11 : 13,
                    ),
                  ),
          ),
          SizedBox(width: isMobile ? 10 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
                Text(
                  '${cls?['name'] ?? 'بدون فصل'} • ${stage?['name'] ?? 'بدون مرحلة'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appPrimary.withValues(alpha: isDark ? 0.20 : 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: appPrimary.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$score ن',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: appPrimary,
                fontSize: isMobile ? 12 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookSettings extends ConsumerStatefulWidget {
  const _NotebookSettings({
    required this.serviceId,
    required this.activities,
    required this.settings,
    required this.isMobile,
    required this.onSaved,
  });

  final String serviceId;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? settings;
  final bool isMobile;
  final VoidCallback onSaved;

  @override
  ConsumerState<_NotebookSettings> createState() => _NotebookSettingsState();
}

class _NotebookSettingsState extends ConsumerState<_NotebookSettings> {
  late final TextEditingController nameController;
  late final TextEditingController pointsController;
  late final TextEditingController maxBonusController;
  late final Set<String> roles;
  bool isAddingActivity = false;
  bool isSavingBonusSettings = false;

  static const availableRoles = [
    'overall_leader',
    'overall_helper',
    'stage_leader',
    'class_leader',
    'class_servant',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    pointsController = TextEditingController();
    maxBonusController = TextEditingController(
      text: '${widget.settings?['max_bonus_points'] ?? 0}',
    );
    roles = (widget.settings?['bonus_roles'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
  }

  @override
  void dispose() {
    nameController.dispose();
    pointsController.dispose();
    maxBonusController.dispose();
    super.dispose();
  }

  String _roleLabel(String r) => switch (r) {
    'overall_leader' => 'مسؤول الخدمة',
    'overall_helper' => 'مساعد مسؤول الخدمة',
    'stage_leader' => 'مسؤول المرحلة',
    'class_leader' => 'أمين الفصل',
    _ => 'خادم الفصل',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppContent(
      maxWidth: 820,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 24,
        vertical: 10,
      ),
      child: ListView(
        children: [
          // Section 1: Activities Management
          SolidCard(
            borderRadius: 14,
            padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernSectionHeader(
                  title: 'الأنشطة الروحية المفعلة',
                  subtitle: 'قائمة الأنشطة المتاحة للتسجيل أسبوعياً',
                  badge: GlassBadge(
                    label: '${widget.activities.length} نشاط',
                    color: appPrimary,
                    showDot: false,
                  ),
                ),
                const SizedBox(height: 12),

                if (widget.activities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'لم تتم إضافة أنشطة روحية بعد. أضف نشاطاً جديداً بالأسفل.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  for (final a in widget.activities) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: appSuccess,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (a['description'] != null &&
                                    (a['description'] as String).isNotEmpty)
                                  Text(
                                    a['description'].toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: appPrimary.withValues(
                                alpha: isDark ? 0.20 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${a['points']} ن',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: appPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: appPrimary,
                            tooltip: 'تعديل',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _showEditActivityDialog(a),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            color: appError,
                            tooltip: 'حذف',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _showDeleteActivityDialog(a),
                          ),
                        ],
                      ),
                    ),
                  ],

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                const Text(
                  'إضافة نشاط روحي جديد',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),

                if (widget.isMobile) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم النشاط (مثلاً: قراءة الإنجيل)',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'النقاط',
                            prefixIcon: Icon(Icons.stars_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: appPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: isAddingActivity ? null : _addActivity,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(isAddingActivity ? 'جاري...' : 'إضافة'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم النشاط (مثلاً: صلاة باكر)',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'النقاط',
                            prefixIcon: Icon(Icons.stars_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: appPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        onPressed: isAddingActivity ? null : _addActivity,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(isAddingActivity ? 'جاري...' : 'إضافة'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Bonus Rules & Permissions
          SolidCard(
            borderRadius: 14,
            padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernSectionHeader(
                  title: 'قواعد النقاط الإضافية والمكافآت',
                  subtitle:
                      'حدد سقف النقاط الإضافية والأدوار المصرح لها بمنحها',
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: widget.isMobile ? 150 : 200,
                      child: TextField(
                        controller: maxBonusController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الحد الأقصى',
                          prefixIcon: Icon(Icons.star_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: appPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSavingBonusSettings
                          ? null
                          : _saveBonusSettings,
                      child: Text(
                        isSavingBonusSettings ? 'حفظ...' : 'حفظ السقف',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'الأدوار المسموح لها بمنح نقاط إضافية:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: availableRoles.map((r) {
                    final isChecked = roles.contains(r);
                    return FilterChip(
                      selected: isChecked,
                      selectedColor: appPrimary.withValues(
                        alpha: isDark ? 0.25 : 0.12,
                      ),
                      label: Text(
                        _roleLabel(r),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onSelected: (v) async {
                        setState(() {
                          if (v) {
                            roles.add(r);
                          } else {
                            roles.remove(r);
                          }
                        });
                        await _saveBonusSettings();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: appPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تعديل القواعد ينطبق على التسجيلات القادمة مع الحفاظ الكامل على درجات الأسابيع السابقة.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addActivity() async {
    final p = int.tryParse(pointsController.text);
    if (nameController.text.trim().isEmpty || p == null || p < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم النشاط وعدد نقاط صالح (0 أو أكثر)'),
        ),
      );
      return;
    }

    setState(() => isAddingActivity = true);
    try {
      await ref
          .read(spiritualNotebookRepositoryProvider)
          .addActivity(widget.serviceId, nameController.text.trim(), p);
      nameController.clear();
      pointsController.clear();
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة النشاط الروحي بنجاح'),
            backgroundColor: appSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إضافة النشاط: $e'),
            backgroundColor: appError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAddingActivity = false);
    }
  }

  Future<void> _saveBonusSettings() async {
    final value = int.tryParse(maxBonusController.text);
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل حداً صحيحاً للنقاط الإضافية')),
      );
      return;
    }

    setState(() => isSavingBonusSettings = true);
    try {
      await ref
          .read(spiritualNotebookRepositoryProvider)
          .upsertSettings(
            widget.serviceId,
            maxBonus: value,
            bonusRoles: roles.toList(),
          );
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ إعدادات النقاط الإضافية بنجاح'),
            backgroundColor: appSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ الإعدادات: $e'),
            backgroundColor: appError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSavingBonusSettings = false);
    }
  }

  Future<void> _showEditActivityDialog(Map<String, dynamic> activity) async {
    final editName = TextEditingController(
      text: activity['name'] as String? ?? '',
    );
    final editPoints = TextEditingController(
      text: '${activity['points'] ?? 0}',
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: appPrimary),
              SizedBox(width: 8),
              Text(
                'تعديل النشاط الروحي',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: editName,
                    decoration: const InputDecoration(
                      labelText: 'اسم النشاط الروحي',
                      prefixIcon: Icon(Icons.bookmark_outline_rounded),
                    ),
                    autofocus: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم النشاط';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: editPoints,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'النقاط',
                      prefixIcon: Icon(Icons.stars_rounded),
                    ),
                    validator: (v) {
                      final p = int.tryParse(v ?? '');
                      if (p == null || p < 0) {
                        return 'يرجى إدخال عدد نقاط صحيح (0 أو أكثر)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: appPrimary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ملاحظة: تعديل النقاط ينطبق على الأسابيع والتسجيلات القادمة، مع بقاء درجات الأسابيع السابقة المسجلة كما هي.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final p = int.parse(editPoints.text.trim());
      try {
        await ref
            .read(spiritualNotebookRepositoryProvider)
            .updateActivity(
              activityId: activity['id'] as String,
              name: editName.text.trim(),
              points: p,
            );
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث النشاط الروحي بنجاح'),
              backgroundColor: appSuccess,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر تعديل النشاط: $e'),
              backgroundColor: appError,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteActivityDialog(Map<String, dynamic> activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: appError),
              SizedBox(width: 8),
              Text(
                'حذف النشاط الروحي',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل أنت متأكد من حذف النشاط «${activity['name']}»؟',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: appSuccess.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: appSuccess.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: appSuccess,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'حفظ الدرجات السابقة:\nسيتم حذف النشاط من قائمة الأنشطة المتاحة للتسجيل في الأسابيع القادمة، مع الاحتفاظ الكامل بجميع درجات وسجلات الأسابيع السابقة.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF0F5132),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: appError,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تأكيد الحذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(spiritualNotebookRepositoryProvider)
            .deleteActivity(activity['id'] as String);
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم حذف النشاط بنجاح مع الحفاظ على درجات الأسابيع السابقة',
              ),
              backgroundColor: appSuccess,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر حذف النشاط: $e'),
              backgroundColor: appError,
            ),
          );
        }
      }
    }
  }
}
