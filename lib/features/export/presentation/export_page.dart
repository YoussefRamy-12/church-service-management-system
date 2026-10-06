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

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  String scope = 'service';
  bool graduationOnly = false;
  String? stageId;
  String? selectedClassId;
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    selectedClassId = widget.classId;
    Future.microtask(_loadDefaults);
  }

  Future<void> _loadDefaults() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    if (!mounted) return;
    if (profile?.role == 'class_leader' || profile?.role == 'class_servant') {
      setState(() {
        scope = 'class';
        selectedClassId = profile?.classId;
      });
    } else if (profile?.role == 'stage_leader') {
      setState(() {
        scope = 'stage';
        stageId = profile?.stageId;
      });
    }
  }

  Future<void> _export() async {
    setState(() => exporting = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final repository = CsvExportRepository(db);
      final profile = await ref.read(currentServantProfileProvider.future);

      String? effectiveStage = stageId;
      String? effectiveClass = selectedClassId;
      if (profile?.role == 'class_leader' || profile?.role == 'class_servant') {
        effectiveClass = profile?.classId;
        effectiveStage = null;
      } else if (profile?.role == 'stage_leader') {
        effectiveStage = profile?.stageId;
        effectiveClass = scope == 'class' ? selectedClassId : null;
      }

      await repository.exportStudents(
        serviceId: widget.serviceId,
        stageId: scope == 'stage' ? effectiveStage : null,
        classId: scope == 'class' ? effectiveClass : null,
        graduationOnly: graduationOnly,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء ملف CSV بنجاح.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء الملف: $error')),
      );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التصدير')),
      body: FutureBuilder(
        future: ref.read(serviceRepositoryProvider).local.getStages(widget.serviceId),
        builder: (context, snapshot) {
          final stages = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<String>(
                initialValue: scope,
                decoration: const InputDecoration(labelText: 'النطاق'),
                items: const [
                  DropdownMenuItem(value: 'service', child: Text('الخدمة بالكامل')),
                  DropdownMenuItem(value: 'stage', child: Text('مرحلة')),
                  DropdownMenuItem(value: 'class', child: Text('فصل')),
                ],
                onChanged: (value) => setState(() => scope = value!),
              ),
              if (scope == 'stage')
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  decoration: const InputDecoration(labelText: 'المرحلة'),
                  items: stages.map((stage) => DropdownMenuItem(
                    value: stage.id, child: Text(stage.name),
                  )).toList(),
                  onChanged: (value) => setState(() => stageId = value),
                ),
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
            ],
          );
        },
      ),
    );
  }
}
