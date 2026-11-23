import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ui/app_ui.dart';
import '../domain/entities/case_status.dart';
import 'absence_prioritization_page.dart';
import 'follow_up_case_providers.dart';
import 'pages/create_follow_up_case_page.dart';
import 'pages/follow_up_case_details_page.dart';
import 'pages/student_follow_up_profile_page.dart';
import 'weekly_follow_up_page.dart';
import 'widgets/follow_up_activity_card.dart';
import 'widgets/follow_up_case_card.dart';
import 'widgets/follow_up_student_card.dart';

enum _StudentFilter { all, mostAbsent, needsFollowUp, previouslyFollowedUp }

enum _StudentSort { mostAbsences, alphabetical, latestFollowUp }

class FollowUpHubPage extends ConsumerStatefulWidget {
  const FollowUpHubPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<FollowUpHubPage> createState() => _FollowUpHubPageState();
}

class _FollowUpHubPageState extends ConsumerState<FollowUpHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Student Tab State
  String _studentQuery = '';
  _StudentFilter _studentFilter = _StudentFilter.all;
  _StudentSort _studentSort = _StudentSort.mostAbsences;

  // Cases Tab State
  String _caseQuery = '';
  CaseStatus? _caseStatusFilter; // null = all

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المتابعة والرعاية'),
        actions: [
          IconButton(
            key: const Key('follow_up_weekly'),
            tooltip: 'متابعات الأسبوع',
            icon: const Icon(Icons.calendar_view_week_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeeklyFollowUpPage(serviceId: widget.serviceId),
              ),
            ),
          ),
          IconButton(
            key: const Key('follow_up_priority'),
            tooltip: 'أولوية الغياب المتتالي',
            icon: const Icon(Icons.priority_high_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AbsencePrioritizationPage(serviceId: widget.serviceId),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              icon: Icon(Icons.school_rounded, size: 18),
              text: 'الطلاب',
            ),
            Tab(
              icon: Icon(Icons.folder_shared_rounded, size: 18),
              text: 'حالات المتابعة',
            ),
            Tab(
              icon: Icon(Icons.history_rounded, size: 18),
              text: 'سجل الأنشطة',
            ),
          ],
        ),
      ),
      body: AmbientBackground(
        intensity: 0.35,
        child: AppContent(
          maxWidth: 960,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudentsTab(theme),
              _buildCasesTab(theme),
              _buildActivityLogTab(theme),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('فتح حالة متابعة'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateFollowUpCasePage(
              serviceId: widget.serviceId,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION A: STUDENTS TAB
  // ===========================================================================

  Widget _buildStudentsTab(ThemeData theme) {
    final studentsAsync =
        ref.watch(followUpStudentItemsProvider(widget.serviceId));

    return studentsAsync.when(
      data: (items) {
        // 1. Filter
        final filtered = items.where((item) {
          if (_studentQuery.isNotEmpty) {
            final q = _studentQuery.toLowerCase();
            final matchesName = item.student.name.toLowerCase().contains(q);
            final matchesClass = item.className.toLowerCase().contains(q);
            if (!matchesName && !matchesClass) return false;
          }

          return switch (_studentFilter) {
            _StudentFilter.all => true,
            _StudentFilter.mostAbsent => item.absenceCount >= 2,
            _StudentFilter.needsFollowUp => item.needsFollowUp,
            _StudentFilter.previouslyFollowedUp => item.wasPreviouslyFollowedUp,
          };
        }).toList();

        // 2. Sort
        switch (_studentSort) {
          case _StudentSort.mostAbsences:
            filtered.sort((a, b) => b.absenceCount.compareTo(a.absenceCount));
          case _StudentSort.alphabetical:
            filtered.sort((a, b) => a.student.name.compareTo(b.student.name));
          case _StudentSort.latestFollowUp:
            filtered.sort((a, b) {
              final dateA = a.latestFollowUpDate ?? '';
              final dateB = b.latestFollowUpDate ?? '';
              return dateB.compareTo(dateA);
            });
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Search Input
            GlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.all(4),
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintText: 'ابحث باسم التلميذ أو الفصل...',
                  border: InputBorder.none,
                  suffixIcon: _studentQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _studentQuery = ''),
                        ),
                ),
                onChanged: (val) => setState(() => _studentQuery = val.trim()),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips & Sort Controls
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStudentFilterChip('الكل (${items.length})', _StudentFilter.all),
                  const SizedBox(width: 8),
                  _buildStudentFilterChip(
                    'الأكثر غياباً (≥2)',
                    _StudentFilter.mostAbsent,
                  ),
                  const SizedBox(width: 8),
                  _buildStudentFilterChip(
                    'يحتاج متابعة',
                    _StudentFilter.needsFollowUp,
                  ),
                  const SizedBox(width: 8),
                  _buildStudentFilterChip(
                    'تمت متابعتهم',
                    _StudentFilter.previouslyFollowedUp,
                  ),
                  const SizedBox(width: 14),
                  Container(
                    height: 24,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(width: 14),
                  // Sort Dropdown
                  PopupMenuButton<_StudentSort>(
                    tooltip: 'ترتيب حسب',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            switch (_studentSort) {
                              _StudentSort.mostAbsences => 'الأكثر غياباً',
                              _StudentSort.alphabetical => 'أبجدياً',
                              _StudentSort.latestFollowUp => 'أحدث متابعة',
                            },
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (sort) => setState(() => _studentSort = sort),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _StudentSort.mostAbsences,
                        child: Text('الأكثر غياباً'),
                      ),
                      PopupMenuItem(
                        value: _StudentSort.alphabetical,
                        child: Text('أبجدياً (أ - ي)'),
                      ),
                      PopupMenuItem(
                        value: _StudentSort.latestFollowUp,
                        child: Text('أحدث متابعة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.person_search_rounded,
                title: 'لا يوجد طلاب يطابقون البحث أو الفلتر',
                message: 'جرّب تغيير عبارة البحث أو اختيار فلتر آخر.',
              )
            else
              ...filtered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FollowUpStudentCard(
                    item: item,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentFollowUpProfilePage(
                          serviceId: widget.serviceId,
                          studentItem: item,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const LoadingView(message: 'جاري تحميل طلاب النطاق المصرح...'),
      error: (err, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل الطلاب',
        message: '$err',
      ),
    );
  }

  Widget _buildStudentFilterChip(String label, _StudentFilter filter) {
    final isSelected = _studentFilter == filter;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _studentFilter = filter);
      },
    );
  }

  // ===========================================================================
  // SECTION B: FOLLOW-UP CASES TAB
  // ===========================================================================

  Widget _buildCasesTab(ThemeData theme) {
    final casesAsync = ref.watch(followUpCasesInScopeProvider(widget.serviceId));

    return casesAsync.when(
      data: (cases) {
        final filtered = cases.where((c) {
          if (_caseStatusFilter != null && c.status != _caseStatusFilter) {
            return false;
          }
          if (_caseQuery.isNotEmpty) {
            final q = _caseQuery.toLowerCase();
            final matchesTitle = c.title.toLowerCase().contains(q);
            final matchesStudent =
                c.studentName?.toLowerCase().contains(q) ?? false;
            final matchesClass =
                c.className?.toLowerCase().contains(q) ?? false;
            if (!matchesTitle && !matchesStudent && !matchesClass) return false;
          }
          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Search Input
            GlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.all(4),
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  hintText: 'ابحث في الحالات أو اسم التلميذ...',
                  border: InputBorder.none,
                  suffixIcon: _caseQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _caseQuery = ''),
                        ),
                ),
                onChanged: (val) => setState(() => _caseQuery = val.trim()),
              ),
            ),
            const SizedBox(height: 12),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    selected: _caseStatusFilter == null,
                    label: Text('الكل (${cases.length})'),
                    onSelected: (selected) {
                      if (selected) setState(() => _caseStatusFilter = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...CaseStatus.values.map((status) {
                    final count = cases.where((c) => c.status == status).length;
                    final isSelected = _caseStatusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text('${status.arabicLabel} ($count)'),
                        selectedColor: status.color.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? status.color : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _caseStatusFilter = status);
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.folder_off_outlined,
                title: 'لا توجد حالات متابعة تطابق الفلتر',
                message: 'اضغط على الزر أدناه لفتح حالة متابعة جديدة.',
              )
            else
              ...filtered.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FollowUpCaseCard(
                    caseItem: c,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowUpCaseDetailsPage(
                          serviceId: widget.serviceId,
                          caseId: c.id,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const LoadingView(message: 'جاري تحميل حالات المتابعة...'),
      error: (err, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل الحالات',
        message: '$err',
      ),
    );
  }

  // ===========================================================================
  // SECTION C: ACTIVITY LOG TAB
  // ===========================================================================

  Widget _buildActivityLogTab(ThemeData theme) {
    final activitiesAsync =
        ref.watch(followUpActivitiesInScopeProvider(widget.serviceId));

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return const EmptyState(
            icon: Icons.history_toggle_off_rounded,
            title: 'لا توجد أنشطة مسجلة بعد في نطاقك',
            message: 'سجل الأنشطة يعرض تغذية زمنية لجميع الاتصالات والافتقادات مع هوية كل كاتب.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final act = activities[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FollowUpActivityCard(
                activity: act,
                showCaseInfo: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowUpCaseDetailsPage(
                      serviceId: widget.serviceId,
                      caseId: act.caseId,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingView(message: 'جاري تحميل سجل الأنشطة...'),
      error: (err, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل الأنشطة',
        message: '$err',
      ),
    );
  }
}
