import 'package:flutter/material.dart';
import '../../auth/domain/entities/servant_profile.dart';
import '../../service/domain/entities/service_class.dart';
import '../../service/domain/entities/stage.dart';

class ServantEditResult {
  const ServantEditResult({
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

class NewServantValues {
  const NewServantValues({
    required this.authUserId,
    required this.name,
    required this.phone,
    required this.role,
    this.stageId,
    this.classId,
  });
  final String authUserId;
  final String name;
  final String phone;
  final String role;
  final String? stageId;
  final String? classId;
}

class NewServantDialog extends StatefulWidget {
  const NewServantDialog({super.key, required this.stages, required this.classes});
  final List<Stage> stages;
  final List<ServiceClass> classes;

  @override
  State<NewServantDialog> createState() => NewServantDialogState();
}

class NewServantDialogState extends State<NewServantDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _authId = TextEditingController();
  String role = 'class_servant';
  String? stageId;
  String? classId;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _authId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classes = stageId == null
        ? widget.classes
        : widget.classes.where((item) => item.stageId == stageId).toList();
    return AlertDialog(
      title: const Text('إضافة خادم للخدمة'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'يجب أن يكون للخادم حساب مسجل مسبقًا. أدخل معرّف مستخدم Auth لربط الحساب بهذا الدور.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _authId,
                decoration: const InputDecoration(
                  labelText: 'معرّف مستخدم Auth *',
                ),
              ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم الخادم *'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
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
                onChanged: (value) => setState(() {
                  role = value ?? role;
                  if (role != 'stage_leader') stageId = null;
                  if (role != 'class_leader' && role != 'class_servant') {
                    classId = null;
                  }
                }),
              ),
              if (role == 'stage_leader')
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  decoration: const InputDecoration(labelText: 'المرحلة'),
                  items: widget.stages
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    stageId = value;
                    classId = null;
                  }),
                ),
              if (role == 'class_leader' || role == 'class_servant') ...[
                DropdownButtonFormField<String>(
                  initialValue: stageId,
                  decoration: const InputDecoration(
                    labelText: 'تصفية حسب المرحلة (اختياري)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('كل المراحل'),
                    ),
                    ...widget.stages.map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    stageId = value;
                    classId = null;
                  }),
                ),
                DropdownButtonFormField<String>(
                  initialValue: classes.any((item) => item.id == classId)
                      ? classId
                      : null,
                  decoration: const InputDecoration(labelText: 'الفصل'),
                  items: classes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => classId = value),
                ),
              ],
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
            final authId = _authId.text.trim();
            final name = _name.text.trim();
            if (authId.isEmpty || name.isEmpty) return;
            if (role == 'stage_leader' && stageId == null) return;
            if ((role == 'class_leader' || role == 'class_servant') &&
                classId == null) {
              return;
            }
            Navigator.pop(
              context,
              NewServantValues(
                authUserId: authId,
                name: name,
                phone: _phone.text.trim(),
                role: role,
                stageId: role == 'stage_leader' ? stageId : null,
                classId: role == 'class_leader' || role == 'class_servant'
                    ? classId
                    : null,
              ),
            );
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}

class ServantEditDialog extends StatefulWidget {
  const ServantEditDialog({
    super.key,
    required this.servant,
    required this.stages,
    required this.classes,
  });

  final ServantProfile servant;
  final List<Stage> stages;
  final List<ServiceClass> classes;

  @override
  State<ServantEditDialog> createState() => ServantEditDialogState();
}

class ServantEditDialogState extends State<ServantEditDialog> {
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
                  initialValue:
                      availableClasses.any((item) => item.id == classId)
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
                  DropdownMenuItem(value: 'pending', child: Text('معلق')),
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
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
              ServantEditResult(
                name: name.text.trim(),
                phone: phone.text.trim(),
                birthDate: birthDate,
                workStudy: workStudy.text.trim(),
                role: role,
                stageId: role == 'stage_leader' ? stageId : null,
                classId: role == 'class_leader' || role == 'class_servant'
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
