import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/design/app_colors.dart';
import '../../../../app/ui/app_ui.dart';
import '../../../auth/domain/entities/servant_profile.dart';
import '../../../service/domain/entities/stage.dart';
import '../../domain/prep_date_formatter.dart';
import '../../domain/preparation_status.dart';
import '../../domain/weekly_lesson.dart';
import '../../domain/weekly_preparation.dart';
import '../weekly_prep_providers.dart';
import 'widgets/preparation_history_sheet.dart';
import 'widgets/preparation_status_badge.dart';
import 'widgets/review_feedback_card.dart';

class ServantPrepView extends ConsumerStatefulWidget {
  const ServantPrepView({
    super.key,
    required this.serviceId,
    required this.profile,
    required this.lessons,
    required this.stages,
    this.initialStageId,
    required this.currentWeekMonday,
    required this.onRefresh,
    this.headerAction,
    this.refreshing = false,
  });

  final String serviceId;
  final ServantProfile profile;
  final List<WeeklyLesson> lessons;
  final List<Stage> stages;
  final String? initialStageId;
  final DateTime currentWeekMonday;
  final Future<void> Function() onRefresh;
  final Widget? headerAction;
  final bool refreshing;

  @override
  ConsumerState<ServantPrepView> createState() => _ServantPrepViewState();
}

