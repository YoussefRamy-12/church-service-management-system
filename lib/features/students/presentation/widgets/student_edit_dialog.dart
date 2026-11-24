import 'package:flutter/material.dart';

import '../../domain/entities/sensitive_student_data.dart';
import '../../domain/entities/student.dart';

class StudentEditResult {
  const StudentEditResult({
    required this.name,
    required this.birthDate,
    required this.phone,
    required this.school,
    required this.grade,
    required this.isDeacon,
    required this.enrollmentAt,
    required this.photoPath,
    required this.notes,
    this.sensitiveData,
  });

  final String name;
  final DateTime? birthDate;
  final String? phone;
  final String? school;
  final String? grade;
  final bool isDeacon;
  final DateTime? enrollmentAt;
  final String? photoPath;
  final String? notes;
  final SensitiveStudentData? sensitiveData;
}

class StudentEditDialog extends StatefulWidget {
  const StudentEditDialog({
    super.key,
    required this.student,
    this.sensitiveData,
    this.onDelete,
  });

  final Student student;
  final SensitiveStudentData? sensitiveData;
  final VoidCallback? onDelete;

  @override
  State<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<StudentEditDialog> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController school;
  late final TextEditingController notes;
  late bool isDeacon;
  late DateTime? birthDate;

  // Address
  late final TextEditingController addressBuilding;
  late final TextEditingController addressStreet;
  late final TextEditingController addressFloor;
  late final TextEditingController addressApartment;

  // Family
  late final TextEditingController fatherJob;
  late final TextEditingController fatherPhone;
  late final TextEditingController motherName;
  late final TextEditingController motherJob;
  late final TextEditingController motherPhone;
  late final TextEditingController familySize;
  late final TextEditingController birthOrder;

