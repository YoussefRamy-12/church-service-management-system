import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
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
    this.refreshing = false,
  });

  final String serviceId;
  final ServantProfile profile;
  final List<WeeklyLesson> lessons;
  final List<Stage> stages;
  final String? initialStageId;
  final DateTime currentWeekMonday;
  final Future<void> Function() onRefresh;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              download ? 'تعذر تنزيل الملف: $e' : 'تعذر فتح الملف: $e',
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
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              isResubmission
                  ? 'تمت إعادة إرسال التحضير للمراجعة بنجاح.'
                  : 'تم إرسال التحضير للمراجعة بنجاح.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر إرسال التحضير: $e')));
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PreparationHistorySheet(
        reviews: reviews,
        lessonFileName: lesson.fileName,
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
      body: AppContent(
        maxWidth: 820,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveHeaderRow(
              title: 'تحضيري',
              subtitle: 'تحضير الدروس الأسبوعية وإرسالها للمراجعة والاعتماد',
              action: IconButton(
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
            ),
            const SizedBox(height: 12),

            // Stage categorization bar
            if (widget.stages.length > 1) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'المرحلة الدراسية:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                  for (final stage in widget.stages)
                    ChoiceChip(
                      label: Text(stage.name),
                      selected: _selectedStageId == stage.id,
                      onSelected: (val) {
                        if (val) setState(() => _selectedStageId = stage.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ] else if (widget.stages.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'المرحلة: ${widget.stages.first.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final w in weeks) ...[
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: _sameDay(w, selectedWeek),
                onSelected: (val) {
                  if (val) setState(() => _selectedWeek = w);
                },
                avatar: _sameDay(w, currentWeek)
                    ? const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: appPrimary,
                      )
                    : null,
                label: Text(
                  _sameDay(w, currentWeek)
                      ? 'الأسبوع الحالي (${PrepDateFormatter.formatDayMonth(w)})'
                      : PrepDateFormatter.formatWeek(w),
                  style: TextStyle(
                    fontWeight: _sameDay(w, selectedWeek)
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
            const Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
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
            const Text(
              'سيتوفر ملف الدرس والتحضير هنا بمجرد أن يقوم القائد برفعه.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
      error: (error, _) => SolidCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text('تعذر تحميل بيانات التحضير: $error'),
          ],
        ),
      ),
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
    final needsRevision = status == PreparationStatus.needsRevision;
    final isNotSubmitted = status == PreparationStatus.notSubmitted;
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
              // Top badge row - responsive and guarded against overflow
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCurrentWeek
                          ? appSoftBlue
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: isCurrentWeek
                          ? appPrimary
                          : const Color(0xFF64748B),
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
                                ? appPrimary
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.fileName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: PreparationStatusBadge(
                      status: status,
                      isPendingSync: prep.isPendingSync,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              // PDF action buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _openPdf(lesson, download: false),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('فتح الدرس (PDF)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: isCurrentWeek
                        ? () => _openPdf(lesson, download: true)
                        : null,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('تنزيل الملف'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showHistorySheet(lesson: lesson),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('سجل المراجعات'),
                  ),
                ],
              ),
              if (!isCurrentWeek) ...[
                const SizedBox(height: 10),
                const Text(
                  'ملاحظة: هذا أسبوع سابق (للقراءة والاطلاع فقط). التنزيل وتعديل التحضير متاحان للأسبوع الحالي فقط.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ],
          ),
        ),

        // Review Feedback Card (if revision requested or approved with note)
        ReviewFeedbackCard(preparation: prep),

        const SizedBox(height: 18),

        // Submission Action Section
        SolidCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isApproved
                        ? Icons.check_circle_rounded
                        : isAwaiting
                        ? Icons.hourglass_top_rounded
                        : needsRevision
                        ? Icons.warning_amber_rounded
                        : Icons.send_rounded,
                    color: status.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'حالة تسليم التحضير',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: status.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isApproved
                    ? 'تم اعتماد تحضيرك لهذا الدرس من قِبل القائد. مبارك!'
                    : isAwaiting
                    ? 'تم إرسال تحضيرك وهو الآن بانتظار مراجعة القائد. لا يمكن تعديل التحضير أو سحبه أثناء المراجعة.'
                    : needsRevision
                    ? 'طلب القائد تعديلات على التحضير. راجع الملاحظات أعلاه ثم اضغط على إعادة الإرسال بعد إتمام التعديلات.'
                    : 'بعد قراءة ملف الدرس والانتهاء من التحضير، اضغط على الزر أدناه لإرساله للقائد للمراجعة والاعتماد.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 18),
              if (isCurrentWeek) ...[
                if (isNotSubmitted || needsRevision)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: needsRevision
                            ? const Color(0xFFEA580C)
                            : appPrimary,
                      ),
                      onPressed: _submitting
                          ? null
                          : () => _handleSubmit(lesson: lesson, prep: prep),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              needsRevision
                                  ? Icons.refresh_rounded
                                  : Icons.send_rounded,
                            ),
                      label: Text(
                        isResubmission(prep)
                            ? 'إعادة الإرسال للمراجعة'
                            : 'إرسال التحضير للمراجعة',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                else if (isAwaiting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFFB45309),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تم تسليم التحضير وهو قيد المراجعة حالياً من قِبل القائد.',
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isApproved)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF047857),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تم اعتماد هذا التحضير بنجاح.',
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
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
        const SizedBox(height: 32),
      ],
    );
  }

  bool isResubmission(WeeklyPreparation prep) =>
      prep.status == PreparationStatus.needsRevision;
}
