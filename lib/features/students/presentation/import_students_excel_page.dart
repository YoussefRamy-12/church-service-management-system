// ignore_for_file: deprecated_member_use

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/utils/file_download_helper.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/domain/entities/service_class.dart';
import '../../service/domain/entities/stage.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/entities/student.dart';
import '../services/excel_student_import_service.dart';
import 'student_providers.dart';

class ImportStudentsExcelPage extends ConsumerStatefulWidget {
  const ImportStudentsExcelPage({
    super.key,
    required this.serviceId,
    this.initialClassId,
    this.initialClassName,
  });

  final String serviceId;
  final String? initialClassId;
  final String? initialClassName;

  @override
  ConsumerState<ImportStudentsExcelPage> createState() =>
      _ImportStudentsExcelPageState();
}

class _ImportStudentsExcelPageState
    extends ConsumerState<ImportStudentsExcelPage> {
  // Structure & Authorization State
  bool _loadingStructure = true;
  List<Stage> _stages = [];
  Map<String, List<ServiceClass>> _stageClasses = {};
  List<String> _studyYears = [];
  String? _selectedStudyYear;
  String? _selectedStageId;
  String? _selectedClassId;
  bool _isClassLocked = false;
  String? _lockedClassLabel;
  bool _replaceClassStudents = false;

  // File & Parsing State
  PlatformFile? _pickedFile;
  String _fileName = '';
  int _fileSizeBytes = 0;
  bool _parsingFile = false;
  ExcelParseResult? _parseResult;
  // Import Execution State
  bool _importing = false;
  int? _successCount;
  int? _failedCount;

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  Future<void> _loadStructure() async {
    setState(() => _loadingStructure = true);
    final serviceRepo = ref.read(serviceRepositoryProvider);

    try {
      await serviceRepo.refreshStages(widget.serviceId);
      await serviceRepo.refreshReportingPeriods(widget.serviceId);
    } catch (_) {}

    final stages = await serviceRepo.getStages(widget.serviceId);
    final Map<String, List<ServiceClass>> stageClasses = {};
    for (final s in stages) {
      try {
        await serviceRepo.refreshClasses(s.id);
      } catch (_) {}
      stageClasses[s.id] = await serviceRepo.getClasses(s.id);
    }

    final periods = await serviceRepo.getReportingPeriods(widget.serviceId);
    final List<String> years = periods.map((p) => p.name).toList();
    if (years.isEmpty) {
      final now = DateTime.now();
      years.add('سنة الخدمة ${now.year} - ${now.year + 1}');
    }

    // Role scope
    final profile = await ref.read(currentServantProfileProvider.future);
    final isScoped =
        (profile?.role == 'class_servant' ||
        profile?.role == 'class_leader' ||
        profile?.role == 'overall_leader ' && profile?.classId != null);

    String? preselectedStageId;
    String? preselectedClassId =
        widget.initialClassId ?? (isScoped ? profile?.classId : null);
    String? lockedLabel = widget.initialClassName;

    if (preselectedClassId != null) {
      for (final s in stages) {
        final classes = stageClasses[s.id] ?? [];
        for (final c in classes) {
          if (c.id == preselectedClassId) {
            preselectedStageId = s.id;
            lockedLabel ??= '${s.name} • ${c.name}';
            break;
          }
        }
      }
    } else if (stages.isNotEmpty) {
      preselectedStageId = stages.first.id;
      final firstClasses = stageClasses[preselectedStageId] ?? [];
      if (firstClasses.isNotEmpty) {
        preselectedClassId = firstClasses.first.id;
      }
    }

    if (mounted) {
      setState(() {
        _stages = stages;
        _stageClasses = stageClasses;
        _studyYears = years;
        _selectedStudyYear = years.first;
        _selectedStageId = preselectedStageId;
        _selectedClassId = preselectedClassId;
        _isClassLocked = isScoped;
        _lockedClassLabel = lockedLabel;
        _loadingStructure = false;
      });
    }
  }

  Future<void> _pickAndParseFile() async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الملف المحدد فارغ أو تعذر قراءته.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      setState(() {
        _pickedFile = file;
        _fileName = file.name;
        _fileSizeBytes = bytes.length;
        _parsingFile = true;
        _successCount = null;
        _failedCount = null;
      });

      // Duplicate detection is scoped to the destination class. Replacement
      // intentionally ignores the old roster because it will be removed.
      final existing = _replaceClassStudents || _selectedClassId == null
          ? <Student>[]
          : await ref
                .read(studentRepositoryProvider)
                .watchStudentsForClass(_selectedClassId!)
                .first;

      final allStages = _stages;
      final allClasses = _stageClasses.values.expand((c) => c).toList();
      final selectedStage = _stages
          .where((s) => s.id == _selectedStageId)
          .firstOrNull;

      final importService = ref.read(excelStudentImportServiceProvider);
      final parseResult = importService.parseExcelBytes(
        bytes: bytes,
        existingStudents: existing,
        defaultClassId: _selectedClassId,
        defaultStageId: _selectedStageId,
        defaultGrade: selectedStage?.name,
        availableClasses: allClasses,
        availableStages: allStages,
      );

      if (mounted) {
        setState(() {
          _parseResult = parseResult;
          _parsingFile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _parsingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر قراءة ملف Excel: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _downloadErrorReport() {
    if (_parseResult == null) return;
    final importService = ref.read(excelStudentImportServiceProvider);
    final errorRows = _parseResult!.rows.where((r) => !r.isValid).toList();
    final bytes = importService.generateErrorReportExcel(errorRows);
    FileDownloadHelper.downloadBytes(
      bytes: bytes,
      filename: 'import_errors_report.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> _executeImport() async {
    if (_parseResult == null || _selectedClassId == null) return;

    final rowsToImport = _parseResult!.validRows;

    if (rowsToImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد صفوف صالحة للاستيراد.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('تأكيد استيراد الطلاب'),
        content: Text(
          _replaceClassStudents
              ? 'سيتم حذف طلاب الفصل الحاليين وسجلات حضورهم وافتقادهم نهائيًا، ثم استيراد ${rowsToImport.length} طالب من الملف.'
              : 'سيتم إضافة ${rowsToImport.length} طالب إلى الفصل. سيتم تخطي الطلاب الموجودين بالفعل وأي صف به مشكلة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00236F),
            ),
            child: const Text('تأكيد الاستيراد'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);

    try {
      final selectedStage = _stages
          .where((s) => s.id == _selectedStageId)
          .firstOrNull;
      final inputs = rowsToImport
          .map(
            (r) => r.toRegistrationInput(
              fallbackClassId: _selectedClassId,
              fallbackGrade: selectedStage?.name,
              forceClassId: _selectedClassId,
            ),
          )
          .toList();
      final registration = ref.read(studentRegistrationProvider);

      final studentRepository = ref.read(studentRepositoryProvider);
      if (_replaceClassStudents) {
        final currentStudents = await studentRepository
            .watchStudentsForClass(_selectedClassId!)
            .first;
        for (final student in currentStudents) {
          await studentRepository.deleteStudent(student.id);
        }
      }

      var successCount = 0;
      for (var index = 0; index < inputs.length; index++) {
        final row = rowsToImport[index];
        try {
          final created = await registration.registerBatch(
            serviceId: widget.serviceId,
            currentClassId: _selectedClassId,
            inputs: [inputs[index]],
          );
          if (created.isEmpty) {
            throw StateError('لم تُرجع عملية الحفظ سجلًا.');
          }
          successCount++;
        } catch (error) {
          row.errors.add('تعذر استيراد هذا الصف (${row.name}): $error');
        }
      }

      if (mounted) {
        setState(() {
          _importing = false;
          _successCount = successCount;
          _failedCount = _parseResult!.totalRows - successCount;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل أثناء تنفيذ الاستيراد: $error'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentStageClasses = _selectedStageId != null
        ? (_stageClasses[_selectedStageId] ?? [])
        : <ServiceClass>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'استيراد الطلاب من Excel',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AmbientBackground(
        intensity: 0.4,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: _loadingStructure
                ? const LoadingView(
                    message: 'جاري تحميل الفصول وإعدادات الاستيراد...',
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    children: [
                      // Finished Success Banner
                      if (_successCount != null) ...[
                        _buildSuccessResultCard(),
                        const SizedBox(height: 24),
                      ],

                      // Step 1: Destination Selection
                      _buildSectionHeader(
                        'الخطوة 1: تحديد وجهة الاستيراد والفصل',
                        Icons.account_tree_outlined,
                      ),
                      SolidCard(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isClassLocked)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF4FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFDCE9FF),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF00236F),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'الوجهة محددة بفصلك المصرح لك إدارته: ${_lockedClassLabel ?? ''}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF00236F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              DropdownButtonFormField<String>(
                                initialValue: _selectedStudyYear,
                                decoration: const InputDecoration(
                                  labelText: 'سنة الخدمة / السنة الدراسية *',
                                  prefixIcon: Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                ),
                                items: [
                                  for (final y in _studyYears)
                                    DropdownMenuItem(value: y, child: Text(y)),
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedStudyYear = val),
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedStageId,
                                          decoration: const InputDecoration(
                                            labelText: 'المرحلة الدراسية *',
                                            prefixIcon: Icon(
                                              Icons.layers_outlined,
                                            ),
                                          ),
                                          items: [
                                            for (final s in _stages)
                                              DropdownMenuItem(
                                                value: s.id,
                                                child: Text(s.name),
                                              ),
                                          ],
                                          onChanged: (newStageId) {
                                            if (newStageId == null) return;
                                            setState(() {
                                              _selectedStageId = newStageId;
                                              final classes =
                                                  _stageClasses[newStageId] ??
                                                  [];
                                              _selectedClassId =
                                                  classes.isNotEmpty
                                                  ? classes.first.id
                                                  : null;
                                            });
                                          },
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 14),
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedClassId,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'الفصل الدراسي المستهدف *',
                                            prefixIcon: Icon(
                                              Icons.class_outlined,
                                            ),
                                          ),
                                          items: [
                                            for (final c in currentStageClasses)
                                              DropdownMenuItem(
                                                value: c.id,
                                                child: Text(c.name),
                                              ),
                                          ],
                                          onChanged: (newClassId) => setState(
                                            () => _selectedClassId = newClassId,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'سيتم تسكين جميع الطلاب المستوردين في هذا الفصل بحالة «بانتظار الاعتماد».',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'طريقة التعامل مع طلاب الفصل الحاليين:',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            RadioListTile<bool>(
                              contentPadding: EdgeInsets.zero,
                              value: false,
                              // ignore: duplicate_ignore
                              // ignore: deprecated_member_use
                              groupValue: _replaceClassStudents,
                              title: const Text('الإضافة إلى الطلاب الحاليين'),
                              subtitle: const Text(
                                'يتخطى الطلاب الموجودين بالفعل في هذا الفصل.',
                              ),
                              onChanged: _importing
                                  ? null
                                  : (_) => setState(() {
                                      _replaceClassStudents = false;
                                      _parseResult = null;
                                      _pickedFile = null;
                                      _fileName = '';
                                    }),
                            ),
                            RadioListTile<bool>(
                              contentPadding: EdgeInsets.zero,
                              value: true,
                              groupValue: _replaceClassStudents,
                              title: const Text('استبدال جميع طلاب الفصل'),
                              subtitle: const Text(
                                'يحذف القائمة الحالية وسجلاتها المرتبطة قبل استيراد القائمة الجديدة.',
                              ),
                              onChanged: _importing
                                  ? null
                                  : (_) => setState(() {
                                      _replaceClassStudents = true;
                                      _parseResult = null;
                                      _pickedFile = null;
                                      _fileName = '';
                                    }),
                            ),
                          ],
                        ),
                      ),

                      // Step 2: Download Template
                      _buildSectionHeader(
                        'الخطوة 2: تحميل قالب Excel الجاهز',
                        Icons.download_rounded,
                      ),
                      SolidCard(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF059669,
                                ).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.table_view_rounded,
                                color: Color(0xFF059669),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'قالب استيراد الطلاب المعتمد (.xlsx)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'يحتوي القالب على العناوين الصحيحة، التنسيقات المطلوبة، وصف توضيحي استرشادي.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              key: const Key('download_excel_template_button'),
                              onPressed: () {
                                ref
                                    .read(excelStudentImportServiceProvider)
                                    .downloadTemplate();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تنزيل قالب Excel بنجاح.'),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.file_download_outlined,
                                size: 20,
                              ),
                              label: const Text('تحميل القالب'),
                            ),
                          ],
                        ),
                      ),

                      // Step 3: Pick & Parse File
                      _buildSectionHeader(
                        'الخطوة 3: اختيار ملف Excel وفحصه',
                        Icons.upload_file_rounded,
                      ),
                      SolidCard(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _parsingFile || _importing
                                  ? null
                                  : _pickAndParseFile,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(
                                      0xFF00236F,
                                    ).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(
                                    0xFF00236F,
                                  ).withValues(alpha: 0.03),
                                ),
                                child: Column(
                                  children: [
                                    if (_parsingFile)
                                      const CircularProgressIndicator()
                                    else
                                      const Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 44,
                                        color: Color(0xFF00236F),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _pickedFile != null
                                          ? _fileName
                                          : 'اضغط لاختيار ملف Excel (.xlsx) من جهازك',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _pickedFile != null
                                          ? 'الحجم: ${(_fileSizeBytes / 1024).toStringAsFixed(1)} كيلوبايت - اضغط للتغيير'
                                          : 'يدعم الملفات بصيغة .xlsx فقط مع التحقق التلقائي من التكرار والبيانات',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Step 4: Preview & Validation Results
                      if (_parseResult != null) ...[
                        _buildSectionHeader(
                          'الخطوة 4: مراجعة البيانات قبل الاستيراد',
                          Icons.fact_check_outlined,
                        ),
                        _buildPreviewSummaryBar(),
                        const SizedBox(height: 16),
                        _buildParsedRowsList(),
                        const SizedBox(height: 24),

                        // Step 5: Execute Import Action
                        _buildSectionHeader(
                          'الخطوة 5: تأكيد الاستيراد',
                          Icons.send_rounded,
                        ),
                        SolidCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'سيتم تخطي الصفوف التي بها أخطاء أو تكرار مع توضيح اسم الطالب ورقم الصف، ثم متابعة استيراد بقية الملف.',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if (_parseResult!.hasErrors)
                                    OutlinedButton.icon(
                                      onPressed: _downloadErrorReport,
                                      icon: const Icon(
                                        Icons.download_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('تحميل تقرير الأخطاء'),
                                    ),
                                  const Spacer(),
                                  FilledButton.icon(
                                    key: const Key(
                                      'confirm_import_excel_button',
                                    ),
                                    onPressed:
                                        _importing ||
                                            _parseResult!.validRows.isEmpty
                                        ? null
                                        : _executeImport,
                                    icon: _importing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 20,
                                          ),
                                    label: Text(
                                      _importing
                                          ? 'جاري الاستيراد...'
                                          : 'تأكيد استيراد ${_parseResult!.validRows.length} طالب',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF00236F),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSummaryBar() {
    final res = _parseResult!;
    return Row(
      children: [
        Expanded(
          child: _summaryStatCard(
            'إجمالي الصفوف',
            res.totalRows.toString(),
            const Color(0xFF00236F),
            Icons.format_list_numbered_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryStatCard(
            'صالحة للاستيراد',
            res.validRows.length.toString(),
            const Color(0xFF059669),
            Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryStatCard(
            'مكررة',
            res.duplicateRows.length.toString(),
            const Color(0xFFD97706),
            Icons.copy_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryStatCard(
            'بها أخطاء',
            res.errorRows.length.toString(),
            const Color(0xFFDC2626),
            Icons.error_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _summaryStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParsedRowsList() {
    final rows = _parseResult!.rows;
    return SolidCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معاينة سجلات الطلاب المستخرجة:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = rows[index];
              final isDup = r.isDuplicate;
              final hasErr = r.errors.isNotEmpty;
              final Color badgeColor = hasErr
                  ? const Color(0xFFDC2626)
                  : isDup
                  ? const Color(0xFFD97706)
                  : const Color(0xFF059669);
              final String badgeText = hasErr
                  ? 'خطأ'
                  : isDup
                  ? 'مكرر'
                  : 'جاهز';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: badgeColor.withValues(alpha: 0.15),
                      child: Text(
                        '${r.rowNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name.isEmpty ? '— اسم مفقود —' : r.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (r.school != null && r.school!.isNotEmpty)
                            Text(
                              r.school!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          if (hasErr || isDup)
                            Text(
                              hasErr
                                  ? r.errors.join(' • ')
                                  : (r.duplicateReason ?? 'مكرر'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: badgeColor),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        r.phone ?? 'بدون هاتف',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    if (hasErr || isDup) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: hasErr
                            ? r.errors.join('\n')
                            : (r.duplicateReason ?? 'مكرر'),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'اكتملت عملية الاستيراد',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'تم استيراد $_successCount طالب إلى الفصل المحدد. راجع الصفوف التي ظهرت عليها أخطاء قبل إعادة المحاولة.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (_failedCount != null && _failedCount! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'تم استبعاد $_failedCount صف لوجود تكرار أو أخطاء في البيانات.',
                style: const TextStyle(fontSize: 12, color: Color(0xFFD97706)),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
                child: const Text('العودة لقائمة الفصل'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00236F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
