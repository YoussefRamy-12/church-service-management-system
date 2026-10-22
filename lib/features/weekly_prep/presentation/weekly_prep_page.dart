import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/ui/app_ui.dart';
import '../../attendance/domain/entities/meeting.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../auth/domain/entities/servant_profile.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/domain/entities/stage.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/weekly_lesson.dart';
import 'weekly_prep_providers.dart';

class WeeklyPrepPage extends ConsumerStatefulWidget {
  const WeeklyPrepPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<WeeklyPrepPage> createState() => _WeeklyPrepPageState();
}

class _WeeklyPrepPageState extends ConsumerState<WeeklyPrepPage> {
  bool _refreshing = false;
  String? _classStageId;
  late Future<List<Stage>> _stagesFuture;

  @override
  void initState() {
    super.initState();
    _stagesFuture = _loadStages();
    Future.microtask(_loadMeetingSchedule);
  }

  Future<void> _loadMeetingSchedule() async {
    final meetings = ref.read(meetingRepositoryProvider);
    try {
      await meetings.refresh(widget.serviceId);
      final profile = await ref.read(currentServantProfileProvider.future);
      if (ref.read(isSuperAdminProvider) || profile?.role == 'overall_leader') {
        final service = await ref
            .read(serviceRepositoryProvider)
            .getService(widget.serviceId);
        if (service != null) await meetings.ensureConfiguredSchedule(service);
        await meetings.refresh(widget.serviceId);
      }
    } catch (_) {
      // Use the available schedule if the service is offline.
    }
  }

