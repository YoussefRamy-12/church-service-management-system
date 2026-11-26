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
    this.headerAction,
    this.canManageLessons = false,
    this.refreshing = false,
  });

  final String serviceId;
  final ServantProfile currentLeader;
  final List<Stage> stages;
  final List<DateTime> weeks;
  final List<WeeklyLesson> lessons;
  final Future<void> Function() onRefresh;
  final Widget? headerAction;
  final bool canManageLessons;
  final bool refreshing;

  @override
  ConsumerState<LeadershipPrepDashboard> createState() =>
      _LeadershipPrepDashboardState();
}

class _LeadershipPrepDashboardState
    extends ConsumerState<LeadershipPrepDashboard> {
  Stage? _selectedStage;
  DateTime? _selectedWeek;
  PreparationStatus? _selectedStatus = PreparationStatus.submitted;

  @override
  void initState() {
    super.initState();
    // Default to the current week if available
    final normalizedMonday = PrepDateFormatter.normalizeToMondayUtc(
      DateTime.now(),
    );
    _selectedWeek = widget.weeks.any((w) => _sameDay(w, normalizedMonday))
        ? normalizedMonday
        : (widget.weeks.isNotEmpty ? widget.weeks.first : null);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openFilesManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          top: false,
          child: LessonFilesManagerSheet(
            serviceId: widget.serviceId,
            stages: widget.stages,
            weeks: widget.weeks,
            lessons: widget.lessons,
          ),
        ),
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

    return Scaffold(
      body: AppContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.headerAction != null) widget.headerAction!,
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
                  if (widget.canManageLessons)
                    PopupMenuButton<String>(
                      tooltip: 'المزيد',
                      onSelected: (_) => _openFilesManager(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'files',
                          child: Text('إدارة ملفات الدروس'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Metrics row
            PreparationMetricsRow(counts: counts),

            const SizedBox(height: 14),

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
              counts: counts,
            ),

            const SizedBox(height: 6),

            Expanded(child: _buildPreparationsList(prepsAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparationsList(
    AsyncValue<List<WeeklyPreparation>> prepsAsync,
  ) {
    return prepsAsync.when(
      loading: () => ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => SolidCard(
          margin: const EdgeInsetsDirectional.only(bottom: 6),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 130,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 95,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 82,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) {
        debugPrint('Failed to load weekly preparations: $error');
        return EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل التحضيرات',
          message: 'تحقق من الاتصال ثم حاول مرة أخرى.',
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(dashboardPreparationsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        );
      },
      data: (allPreps) {
        final list = allPreps;

        if (list.isEmpty) {
          return EmptyState(
            icon: _selectedStatus == PreparationStatus.submitted
                ? Icons.check_circle_outline_rounded
                : Icons.menu_book_outlined,
            title: _selectedStatus == PreparationStatus.submitted
                ? 'لا توجد تحضيرات بانتظار المراجعة'
                : 'لا توجد سجلات مطابقة',
            message: 'حاول تغيير معايير التصفية أو اختيار أسبوع آخر.',
            action: _selectedStatus != null
                ? TextButton(
                    onPressed: () => setState(() => _selectedStatus = null),
                    child: const Text('عرض الكل'),
                  )
                : null,
          );
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final prep = list[index];
            return SolidCard(
              margin: const EdgeInsetsDirectional.only(bottom: 6),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              child: InkWell(
                onTap: () => _openReviewDialog(prep),
                child: SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Text(
                          (prep.servantName?.trim().isNotEmpty ?? false)
                              ? prep.servantName!.trim().substring(0, 1)
                              : '؟',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prep.servantName ?? 'خادم غير محدد',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${prep.stageName ?? 'المرحلة'} • ${prep.className ?? 'الفصل'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      PreparationStatusBadge(status: prep.status),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
