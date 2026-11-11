import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/ui/app_ui.dart';
import '../../../auth/domain/entities/servant_profile.dart';
import '../../../service/domain/entities/stage.dart';
import '../../domain/prep_date_formatter.dart';
import '../../domain/preparation_status.dart';
import '../../domain/weekly_lesson.dart';
import '../../domain/weekly_preparation.dart';
import '../servant/widgets/preparation_status_badge.dart';
import '../weekly_prep_providers.dart';
import 'widgets/lesson_files_manager_sheet.dart';
import 'widgets/preparation_filter_bar.dart';
import 'widgets/preparation_metrics_row.dart';
import 'widgets/preparation_review_dialog.dart';

class LeadershipPrepDashboard extends ConsumerStatefulWidget {
  const LeadershipPrepDashboard({
    super.key,
    required this.serviceId,
    required this.currentLeader,
    required this.stages,
    required this.weeks,
    required this.lessons,
    required this.onRefresh,
    this.refreshing = false,
  });

  final String serviceId;
  final ServantProfile currentLeader;
  final List<Stage> stages;
  final List<DateTime> weeks;
  final List<WeeklyLesson> lessons;
  final Future<void> Function() onRefresh;
  final bool refreshing;

  @override
  ConsumerState<LeadershipPrepDashboard> createState() =>
      _LeadershipPrepDashboardState();
}

class _LeadershipPrepDashboardState
    extends ConsumerState<LeadershipPrepDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  Stage? _selectedStage;
  DateTime? _selectedWeek;
  PreparationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Default to the current week if available
    final normalizedMonday = PrepDateFormatter.normalizeToMondayUtc(
      DateTime.now(),
    );
    _selectedWeek = widget.weeks.any((w) => _sameDay(w, normalizedMonday))
        ? normalizedMonday
        : (widget.weeks.isNotEmpty ? widget.weeks.first : null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openFilesManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LessonFilesManagerSheet(
        serviceId: widget.serviceId,
        stages: widget.stages,
        weeks: widget.weeks,
        lessons: widget.lessons,
      ),
    );
  }

  void _openReviewDialog(WeeklyPreparation prep) {
    showDialog<void>(
      context: context,
      builder: (ctx) => PreparationReviewDialog(
        preparation: prep,
        currentLeader: widget.currentLeader,
        onReviewed: () {
          ref.invalidate(dashboardPreparationsProvider);
          ref.invalidate(dashboardStatusCountsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = DashboardFilter(
      serviceId: widget.serviceId,
      stageId: _selectedStage?.id,
      weekStart: _selectedWeek,
      statusFilter: _selectedStatus,
    );

    final countsAsync = ref.watch(dashboardStatusCountsProvider(filter));
    final prepsAsync = ref.watch(dashboardPreparationsProvider(filter));

    final counts =
        countsAsync.value ??
        const {
          PreparationStatus.notSubmitted: 0,
          PreparationStatus.submitted: 0,
          PreparationStatus.approved: 0,
          PreparationStatus.needsRevision: 0,
        };

    final pendingCount = counts[PreparationStatus.submitted] ?? 0;

    return Scaffold(
      body: AppContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveHeaderRow(
              title: 'متابعة التحضيرات الأسبوعية',
              subtitle: 'لوحة قيادة مراجعة واعتماد تحضير الدروس للخدام',
              action: Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _openFilesManager,
                    icon: const Icon(Icons.folder_shared_rounded, size: 18),
                    label: const Text('إدارة ملفات الدروس'),
                  ),
                  IconButton(
                    onPressed: widget.refreshing ? null : widget.onRefresh,
                    tooltip: 'تحديث',
                    icon: widget.refreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Metrics row
            PreparationMetricsRow(counts: counts),

            const SizedBox(height: 14),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'سجل التحضير الكامل'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('بانتظار المراجعة'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Filter bar
            PreparationFilterBar(
              stages: widget.stages,
              selectedStage: _selectedStage,
              onStageChanged: (stage) => setState(() => _selectedStage = stage),
              selectedStatus: _selectedStatus,
              onStatusChanged: (status) =>
                  setState(() => _selectedStatus = status),
              weeks: widget.weeks,
              selectedWeek: _selectedWeek,
              onWeekChanged: (week) => setState(() => _selectedWeek = week),
            ),

            const SizedBox(height: 14),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: All preparations with filters
                  _buildPreparationsList(prepsAsync, onlyPending: false),

                  // Tab 2: Pending review queue only
                  _buildPreparationsList(prepsAsync, onlyPending: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparationsList(
    AsyncValue<List<WeeklyPreparation>> prepsAsync, {
    required bool onlyPending,
  }) {
    return prepsAsync.when(
      loading: () => const LoadingView(message: 'جاري تحميل سجل التحضيرات...'),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل التحضيرات',
        message: '$error',
        action: OutlinedButton.icon(
          onPressed: () => ref.invalidate(dashboardPreparationsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      ),
      data: (allPreps) {
        final list = onlyPending
            ? allPreps
                  .where((p) => p.status == PreparationStatus.submitted)
                  .toList()
            : allPreps;

        if (list.isEmpty) {
          return EmptyState(
            icon: onlyPending
                ? Icons.check_circle_outline_rounded
                : Icons.menu_book_outlined,
            title: onlyPending
                ? 'لا توجد تحضيرات بانتظار المراجعة'
                : 'لا توجد سجلات مطابقة',
            message: onlyPending
                ? 'تمت مراجعة واعتماد جميع التحضيرات المسلمة.'
                : 'حاول تغيير معايير البحث أو اختيار أسبوع آخر.',
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final prep = list[index];
            final isSelf = prep.servantProfileId == widget.currentLeader.id;
            final isPending = prep.status == PreparationStatus.submitted;

            final submittedDateStr = prep.submittedAt != null
                ? PrepDateFormatter.formatShortDateTime(prep.submittedAt)
                : null;

            return SolidCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 620;

                  final actionWidget =
                      prep.status != PreparationStatus.notSubmitted
                      ? FilledButton.tonal(
                          style: isPending
                              ? FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF3C7),
                                  foregroundColor: const Color(0xFFB45309),
                                )
                              : null,
                          onPressed: () => _openReviewDialog(prep),
                          child: Text(
                            isPending
                                ? (isSelf ? 'تفاصيل تحضيرك' : 'مراجعة واعتماد')
                                : 'عرض المراجعة',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            'لم يسلم',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: prep.status.backgroundColor,
                              radius: 18,
                              child: Icon(
                                prep.status.icon,
                                color: prep.status.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          prep.servantName ?? 'خادم غير محدد',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelf) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            'أنت',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${prep.stageName ?? 'المرحلة'} • ${prep.className ?? 'الفصل'}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PreparationStatusBadge(status: prep.status),
                          ],
                        ),
                        if (submittedDateStr != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'تاريخ الإرسال: $submittedDateStr',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: actionWidget,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: prep.status.backgroundColor,
                        child: Icon(
                          prep.status.icon,
                          color: prep.status.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    prep.servantName ?? 'خادم غير محدد',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelf) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'أنت',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${prep.stageName ?? 'المرحلة'} • ${prep.className ?? 'الفصل'}${submittedDateStr != null ? ' • تاريخ الإرسال: $submittedDateStr' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      PreparationStatusBadge(status: prep.status),
                      const SizedBox(width: 10),
                      actionWidget,
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
