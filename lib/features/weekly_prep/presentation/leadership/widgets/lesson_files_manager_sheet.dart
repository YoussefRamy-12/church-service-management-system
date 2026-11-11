import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:church_service_management_system/features/service/domain/entities/stage.dart';
import '../../../domain/prep_date_formatter.dart';
import '../../../domain/weekly_lesson.dart';
import '../../weekly_prep_providers.dart';

class LessonFilesManagerSheet extends ConsumerStatefulWidget {
  const LessonFilesManagerSheet({
    super.key,
    required this.serviceId,
    required this.stages,
    required this.weeks,
    required this.lessons,
  });

  final String serviceId;
  final List<Stage> stages;
  final List<DateTime> weeks;
  final List<WeeklyLesson> lessons;

  @override
  ConsumerState<LessonFilesManagerSheet> createState() =>
      _LessonFilesManagerSheetState();
}

class _LessonFilesManagerSheetState
    extends ConsumerState<LessonFilesManagerSheet> {
  // ignore: unused_field
  bool _saving = false;

  String _formatWeek(DateTime monday) {
    return PrepDateFormatter.formatWeekWithYear(monday);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _deleteLesson(WeeklyLesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف ملف التحضير'),
        content: Text('هل أنت متأكد من حذف ملف "${lesson.fileName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(weeklyLessonRepositoryProvider).delete(lesson);
      ref.invalidate(weeklyLessonsProvider(widget.serviceId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف ملف الدرس بنجاح.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حذف الملف: $e')));
      }
    }
  }

  Future<void> _showUploadForm({
    required Stage stage,
    required DateTime week,
    WeeklyLesson? existingLesson,
  }) async {
    final result = await showDialog<_UploadResult>(
      context: context,
      builder: (ctx) => _SingleLessonUploadDialog(
        stage: stage,
        week: week,
        existingLesson: existingLesson,
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _saving = true);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ ملف الدرس بنجاح.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حفظ الملف: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPdf(WeeklyLesson lesson) async {
    try {
      final url = await ref
          .read(weeklyLessonRepositoryProvider)
          .signedUrl(lesson, download: false);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('تعذر فتح الرابط');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح الملف: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: 720,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_shared_rounded, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'إدارة ملفات الدروس الأسبوعية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView(
              children: [
                for (final stage in widget.stages) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      stage.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  for (final week in widget.weeks)
                    Builder(
                      builder: (ctx) {
                        final matches = widget.lessons.where(
                          (l) =>
                              l.stageId == stage.id &&
                              _sameDay(l.weekStart, week),
                        );
                        final lesson = matches.isNotEmpty
                            ? matches.first
                            : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                lesson != null
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.upload_file_rounded,
                                size: 22,
                                color: lesson != null
                                    ? Colors.red
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatWeek(week),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      lesson?.fileName ?? 'لا يوجد ملف مرفوع',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: lesson != null
                                            ? const Color(0xFF334155)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (lesson != null) ...[
                                IconButton(
                                  tooltip: 'فتح الملف',
                                  onPressed: () => _openPdf(lesson),
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'استبدال الملف',
                                  onPressed: () => _showUploadForm(
                                    stage: stage,
                                    week: week,
                                    existingLesson: lesson,
                                  ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  onPressed: () => _deleteLesson(lesson),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                ),
                              ] else
                                FilledButton.tonalIcon(
                                  onPressed: () =>
                                      _showUploadForm(stage: stage, week: week),
                                  icon: const Icon(
                                    Icons.upload_file_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('رفع ملف'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadResult {
  const _UploadResult({
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

class _SingleLessonUploadDialog extends StatefulWidget {
  const _SingleLessonUploadDialog({
    required this.stage,
    required this.week,
    this.existingLesson,
  });

  final Stage stage;
  final DateTime week;
  final WeeklyLesson? existingLesson;

  @override
  State<_SingleLessonUploadDialog> createState() =>
      _SingleLessonUploadDialogState();
}

class _SingleLessonUploadDialogState extends State<_SingleLessonUploadDialog> {
  PlatformFile? _file;
  Uint8List? _fileBytes;
  String? _error;

  Future<void> _pickFile() async {
    final files = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (files.isEmpty) return;

    final file = files.single;
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty ||
        bytes.length < 5 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      setState(() => _error = 'الملف المختار ليس ملف PDF صالحاً.');
      return;
    }

    if (bytes.length > 25 * 1024 * 1024) {
      setState(() => _error = 'حجم الملف يتجاوز الحد المسموح (25 ميجابايت).');
      return;
    }

    setState(() {
      _file = file;
      _fileBytes = bytes;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existingLesson == null ? 'رفع درس أسبوعي' : 'استبدال ملف الدرس',
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'المرحلة: ${widget.stage.name}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'الأسبوع: ${PrepDateFormatter.formatWeek(widget.week)}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                _file?.name ??
                    (widget.existingLesson?.fileName ?? 'اختر ملف PDF'),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _file == null || _fileBytes == null
              ? null
              : () {
                  Navigator.pop(
                    context,
                    _UploadResult(
                      stage: widget.stage,
                      week: widget.week,
                      fileName: _file!.name,
                      bytes: _fileBytes!,
                    ),
                  );
                },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
