import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/entities/servant_profile.dart';
import '../../service/domain/entities/service_class.dart';
import '../../service/domain/entities/stage.dart';
import '../../service/presentation/service_providers.dart';
import 'servant_providers.dart';

class ServantManagementPage extends ConsumerStatefulWidget {
  const ServantManagementPage({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<ServantManagementPage> createState() =>
      _ServantManagementPageState();
}

class _ServantManagementPageState
    extends ConsumerState<ServantManagementPage> {
  String search = '';
  String statusFilter = 'all';
  List<Stage> stages = [];
  List<ServiceClass> classes = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadHierarchy);
  }

  Future<void> _loadHierarchy() async {
    final service = ref.read(serviceRepositoryProvider);
    try {
      await service.refreshStages(widget.serviceId);
      final localStages = await service.local.getStages(widget.serviceId);
      for (final stage in localStages) {
        await service.refreshClasses(stage.id);
      }
      final localClasses = <ServiceClass>[];
      for (final stage in localStages) {
        localClasses.addAll(await service.local.getClasses(stage.id));
      }
      if (!mounted) return;
      setState(() {
        stages = localStages;
        classes = localClasses;
      });
    } catch (_) {
      final localStages = await service.local.getStages(widget.serviceId);
      final localClasses = <ServiceClass>[];
      for (final stage in localStages) {
        localClasses.addAll(await service.local.getClasses(stage.id));
      }
      if (!mounted) return;
      setState(() {
        stages = localStages;
        classes = localClasses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(servantRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الخدام'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () async {
              await repository.refresh(widget.serviceId);
              await _loadHierarchy();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: StreamBuilder<List<ServantProfile>>(
        stream: repository.watchForService(widget.serviceId),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <ServantProfile>[];
          final filtered = all.where((servant) {
            final matchesSearch = search.trim().isEmpty ||
                servant.name.contains(search.trim()) ||
                (servant.phone ?? '').contains(search.trim());
            final matchesStatus =
                statusFilter == 'all' || servant.accountStatus == statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'الخدام',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'بحث بالاسم أو الهاتف',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => search = value),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('الكل')),
                  ButtonSegment(value: 'pending', label: Text('معلق')),
                  ButtonSegment(value: 'active', label: Text('نشط')),
                  ButtonSegment(value: 'inactive', label: Text('غير نشط')),
                ],
                selected: {statusFilter},
                onSelectionChanged: (value) =>
                    setState(() => statusFilter = value.first),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('لا توجد بيانات مطابقة.')),
                ),
              ...filtered.map(
                (servant) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        servant.name.isEmpty ? '?' : servant.name.substring(0, 1),
                      ),
                    ),
                    title: Text(servant.name),
                    subtitle: Text(
                      '${_roleLabel(servant.role)} • ${_statusLabel(servant.accountStatus)}'
                      '${servant.phone == null ? '' : ' • ${servant.phone}'}',
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _openEditor(servant),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(ServantProfile servant) async {
    final result = await showDialog<_ServantEditResult>(
      context: context,
      builder: (_) => _ServantEditDialog(
        servant: servant,
        stages: stages,
        classes: classes,
      ),
    );

    if (result == null) return;

    try {
      await ref.read(servantRepositoryProvider).updateProfile(
            servantId: servant.id,
            name: result.name,
            phone: result.phone,
            birthDate: result.birthDate,
            workStudy: result.workStudy,
            role: result.role,
            stageId: result.stageId,
            classId: result.classId,
            accountStatus: result.accountStatus,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديل محليًا وسيتم مزامنته.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التعديل: $error')),
      );
    }
  }

  String _roleLabel(String role) => switch (role) {
        'overall_leader' => 'أمين الخدمة',
        'overall_helper' => 'أمين مساعد',
        'stage_leader' => 'أمين المرحلة',
        'class_leader' => 'أمين الفصل',
        'class_servant' => 'خادم الفصل',
        _ => role,
      };

  String _statusLabel(String status) => switch (status) {
        'pending' => 'معلق',
        'active' => 'نشط',
        'inactive' => 'غير نشط',
        _ => status,
      };
}

class _ServantEditResult {
  const _ServantEditResult({
    required this.name,
    required this.phone,
    required this.birthDate,
    required this.workStudy,
    required this.role,
    required this.stageId,
    required this.classId,
    required this.accountStatus,
  });

  final String name;
  final String phone;
  final DateTime birthDate;
  final String workStudy;
  final String role;
  final String? stageId;
  final String? classId;
  final String accountStatus;
}

class _ServantEditDialog extends StatefulWidget {
  const _ServantEditDialog({
    required this.servant,
    required this.stages,
    required this.classes,
  });

  final ServantProfile servant;
  final List<Stage> stages;
  final List<ServiceClass> classes;

  @override
  State<_ServantEditDialog> createState() => _ServantEditDialogState();
}

class _ServantEditDialogState extends State<_ServantEditDialog> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController workStudy;
  late String role;
  late String status;
  late DateTime birthDate;
  String? stageId;
  String? classId;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.servant.name);
    phone = TextEditingController(text: widget.servant.phone ?? '');
    workStudy = TextEditingController(text: widget.servant.workStudy ?? '');
    role = widget.servant.role;
    status = widget.servant.accountStatus;
    birthDate = widget.servant.birthDate ?? DateTime(2000, 1, 1);
    stageId = widget.servant.stageId;
    classId = widget.servant.classId;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    workStudy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableClasses = stageId == null
        ? widget.classes
        : widget.classes.where((item) => item.stageId == stageId).toList();

    return AlertDialog(
      title: Text(widget.servant.isPending ? 'اعتماد خادم' : 'بيانات الخادم'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              TextField(
                controller: workStudy,
                decoration: const InputDecoration(labelText: 'الدراسة / العمل'),
              ),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'الدور'),
                items: const [
                  DropdownMenuItem(
                    value: 'overall_leader',
                    child: Text('أمين الخدمة'),
                  ),
                  DropdownMenuItem(
                    value: 'overall_helper',
                    child: Text('أمين مساعد'),
                  ),
                  DropdownMenuItem(
                    value: 'stage_leader',
                    child: Text('أمين المرحلة'),
                  ),
                  DropdownMenuItem(
                    value: 'class_leader',
                    child: Text('أمين الفصل'),
                  ),
                  DropdownMenuItem(
                    value: 'class_servant',
                    child: Text('خادم الفصل'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    role = value;
                    if (role == 'overall_leader' || role == 'overall_helper') {
                      stageId = null;
                      classId = null;
                    } else if (role == 'stage_leader') {
                      classId = null;
                    } else {
                      stageId = null;
                    }
                  });
                },
              ),
              if (role == 'stage_leader')
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  decoration: const InputDecoration(labelText: 'المرحلة'),
                  items: widget.stages
                      .map(
                        (stage) => DropdownMenuItem(
                          value: stage.id,
                          child: Text(stage.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    stageId = value;
                    classId = null;
                  }),
                ),
              if (role == 'class_leader' || role == 'class_servant')
                DropdownButtonFormField<String>(
                  initialValue: availableClasses.any((item) => item.id == classId)
                      ? classId
                      : null,
                  decoration: const InputDecoration(labelText: 'الفصل'),
                  items: availableClasses
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => classId = value),
                ),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'حالة الحساب'),
                items: const [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('معلق'),
                  ),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('نشط'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('غير نشط'),
                  ),
                ],
                onChanged: (value) => setState(() => status = value!),
              ),
              ListTile(
                title: Text(
                  'تاريخ الميلاد: ${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: birthDate,
                      firstDate: DateTime(1940),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null && context.mounted) {
                      setState(() => birthDate = selected);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty ||
                phone.text.trim().isEmpty ||
                workStudy.text.trim().isEmpty) {
              return;
            }
            if (role == 'stage_leader' && stageId == null) return;
            if ((role == 'class_leader' || role == 'class_servant') &&
                classId == null) {
              return;
            }

            Navigator.pop(
              context,
              _ServantEditResult(
                name: name.text.trim(),
                phone: phone.text.trim(),
                birthDate: birthDate,
                workStudy: workStudy.text.trim(),
                role: role,
                stageId: role == 'stage_leader' ? stageId : null,
                classId:
                    role == 'class_leader' || role == 'class_servant'
                        ? classId
                        : null,
                accountStatus: status,
              ),
            );
          },
          child: Text(widget.servant.isPending ? 'اعتماد وحفظ' : 'حفظ'),
        ),
      ],
    );
  }
}
