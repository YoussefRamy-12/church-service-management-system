import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../data/csv_export_repository.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key, required this.serviceId, this.classId});
  final String serviceId;
  final String? classId;
  @override ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  String scope = 'service';
  bool graduationOnly = false;
  String? stageId;
  String? selectedClassId;
  Set<String> selectedStudentIds = {};
  bool exporting = false;
  bool loading = true;
  List<dynamic> stages = [];
  List<dynamic> classes = [];
  List<dynamic> students = [];
  String role = '';

  @override void initState() { super.initState(); selectedClassId = widget.classId; Future.microtask(_load); }

  Future<void> _load() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    final db = ref.read(appDatabaseProvider);
    final allStages = await ref.read(serviceRepositoryProvider).local.getStages(widget.serviceId);
    final allClasses = <dynamic>[];
    for (final stage in allStages) {
      allClasses.addAll(await ref.read(serviceRepositoryProvider).local.getClasses(stage.id));
    }
    final cachedStudents = await (db.select(db.cachedStudents)..where((t) => t.serviceId.equals(widget.serviceId))).get();
    if (!mounted) return;
    role = profile?.role ?? '';
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
    stages = allowedStageId == null ? allStages : allStages.where((item) => item.id == allowedStageId).toList();
    classes = allowedStageId == null ? allClasses : allClasses.where((item) => item.stageId == allowedStageId).toList();
    students = cachedStudents.where((item) => item.currentClassId != null && classes.any((c) => c.id == item.currentClassId)).toList();
    setState(() => loading = false);
  }

  List<dynamic> get visibleClasses {
    if (stageId == null) return classes;
    return classes.where((item) => item.stageId == stageId).toList();
  }

  List<dynamic> get visibleStudents {
    if (selectedClassId == null) return const [];
    return students.where((item) => item.currentClassId == selectedClassId).toList();
  }

  Future<void> _export() async {
    if ((scope == 'class' || scope == 'students') && selectedClassId == null) return;
    if (scope == 'students' && selectedStudentIds.isEmpty) return;
    setState(() => exporting = true);
    try {
      final repository = CsvExportRepository(ref.read(appDatabaseProvider));
      String? effectiveStage = stageId;
      String? effectiveClass = selectedClassId;
      if (role == 'class_leader' || role == 'class_servant') {
        effectiveClass = selectedClassId;
        effectiveStage = null;
      } else if (role == 'stage_leader') {
        effectiveStage = stageId;
        effectiveClass = scope == 'class' || scope == 'students' ? selectedClassId : null;
      }
      await repository.exportStudents(
        serviceId: widget.serviceId,
        stageId: scope == 'stage' ? effectiveStage : null,
        classId: scope == 'class' || scope == 'students' ? effectiveClass : null,
        studentIds: scope == 'students' ? selectedStudentIds : null,
        graduationOnly: graduationOnly,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء ملف CSV بنجاح.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الملف: $error')));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final canChooseService = role == 'overall_leader' || role == 'overall_helper';
    final scopeItems = <DropdownMenuItem<String>>[
      if (canChooseService) const DropdownMenuItem(value: 'service', child: Text('الخدمة بالكامل')),
      if (role == 'overall_leader' || role == 'overall_helper' || role == 'stage_leader') const DropdownMenuItem(value: 'stage', child: Text('مرحلة')),
      const DropdownMenuItem(value: 'class', child: Text('فصل')),
      const DropdownMenuItem(value: 'students', child: Text('تلاميذ محددون')),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('التصدير')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        DropdownButtonFormField<String>(
          initialValue: scope,
          decoration: const InputDecoration(labelText: 'النطاق'),
          items: scopeItems,
          onChanged: (value) => setState(() { scope = value!; selectedStudentIds = {}; }),
        ),
        if (scope == 'stage') DropdownButtonFormField<String>(
          initialValue: stageId,
          decoration: const InputDecoration(labelText: 'المرحلة'),
          items: stages.map((stage) => DropdownMenuItem(value: stage.id as String, child: Text(stage.name as String))).toList(),
          onChanged: (value) => setState(() { stageId = value; selectedClassId = null; selectedStudentIds = {}; }),
        ),
        if (scope == 'class' || scope == 'students') DropdownButtonFormField<String>(
          initialValue: visibleClasses.any((item) => item.id == selectedClassId) ? selectedClassId : null,
          decoration: const InputDecoration(labelText: 'الفصل'),
          items: visibleClasses.map((item) => DropdownMenuItem(value: item.id as String, child: Text(item.name as String))).toList(),
          onChanged: (value) => setState(() { selectedClassId = value; selectedStudentIds = {}; }),
        ),
        if (scope == 'students') ...visibleStudents.map((student) => CheckboxListTile(
          value: selectedStudentIds.contains(student.id),
          title: Text(student.name as String),
          subtitle: Text(student.grade as String? ?? ''),
          onChanged: (value) => setState(() {
            if (value == true) { selectedStudentIds.add(student.id as String); } else { selectedStudentIds.remove(student.id as String); }
          }),
        )),
        SwitchListTile(
          title: const Text('تصدير بيانات التخرج فقط'),
          subtitle: const Text('بدون الحضور أو المتابعة أو البيانات الحساسة.'),
          value: graduationOnly,
          onChanged: (value) => setState(() => graduationOnly = value),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: exporting ? null : _export,
          icon: const Icon(Icons.download),
          label: Text(exporting ? 'جاري التصدير...' : 'تصدير CSV'),
        ),
      ]),
    );
  }
}