class _ServantPrepViewState extends ConsumerState<ServantPrepView> {
  DateTime? _selectedWeek;
  String? _selectedStageId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedWeek = PrepDateFormatter.normalizeToMondayUtc(
      widget.currentWeekMonday,
    );
    _selectedStageId =
        widget.initialStageId ??
        widget.profile.stageId ??
        (widget.stages.isNotEmpty ? widget.stages.first.id : null);
  }

  @override
  void didUpdateWidget(covariant ServantPrepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedStageId == null && widget.stages.isNotEmpty) {
      _selectedStageId =
          widget.initialStageId ??
          widget.profile.stageId ??
          widget.stages.first.id;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  WeeklyLesson? _findLessonForWeek(DateTime week) {
    if (_selectedStageId != null) {
      final matches = widget.lessons.where(
        (l) => l.stageId == _selectedStageId && _sameDay(l.weekStart, week),
      );
      if (matches.isNotEmpty) return matches.first;
    }
    final any = widget.lessons.where((l) => _sameDay(l.weekStart, week));
    return any.isNotEmpty ? any.first : null;
  }

  Stage? _stageForId(String? stageId) {
    if (stageId == null) return null;
    for (final s in widget.stages) {
      if (s.id == stageId) return s;
    }
    return null;
  }

  Future<void> _openPdf(WeeklyLesson lesson, {required bool download}) async {
    try {
      final url = await ref
          .read(weeklyLessonRepositoryProvider)
          .signedUrl(lesson, download: download);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('تعذر فتح الرابط');
      }
    } catch (e) {
      debugPrint('Presentation operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              download
                  ? 'تعذر إتمام العملية. حاول مرة أخرى.'
                  : 'تعذر إتمام العملية. حاول مرة أخرى.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit({
    required WeeklyLesson lesson,
    required WeeklyPreparation prep,
  }) async {
    final isResubmission = prep.status == PreparationStatus.needsRevision;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isResubmission ? 'تأكيد إعادة الإرسال' : 'إرسال التحضير للمراجعة',
        ),
        content: Text(
          isResubmission
              ? 'هل قمت بإجراء التعديلات المطلوبة وتريد إرسال التحضير للمراجعة مرة أخرى؟'
              : 'هل انتهيت من تحضير الدرس وتريد إرساله للقائد لاعتماده؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isResubmission ? 'إعادة الإرسال' : 'إرسال للمراجعة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final repo = ref.read(weeklyPreparationRepositoryProvider);
      if (isResubmission) {
        await repo.resubmitPreparation(
          lessonId: lesson.id,
          servantProfileId: widget.profile.id,
        );
      } else {
        await repo.submitPreparation(
          lessonId: lesson.id,
          servantProfileId: widget.profile.id,
        );
      }

      ref.invalidate(
        servantPreparationProvider((
          lessonId: lesson.id,
          servantProfileId: widget.profile.id,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.of(context).present.foreground,
            content: Text(
              isResubmission
                  ? 'تمت إعادة إرسال التحضير للمراجعة بنجاح.'
                  : 'تم إرسال التحضير للمراجعة بنجاح.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Presentation operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إتمام العملية. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showHistorySheet({required WeeklyLesson lesson}) async {
    final reviews = await ref
        .read(weeklyPreparationRepositoryProvider)
        .getReviewHistory(
          lessonId: lesson.id,
          servantProfileId: widget.profile.id,
        );
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: PreparationHistorySheet(
            reviews: reviews,
            lessonFileName: lesson.fileName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWeek = PrepDateFormatter.normalizeToMondayUtc(
      widget.currentWeekMonday,
    );
    final selectedWeek = _selectedWeek ?? currentWeek;
    final isCurrentWeek = _sameDay(selectedWeek, currentWeek);
    final lesson = _findLessonForWeek(selectedWeek);
    final selectedPrep = lesson == null
        ? null
        : ref
              .watch(
                servantPreparationProvider((
                  lessonId: lesson.id,
                  servantProfileId: widget.profile.id,
                )),
              )
              .asData
              ?.value;

    // Build deduplicated list of available weeks: current week + previous weeks with lessons
    final allWeeks = <DateTime>[];
    final weekKeys = <String>{};

    void addWeek(DateTime dt) {
      final monday = PrepDateFormatter.normalizeToMondayUtc(dt);
      final key = '${monday.year}-${monday.month}-${monday.day}';
      if (weekKeys.add(key)) {
        allWeeks.add(monday);
      }
    }

    addWeek(currentWeek);
    final relevantLessons = _selectedStageId != null
        ? widget.lessons.where((l) => l.stageId == _selectedStageId)
        : widget.lessons;
    for (final l in relevantLessons) {
      addWeek(l.weekStart);
    }
    allWeeks.sort((a, b) => b.compareTo(a)); // Newest first

    return Scaffold(
      bottomNavigationBar:
          lesson != null &&
              isCurrentWeek &&
              selectedPrep != null &&
              (selectedPrep.status == PreparationStatus.notSubmitted ||
                  selectedPrep.status == PreparationStatus.needsRevision)
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting
                        ? null
                        : () =>
                              _handleSubmit(lesson: lesson, prep: selectedPrep),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            selectedPrep.status ==
                                    PreparationStatus.needsRevision
                                ? Icons.refresh_rounded
                                : Icons.send_rounded,
                          ),
                    label: Text(
                      selectedPrep.status == PreparationStatus.needsRevision
                          ? 'إعادة الإرسال'
                          : 'إرسال التحضير',
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: AppContent(
        maxWidth: 820,
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
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Keep the stage choice compact when multiple stages are available.
            if (widget.stages.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedStageId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'المرحلة الدراسية',
                  contentPadding: EdgeInsetsDirectional.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  for (final stage in widget.stages)
                    DropdownMenuItem(
                      value: stage.id,
                      child: Text(
                        stage.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) setState(() => _selectedStageId = id);
                },
              ),
              const SizedBox(height: 10),
            ] else if (widget.stages.isNotEmpty) ...[
              Text(
                'المرحلة: ${widget.stages.first.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Week selector bar
            _buildWeekSelector(allWeeks, selectedWeek, currentWeek),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildMainLessonCard(
                    lesson: lesson,
                    selectedWeek: selectedWeek,
                    isCurrentWeek: isCurrentWeek,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSelector(
    List<DateTime> weeks,
    DateTime selectedWeek,
    DateTime currentWeek,
  ) {
    final index = weeks.indexWhere((week) => _sameDay(week, selectedWeek));
    final hasOlder = index >= 0 && index + 1 < weeks.length;
    final hasNewer = index > 0;
    return Row(
      children: [
        IconButton(
          tooltip: 'الأسبوع التالي',
          onPressed: hasNewer
              ? () => setState(() => _selectedWeek = weeks[index - 1])
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                _sameDay(selectedWeek, currentWeek)
                    ? 'الأسبوع الحالي'
                    : PrepDateFormatter.formatWeek(selectedWeek),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                PrepDateFormatter.formatWeek(selectedWeek),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'الأسبوع السابق',
          onPressed: hasOlder
              ? () => setState(() => _selectedWeek = weeks[index + 1])
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
      ],
    );
  }

  Widget _buildMainLessonCard({
    required WeeklyLesson? lesson,
    required DateTime selectedWeek,
    required bool isCurrentWeek,
  }) {
    if (lesson == null) {
      final stage = _stageForId(_selectedStageId);
      final stageNotice = stage != null ? ' لمرحلة ${stage.name}' : '';

      return SolidCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              isCurrentWeek
                  ? 'لم يتم رفع ملف درس الأسبوع الحالي$stageNotice بعد'
                  : 'لا يوجد ملف درس مسجل لهذا الأسبوع$stageNotice',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'سيتوفر ملف الدرس والتحضير هنا بمجرد أن يقوم القائد برفعه.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final prepAsync = ref.watch(
      servantPreparationProvider((
        lessonId: lesson.id,
        servantProfileId: widget.profile.id,
      )),
    );

    return prepAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(message: 'جاري تحميل تفاصيل التحضير...'),
      ),
      error: (error, _) {
        debugPrint('Failed to load servant preparation: $error');
        return SolidCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 36,
              ),
              const SizedBox(height: 10),
              const Text('تعذر إتمام العملية. حاول مرة أخرى.'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.invalidate(
                  servantPreparationProvider((
                    lessonId: lesson.id,
                    servantProfileId: widget.profile.id,
                  )),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      },
      data: (prep) {
        return _buildLessonContent(
          lesson: lesson,
          prep: prep,
          selectedWeek: selectedWeek,
          isCurrentWeek: isCurrentWeek,
        );
      },
    );
  }

  Widget _buildLessonContent({
    required WeeklyLesson lesson,
    required WeeklyPreparation prep,
    required DateTime selectedWeek,
    required bool isCurrentWeek,
  }) {
    final status = prep.status;
    final isAwaiting = status == PreparationStatus.submitted;
    final isApproved = status == PreparationStatus.approved;
    final stage = _stageForId(lesson.stageId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main lesson card
        SolidCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCurrentWeek
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: isCurrentWeek
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stage != null ? '${stage.name} • ' : ''}${PrepDateFormatter.formatWeek(selectedWeek)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCurrentWeek
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.fileName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: PreparationStatusBadge(
                  status: status,
                  isPendingSync: prep.isPendingSync,
                ),
              ),
              const Divider(height: 28),
              // PDF action buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 16) / 3;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: width,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 2,
                            ),
                          ),
                          onPressed: () => _openPdf(lesson, download: false),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text(
                            'فتح الدرس (PDF)',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 2,
                            ),
                          ),
                          onPressed: isCurrentWeek
                              ? () => _openPdf(lesson, download: true)
                              : null,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text(
                            'تنزيل الملف',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 2,
                            ),
                          ),
                          onPressed: () => _showHistorySheet(lesson: lesson),
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: const Text(
                            'سجل المراجعات',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (!isCurrentWeek) ...[
                const SizedBox(height: 10),
                Text(
                  'ملاحظة: هذا أسبوع سابق (للقراءة والاطلاع فقط). التنزيل وتعديل التحضير متاحان للأسبوع الحالي فقط.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Review Feedback Card (if revision requested or approved with note)
        ReviewFeedbackCard(preparation: prep),

        const SizedBox(height: 18),

        if (isAwaiting || isApproved)
          Container(
            margin: const EdgeInsetsDirectional.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isApproved
                  ? AppColors.of(context).present.background
                  : AppColors.of(context).warning.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isApproved
                      ? Icons.verified_rounded
                      : Icons.hourglass_top_rounded,
                  color: isApproved
                      ? AppColors.of(context).present.foreground
                      : AppColors.of(context).warning.foreground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isApproved
                        ? 'تم اعتماد هذا التحضير بنجاح.'
                        : 'تم تسليم التحضير وهو بانتظار مراجعة القائد.',
                    style: TextStyle(
                      color: isApproved
                          ? AppColors.of(context).present.foreground
                          : AppColors.of(context).warning.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool isResubmission(WeeklyPreparation prep) =>
      prep.status == PreparationStatus.needsRevision;
}
