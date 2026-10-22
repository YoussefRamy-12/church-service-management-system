import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../../students/presentation/student_providers.dart';
import '../data/csv_export_repository.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({
    super.key,
    required this.serviceId,
    this.classId,
    this.graduationOnly = false,
  });
  final String serviceId;
  final String? classId;
  final bool graduationOnly;
  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  String scope = 'service';
  late bool graduationOnly = widget.graduationOnly;
  String? stageId;
  String? selectedClassId;
  Set<String> selectedStudentIds = {};
  bool exporting = false;
  bool loading = true;
  List<dynamic> stages = [];
  List<dynamic> classes = [];
  List<dynamic> students = [];
  String role = '';

  @override
  void initState() {
    super.initState();
    selectedClassId = widget.classId;
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    final isSuperAdmin = ref.read(isSuperAdminProvider);
    final offlineEnabled = ref.read(offlineSyncEnabledProvider);
    final allStages = await ref
        .read(serviceRepositoryProvider)
        .getStages(widget.serviceId);
    final allClasses = <dynamic>[];
    for (final stage in allStages) {
      allClasses.addAll(
        await ref.read(serviceRepositoryProvider).getClasses(stage.id),
      );
    }
    final List<dynamic> loadedStudents;
    if (offlineEnabled) {
      final db = ref.read(appDatabaseProvider);
      loadedStudents = await (db.select(
        db.cachedStudents,
      )..where((t) => t.serviceId.equals(widget.serviceId))).get();
    } else {
      loadedStudents = await ref
          .read(studentRepositoryProvider)
          .watchStudentsForService(widget.serviceId)
          .first;
    }
    if (!mounted) return;
    role = isSuperAdmin ? 'system_admin' : profile?.role ?? '';
    if (role == 'class_leader' || role == 'class_servant') {
      scope = 'class';
      selectedClassId = profile?.classId;
      stageId = null;
    } else if (role == 'stage_leader') {
      scope = 'stage';
      stageId = profile?.stageId;
      selectedClassId = null;
    }
    final allowedStageId = role == 'stage_leader' ? profile?.stageId : null;
    stages = allowedStageId == null
        ? allStages
        : allStages.where((item) => item.id == allowedStageId).toList();
    classes = allowedStageId == null
        ? allClasses
        : allClasses.where((item) => item.stageId == allowedStageId).toList();
    students = loadedStudents
        .where(
          (item) =>
              item.currentClassId != null &&
              classes.any((c) => c.id == item.currentClassId),
        )
        .toList();
    setState(() => loading = false);
  }

  List<dynamic> get visibleClasses {
    if (stageId == null) return classes;
    return classes.where((item) => item.stageId == stageId).toList();
  }

  List<dynamic> get visibleStudents {
    if (selectedClassId == null) return const [];
    return students
        .where((item) => item.currentClassId == selectedClassId)
        .toList();
  }

  Future<void> _export() async {
    if ((scope == 'class' || scope == 'students') && selectedClassId == null) {
      return;
    }
    if (scope == 'students' && selectedStudentIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          graduationOnly ? 'تأكيد تصدير بيانات التخرج' : 'مراجعة التصدير',
        ),
        content: Text(
          'النطاق: ${scope == 'service'
              ? 'الخدمة بالكامل'
              : scope == 'stage'
              ? 'مرحلة'
              : scope == 'class'
              ? 'فصل'
              : 'تلاميذ محددون'}\n${graduationOnly ? 'سيحتوي الملف على بيانات التخرج الأساسية فقط.' : 'سيتم تجهيز ملف CSV للنطاق المحدد.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('رجوع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد وإنشاء الملف'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => exporting = true);
    try {
      final offlineEnabled = ref.read(offlineSyncEnabledProvider);
      String? effectiveStage = stageId;
      String? effectiveClass = selectedClassId;
      if (role == 'class_leader' || role == 'class_servant') {
        effectiveClass = selectedClassId;
        effectiveStage = null;
      } else if (role == 'stage_leader') {
        effectiveStage = stageId;
        effectiveClass = scope == 'class' || scope == 'students'
            ? selectedClassId
            : null;
      }

      if (offlineEnabled) {
        final repository = CsvExportRepository(ref.read(appDatabaseProvider));
        await repository.exportStudents(
          serviceId: widget.serviceId,
          stageId: scope == 'stage' ? effectiveStage : null,
          classId: scope == 'class' || scope == 'students'
              ? effectiveClass
              : null,
          studentIds: scope == 'students' ? selectedStudentIds : null,
          graduationOnly: graduationOnly,
        );
      } else {
        final repository = CsvExportRepository();
        await repository.exportStudentsFromData(
          serviceId: widget.serviceId,
          classes: classes,
          students: students,
          stageId: scope == 'stage' ? effectiveStage : null,
          classId: scope == 'class' || scope == 'students'
              ? effectiveClass
              : null,
          studentIds: scope == 'students' ? selectedStudentIds : null,
          graduationOnly: graduationOnly,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء ملف CSV بنجاح.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إنشاء الملف: ${NetworkErrorFormatter.format(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final canChooseService =
        role == 'system_admin' ||
        role == 'overall_leader' ||
        role == 'overall_helper';
    final scopeItems = <DropdownMenuItem<String>>[
      if (canChooseService)
        const DropdownMenuItem(value: 'service', child: Text('الخدمة بالكامل')),
      if (role == 'system_admin' ||
          role == 'overall_leader' ||
          role == 'overall_helper' ||
          role == 'stage_leader')
        const DropdownMenuItem(value: 'stage', child: Text('مرحلة')),
      const DropdownMenuItem(value: 'class', child: Text('فصل')),
      const DropdownMenuItem(value: 'students', child: Text('تلاميذ محددون')),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.graduationOnly ? 'تصدير بيانات التخرج' : 'التصدير'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: scope,
            decoration: const InputDecoration(labelText: 'النطاق'),
            items: scopeItems,
            onChanged: (value) => setState(() {
              scope = value!;
              selectedStudentIds = {};
            }),
          ),
          if (scope == 'stage')
            DropdownButtonFormField<String>(
              initialValue: stageId,
              decoration: const InputDecoration(labelText: 'المرحلة'),
              items: stages
                  .map(
                    (stage) => DropdownMenuItem(
                      value: stage.id as String,
                      child: Text(stage.name as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                stageId = value;
                selectedClassId = null;
                selectedStudentIds = {};
              }),
            ),
          if (scope == 'class' || scope == 'students')
            DropdownButtonFormField<String>(
              initialValue:
                  visibleClasses.any((item) => item.id == selectedClassId)
                  ? selectedClassId
                  : null,
              decoration: const InputDecoration(labelText: 'الفصل'),
              items: visibleClasses
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id as String,
                      child: Text(item.name as String),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                selectedClassId = value;
                selectedStudentIds = {};
              }),
            ),
          if (scope == 'students')
            ...visibleStudents.map(
              (student) => CheckboxListTile(
                value: selectedStudentIds.contains(student.id),
                title: Text(student.name as String),
                subtitle: Text(student.grade as String? ?? ''),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    selectedStudentIds.add(student.id as String);
                  } else {
                    selectedStudentIds.remove(student.id as String);
                  }
                }),
              ),
            ),
          if (!widget.graduationOnly)
            SwitchListTile(
              title: const Text('تصدير بيانات التخرج فقط'),
              subtitle: const Text(
                'بدون الحضور أو المتابعة أو البيانات الحساسة.',
              ),
              value: graduationOnly,
              onChanged: (value) => setState(() => graduationOnly = value),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: exporting ? null : _export,
            icon: const Icon(Icons.download),
            label: Text(exporting ? 'جاري التصدير...' : 'تصدير CSV'),
          ),
        ],
      ),
    );
  }
}