  // Pastoral & Sensitive
  late final TextEditingController confessor;
  late final TextEditingController medicalNotes;
  String? financialStatus;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.student.name);
    phone = TextEditingController(text: widget.student.phone ?? '');
    school = TextEditingController(text: widget.student.school ?? '');
    notes = TextEditingController(text: widget.student.notes ?? '');
    isDeacon = widget.student.isDeacon;
    birthDate = widget.student.birthDate;

    final s = widget.sensitiveData;
    addressBuilding = TextEditingController(text: s?.addressBuilding ?? '');
    addressStreet = TextEditingController(text: s?.addressStreet ?? '');
    addressFloor = TextEditingController(text: s?.addressFloor ?? '');
    addressApartment = TextEditingController(text: s?.addressApartment ?? '');

    fatherJob = TextEditingController(text: s?.fatherJob ?? '');
    fatherPhone = TextEditingController(text: s?.effectiveFatherPhone ?? '');
    motherName = TextEditingController(text: s?.motherName ?? '');
    motherJob = TextEditingController(text: s?.motherJob ?? '');
    motherPhone = TextEditingController(text: s?.effectiveMotherPhone ?? '');
    familySize = TextEditingController(text: s?.familySize?.toString() ?? '');
    birthOrder = TextEditingController(text: s?.birthOrder?.toString() ?? '');

    confessor = TextEditingController(text: s?.confessor ?? '');
    medicalNotes = TextEditingController(text: s?.medicalNotes ?? '');
    financialStatus = s?.financialStatus;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    school.dispose();
    notes.dispose();
    addressBuilding.dispose();
    addressStreet.dispose();
    addressFloor.dispose();
    addressApartment.dispose();
    fatherJob.dispose();
    fatherPhone.dispose();
    motherName.dispose();
    motherJob.dispose();
    motherPhone.dispose();
    familySize.dispose();
    birthOrder.dispose();
    confessor.dispose();
    medicalNotes.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2013),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  String _date(DateTime? value) =>
      value == null ? 'غير محدد' : value.toLocal().toString().split(' ').first;

  bool get _canEditGlobalIdentity =>
      widget.student.identityServiceId != null &&
      widget.student.serviceId == widget.student.identityServiceId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'تعديل بيانات التلميذ',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_canEditGlobalIdentity)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'البيانات الشخصية والحساسة مشتركة وتُدار من الخدمة المالكة للهوية. يمكنك تعديل بيانات العضوية الخاصة بهذه الخدمة فقط.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              const Text(
                'البيانات الأساسية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: name,
                readOnly: !_canEditGlobalIdentity,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل للطالب *',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تاريخ الميلاد: ${_date(birthDate)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: _canEditGlobalIdentity ? _pickBirthDate : null,
                ),
              ),
              TextField(
                controller: phone,
                readOnly: !_canEditGlobalIdentity,
                decoration: const InputDecoration(labelText: 'تليفون الطالب'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: school,
                decoration: const InputDecoration(labelText: 'المدرسة'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('شماس'),
                value: isDeacon,
                onChanged: (val) => setState(() => isDeacon = val),
              ),

              const Divider(height: 28),
              const Text(
                'العنوان',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addressBuilding,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(
                        labelText: 'رقم العقار',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: addressStreet,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(labelText: 'شارع'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addressFloor,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(labelText: 'دور'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: addressApartment,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(labelText: 'شقة'),
                    ),
                  ),
                ],
              ),

              const Divider(height: 28),
              const Text(
                'بيانات الأسرة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fatherJob,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(
                        labelText: 'وظيفة الأب',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatherPhone,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(
                        labelText: 'تليفون الأب',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: motherName,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(labelText: 'اسم الأم'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: motherJob,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(
                        labelText: 'وظيفة الأم',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motherPhone,
                readOnly: !_canEditGlobalIdentity,
                decoration: const InputDecoration(labelText: 'تليفون الأم'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: familySize,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(
                        labelText: 'عدد أفراد الأسرة',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: birthOrder,
                      readOnly: !_canEditGlobalIdentity,
                      decoration: const InputDecoration(
                        labelText: 'ترتيب الطالب بين إخوته',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const Divider(height: 28),
              const Text(
                'بيانات الخدمة والرعاية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confessor,
                readOnly: !_canEditGlobalIdentity,
                decoration: const InputDecoration(labelText: 'أب الاعتراف'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: medicalNotes,
                readOnly: !_canEditGlobalIdentity,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات صحية أو حساسية',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: financialStatus,
                decoration: const InputDecoration(
                  labelText: 'الحالة المادية للأسرة',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('غير محدد')),
                  DropdownMenuItem(
                    value: FinancialStatus.natural,
                    child: Text(FinancialStatus.natural),
                  ),
                  DropdownMenuItem(
                    value: FinancialStatus.brothersOfLord,
                    child: Text(FinancialStatus.brothersOfLord),
                  ),
                  DropdownMenuItem(
                    value: FinancialStatus.hiddenFamily,
                    child: Text(FinancialStatus.hiddenFamily),
                  ),
                ],
                onChanged: _canEditGlobalIdentity
                    ? (val) => setState(() => financialStatus = val)
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات عامة'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton.icon(
            key: const Key('student_dialog_archive'),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete!();
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            label: const Text(
              'أرشفة عضوية التلميذ',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty) return;

            final famSize = int.tryParse(familySize.text.trim());
            final bOrder = int.tryParse(birthOrder.text.trim());
            final validationError =
                SensitiveStudentData.validateFamilyAndFinance(
                  familySize: famSize,
                  birthOrder: bOrder,
                  financialStatus: financialStatus,
                );

            if (validationError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(validationError),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
              return;
            }

            final updatedSensitive = SensitiveStudentData(
              studentId: widget.student.id,
              fatherJob: fatherJob.text.trim().isEmpty
                  ? null
                  : fatherJob.text.trim(),
              fatherPhone: fatherPhone.text.trim().isEmpty
                  ? null
                  : fatherPhone.text.trim(),
              motherName: motherName.text.trim().isEmpty
                  ? null
                  : motherName.text.trim(),
              motherJob: motherJob.text.trim().isEmpty
                  ? null
                  : motherJob.text.trim(),
              motherPhone: motherPhone.text.trim().isEmpty
                  ? null
                  : motherPhone.text.trim(),
              familySize: famSize,
              birthOrder: bOrder,
              confessor: confessor.text.trim().isEmpty
                  ? null
                  : confessor.text.trim(),
              medicalNotes: medicalNotes.text.trim().isEmpty
                  ? null
                  : medicalNotes.text.trim(),
              financialStatus: financialStatus,
              addressBuilding: addressBuilding.text.trim().isEmpty
                  ? null
                  : addressBuilding.text.trim(),
              addressStreet: addressStreet.text.trim().isEmpty
                  ? null
                  : addressStreet.text.trim(),
              addressFloor: addressFloor.text.trim().isEmpty
                  ? null
                  : addressFloor.text.trim(),
              addressApartment: addressApartment.text.trim().isEmpty
                  ? null
                  : addressApartment.text.trim(),
              studyYear: widget.sensitiveData?.studyYear,
            );

            Navigator.pop(
              context,
              StudentEditResult(
                name: name.text.trim(),
                birthDate: birthDate,
                phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                school: school.text.trim().isEmpty ? null : school.text.trim(),
                grade: widget.student.grade,
                isDeacon: isDeacon,
                enrollmentAt: widget.student.enrollmentAt,
                photoPath: widget.student.photoPath,
                notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                sensitiveData: updatedSensitive,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