  Future<List<Stage>> _loadStages() async {
    final repository = ref.read(serviceRepositoryProvider);
    final stages = await repository.getStages(widget.serviceId);
    final profile = await ref.read(currentServantProfileProvider.future);
    if ((profile?.role == 'class_servant' || profile?.role == 'class_leader') &&
        profile?.stageId == null &&
        profile?.classId != null) {
      for (final stage in stages) {
        final classes = await repository.getClasses(stage.id);
        if (classes.any((item) => item.id == profile!.classId)) {
          _classStageId = stage.id;
          break;
        }
      }
    }
    return stages;
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId);
      _stagesFuture = _loadStages();
      await ref.read(meetingRepositoryProvider).refresh(widget.serviceId);
      ref.invalidate(weeklyLessonsProvider(widget.serviceId));
      await ref.read(weeklyLessonsProvider(widget.serviceId).future);
    } catch (error) {
      if (mounted) _message('تعذر تحديث التحاضير: $error');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _open(WeeklyLesson lesson, {required bool download}) async {
    try {
      final url = await ref
          .read(weeklyLessonRepositoryProvider)
          .signedUrl(lesson, download: download);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('تعذر فتح الرابط');
      }
    } catch (error) {
      if (mounted) _message('تعذر ${download ? 'تنزيل' : 'فتح'} الملف: $error');
    }
  }

  Future<void> _delete(WeeklyLesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التحضير'),
        content: Text('هل تريد حذف ملف ${lesson.fileName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(weeklyLessonRepositoryProvider).delete(lesson);
      ref.invalidate(weeklyLessonsProvider(widget.serviceId));
      if (mounted) _message('تم حذف التحضير.');
    } catch (error) {
      if (mounted) _message('تعذر حذف التحضير: $error');
    }
  }

  Future<void> _showForm({
    required List<Stage> stages,
    required Stage? initialStage,
    required DateTime week,
    WeeklyLesson? lesson,
  }) async {
    final result = await showDialog<_FormResult>(
      context: context,
      builder: (_) => _WeeklyLessonForm(
        stages: stages,
        initialStage: initialStage,
        lesson: lesson,
        initialWeek: week,
      ),
    );
    if (result != null) {
      try {
        await ref
            .read(weeklyLessonRepositoryProvider)
            .save(
              serviceId: widget.serviceId,
              stageId: result.stage.id,
              weekStart: result.week,
              fileName: result.fileName,
              bytes: result.bytes,
            );
        ref.invalidate(weeklyLessonsProvider(widget.serviceId));
        if (mounted) _message('تم حفظ ملف التحضير.');
      } catch (error) {
        if (mounted) _message('تعذر حفظ التحضير: $error');
      }
    }
  }

  Future<void> _showBulkForm({
    required List<Stage> stages,
    required List<DateTime> weeks,
  }) async {
    final result = await showDialog<_BulkFormResult>(
      context: context,
      builder: (_) => _WeeklyBulkForm(stages: stages, weeks: weeks),
    );
    if (result == null || result.files.isEmpty) return;
    var uploaded = 0;
    try {
      for (final file in result.files) {
        await ref
            .read(weeklyLessonRepositoryProvider)
            .save(
              serviceId: widget.serviceId,
              stageId: result.stage.id,
              weekStart: file.week,
              fileName: file.fileName,
              bytes: file.bytes,
            );
        uploaded++;
      }
      ref.invalidate(weeklyLessonsProvider(widget.serviceId));
      if (mounted) _message('تم رفع ملفات $uploaded أسبوعًا.');
    } catch (error) {
      ref.invalidate(weeklyLessonsProvider(widget.serviceId));
      if (mounted) _message('تم رفع $uploaded ملفًا، وتعذر رفع الباقي: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentServantProfileProvider);
    final superAdmin = ref.watch(isSuperAdminProvider);
    return FutureBuilder<List<Stage>>(
      future: _stagesFuture,
      builder: (context, stageSnapshot) {
        final stages = stageSnapshot.data ?? const <Stage>[];
        return FutureBuilder<ServantProfile?>(
          future: profileState.when(
            data: (value) async => value,
            error: (_, _) async => null,
            loading: () async => null,
          ),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;
            final isManager =
                superAdmin ||
                profile?.role == 'overall_leader' ||
                profile?.role == 'stage_leader';
            return Scaffold(
              body: AppContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تحضيري',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'ملفات الدروس الأسبوعية حسب المرحلة — فتح وتنزيل الأسبوع الحالي فقط',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _refreshing ? null : _refresh,
                          tooltip: 'تحديث',
                          icon: _refreshing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (stageSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        profileState.isLoading)
                      const Expanded(
                        child: LoadingView(message: 'جاري تحميل المراحل...'),
                      )
                    else if (profile == null && !superAdmin)
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.lock_outline,
                          title: 'تعذر تحديد صلاحيات الحساب',
                          message: 'أعد تسجيل الدخول ثم حاول مرة أخرى.',
                        ),
                      )
                    else
                      Expanded(
                        child: StreamBuilder<List<Meeting>>(
                          stream: ref
                              .watch(meetingRepositoryProvider)
                              .watchMeetings(widget.serviceId),
                          builder: (context, meetingSnapshot) => _lessonList(
                            stages,
                            profile,
                            superAdmin,
                            isManager,
                            _weeksFromMeetings(
                              meetingSnapshot.data ?? const [],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _lessonList(
    List<Stage> stages,
    ServantProfile? profile,
    bool superAdmin,
    bool isManager,
    List<DateTime> weeks,
  ) {
    final allowedStages = _permittedStages(stages, profile, superAdmin);
    if (allowedStages.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'لا توجد مرحلة متاحة',
        message: 'لا توجد مرحلة مرتبطة بحسابك لعرض تحاضيرها.',
      );
    }
    final lessons = ref.watch(weeklyLessonsProvider(widget.serviceId));
    return lessons.when(
      loading: () => const LoadingView(message: 'جاري تحميل ملفات التحضير...'),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'تعذر تحميل التحاضير',
        message: '$error',
        action: OutlinedButton.icon(
          onPressed: () =>
              ref.invalidate(weeklyLessonsProvider(widget.serviceId)),
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      ),
      data: (allLessons) {
        final allowedIds = allowedStages.map((stage) => stage.id).toSet();
        final visible = allLessons
            .where((item) => allowedIds.contains(item.stageId))
            .toList();
        final currentWeek = _monday(DateTime.now());
        final plannedWeeks = weeks.isEmpty ? [currentWeek] : weeks;
        return ListView(
          children: [
            if (isManager)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.upload_file_rounded),
                    ),
                    title: const Text(
                      'رفع تحضيرات الأسابيع دفعة واحدة',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'اختر ملفات الأسابيع ثم احفظها مرة واحدة.',
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _showBulkForm(
                      stages: allowedStages,
                      weeks: plannedWeeks,
                    ),
                  ),
                ),
              ),
            for (final stage in allowedStages) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  stage.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              for (final week in plannedWeeks)
                Builder(
                  builder: (context) {
                    final matches = visible.where(
                      (item) =>
                          item.stageId == stage.id &&
                          _sameDay(item.weekStart, week),
                    );
                    final lesson = matches.isEmpty ? null : matches.first;
                    final isCurrent = _sameDay(week, currentWeek);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            isCurrent
                                ? Icons.calendar_today_rounded
                                : Icons.lock_outline_rounded,
                          ),
                        ),
                        title: Text(
                          _weekLabel(week),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          lesson?.fileName ??
                              (isCurrent
                                  ? 'لا يوجد ملف مرفوع لهذا الأسبوع'
                                  : 'غير متاح للفتح الآن'),
                        ),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            if (lesson != null)
                              IconButton(
                                tooltip: isCurrent
                                    ? 'فتح الملف الحالي'
                                    : 'الأسبوع الحالي فقط متاح للفتح',
                                onPressed: isCurrent
                                    ? () => _open(lesson, download: false)
                                    : null,
                                icon: const Icon(Icons.open_in_new_rounded),
                              ),
                            if (lesson != null)
                              IconButton(
                                tooltip: isCurrent
                                    ? 'تنزيل الملف الحالي'
                                    : 'الأسبوع الحالي فقط متاح للتنزيل',
                                onPressed: isCurrent
                                    ? () => _open(lesson, download: true)
                                    : null,
                                icon: const Icon(Icons.download_rounded),
                              ),
                            if (isManager)
                              IconButton(
                                tooltip: lesson == null
                                    ? 'رفع ملف لهذا الأسبوع'
                                    : 'استبدال الملف',
                                onPressed: () => _showForm(
                                  stages: allowedStages,
                                  initialStage: stage,
                                  lesson: lesson,
                                  week: week,
                                ),
                                icon: Icon(
                                  lesson == null
                                      ? Icons.upload_file_rounded
                                      : Icons.edit_outlined,
                                ),
                              ),
                            if (isManager && lesson != null)
                              IconButton(
                                tooltip: 'حذف',
                                onPressed: () => _delete(lesson),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        );
      },
    );
  }

  List<DateTime> _weeksFromMeetings(List<Meeting> meetings) {
    final weeks = meetings
        .map((meeting) => _monday(meeting.meetingDate))
        .toSet()
        .toList();
    final currentWeek = _monday(DateTime.now());
    if (!weeks.any((week) => _sameDay(week, currentWeek))) {
      weeks.add(currentWeek);
    }
    weeks.sort((a, b) => b.compareTo(a));
    return weeks;
  }

  DateTime _monday(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Stage> _permittedStages(
    List<Stage> stages,
    ServantProfile? profile,
    bool superAdmin,
  ) {
    if (superAdmin || profile?.role == 'overall_leader') return stages;
    final assignedStage = profile?.stageId ?? _classStageId;
    if (assignedStage != null) {
      return stages.where((stage) => stage.id == assignedStage).toList();
    }
    return const [];
  }

  String _weekLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    final formatter = DateFormat('d MMMM', 'ar');
    return 'أسبوع ${formatter.format(start)} – ${formatter.format(end)}';
  }
}

class _WeeklyLessonForm extends StatefulWidget {
  const _WeeklyLessonForm({
    required this.stages,
    required this.initialStage,
    required this.lesson,
    required this.initialWeek,
  });
  final List<Stage> stages;
  final Stage? initialStage;
  final WeeklyLesson? lesson;
  final DateTime initialWeek;

  @override
  State<_WeeklyLessonForm> createState() => _WeeklyLessonFormState();
}

class _WeeklyLessonFormState extends State<_WeeklyLessonForm> {
  late Stage? _stage = widget.initialStage;
  // ignore: prefer_final_fields
  late DateTime _week = widget.lesson?.weekStart ?? widget.initialWeek;
  PlatformFile? _file;
  Uint8List? _fileBytes;
  bool _saving = false;
  String? _error;

  Future<void> _selectFile() async {
    final files = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (files.isEmpty) return;
    final file = files.single;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || !_isPdf(bytes)) {
      setState(() => _error = 'الملف المختار ليس ملف PDF صالحًا.');
      return;
    }
    if (bytes.length > 25 * 1024 * 1024) {
      setState(() => _error = 'حجم الملف أكبر من الحد المسموح (25 ميجابايت).');
      return;
    }
    setState(() {
      _file = file;
      _fileBytes = bytes;
      _error = null;
    });
  }

  bool _isPdf(Uint8List bytes) =>
      bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-';

  Future<void> _save() async {
    final file = _file;
    if (_stage == null) {
      setState(() => _error = 'اختر المرحلة.');
      return;
    }
    if (file == null || _fileBytes == null) {
      setState(() => _error = 'اختر ملف PDF أولًا.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      Navigator.of(context).pop(
        _FormResult(
          stage: _stage!,
          week: _week,
          fileName: file.name,
          bytes: _fileBytes!,
        ),
      );
    } catch (error) {
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _week.add(const Duration(days: 6));
    return AlertDialog(
      title: Text(
        widget.lesson == null ? 'رفع تحضير أسبوعي' : 'استبدال ملف التحضير',
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Stage>(
              initialValue: _stage,
              decoration: const InputDecoration(labelText: 'المرحلة'),
              items: [
                for (final stage in widget.stages)
                  DropdownMenuItem(value: stage, child: Text(stage.name)),
              ],
              onChanged: widget.lesson == null
                  ? (stage) => setState(() => _stage = stage)
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                'الأسبوع: ${DateFormat('d/M/y').format(_week)} – ${DateFormat('d/M/y').format(weekEnd)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _selectFile,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                _file?.name ?? (widget.lesson?.fileName ?? 'اختر ملف PDF'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

class _WeeklyBulkForm extends StatefulWidget {
  const _WeeklyBulkForm({required this.stages, required this.weeks});
  final List<Stage> stages;
  final List<DateTime> weeks;

  @override
  State<_WeeklyBulkForm> createState() => _WeeklyBulkFormState();
}

class _WeeklyBulkFormState extends State<_WeeklyBulkForm> {
  Stage? _stage;
  final Map<String, _PickedPdf> _files = {};
  bool _saving = false;
  String? _error;

  String _key(DateTime week) =>
      '${week.year.toString().padLeft(4, '0')}-${week.month.toString().padLeft(2, '0')}-${week.day.toString().padLeft(2, '0')}';

  Future<void> _pick(DateTime week) async {
    final files = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (files.isEmpty) return;
    final file = files.single;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      setState(() => _error = 'الملف ${file.name} ليس ملف PDF صالحًا.');
      return;
    }
    if (bytes.length > 25 * 1024 * 1024) {
      setState(
        () => _error = 'حجم ${file.name} أكبر من الحد المسموح (25 ميجابايت).',
      );
      return;
    }
    setState(() {
      _files[_key(week)] = _PickedPdf(file: file, bytes: bytes);
      _error = null;
    });
  }

  void _submit() {
    if (_stage == null) {
      setState(() => _error = 'اختر المرحلة.');
      return;
    }
    if (_files.isEmpty) {
      setState(() => _error = 'اختر ملفًا واحدًا على الأقل.');
      return;
    }
    setState(() => _saving = true);
    final files = <_FormResult>[];
    for (final week in widget.weeks) {
      final file = _files[_key(week)];
      if (file != null) {
        files.add(
          _FormResult(
            stage: _stage!,
            week: week,
            fileName: file.file.name,
            bytes: file.bytes,
          ),
        );
      }
    }
    Navigator.of(context).pop(_BulkFormResult(stage: _stage!, files: files));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.68;
    return AlertDialog(
      title: const Text('رفع تحضيرات الأسابيع'),
      content: SizedBox(
        width: 560,
        height: height.clamp(300, 680).toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Stage>(
              initialValue: _stage,
              decoration: const InputDecoration(labelText: 'المرحلة'),
              items: [
                for (final stage in widget.stages)
                  DropdownMenuItem(value: stage, child: Text(stage.name)),
              ],
              onChanged: _saving
                  ? null
                  : (stage) => setState(() => _stage = stage),
            ),
            const SizedBox(height: 10),
            const Text(
              'اختر ملفًا لكل أسبوع تريد تجهيزه. يمكن حفظ الملفات كلها معًا.',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.weeks.length,
                itemBuilder: (context, index) {
                  final week = widget.weeks[index];
                  final file = _files[_key(week)];
                  final currentWeek = DateTime.now();
                  final weekStart = currentWeek.subtract(
                    Duration(days: currentWeek.weekday - 1),
                  );
                  final isCurrent = _key(week) == _key(weekStart);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isCurrent
                          ? Icons.calendar_today_rounded
                          : Icons.date_range_rounded,
                    ),
                    title: Text(_label(week)),
                    subtitle: Text(file?.file.name ?? 'لم يتم اختيار ملف'),
                    trailing: IconButton(
                      tooltip: 'اختيار ملف PDF',
                      onPressed: _saving ? null : () => _pick(week),
                      icon: Icon(
                        file == null
                            ? Icons.attach_file_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('حفظ ${_files.length} ملفًا'),
        ),
      ],
    );
  }

  String _label(DateTime start) =>
      'أسبوع ${DateFormat('d/M/y').format(start)} – ${DateFormat('d/M/y').format(start.add(const Duration(days: 6)))}';
}

class _BulkFormResult {
  const _BulkFormResult({required this.stage, required this.files});
  final Stage stage;
  final List<_FormResult> files;
}

class _PickedPdf {
  const _PickedPdf({required this.file, required this.bytes});
  final PlatformFile file;
  final Uint8List bytes;
}

class _FormResult {
  const _FormResult({
    required this.stage,
    required this.week,
    required this.fileName,
    required this.bytes,
  });
  final Stage stage;
  final DateTime week;
  final String fileName;
  final Uint8List bytes;
}
