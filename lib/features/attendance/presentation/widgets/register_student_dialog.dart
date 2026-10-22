import 'package:flutter/material.dart';

@immutable
class NewStudentDetails {
  const NewStudentDetails({
    required this.name,
    required this.phone,
    required this.school,
    required this.grade,
    required this.birthDate,
  });

  final String name;
  final String? phone;
  final String? school;
  final String? grade;
  final DateTime? birthDate;
}

class RegisterStudentDialog extends StatefulWidget {
  const RegisterStudentDialog({super.key});

  @override
  State<RegisterStudentDialog> createState() => _RegisterStudentDialogState();
}

class _RegisterStudentDialogState extends State<RegisterStudentDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _school = TextEditingController();
  final _grade = TextEditingController();
  DateTime? _birthDate;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _school.dispose();
    _grade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('تسجيل تلميذ جديد'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'اسم التلميذ *'),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
          ),
          TextField(
            controller: _school,
            decoration: const InputDecoration(labelText: 'المدرسة'),
          ),
          TextField(
            controller: _grade,
            decoration: const InputDecoration(labelText: 'الصف الدراسي'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _birthDate == null
                  ? 'تاريخ الميلاد: غير محدد'
                  : 'تاريخ الميلاد: ${_birthDate!.toLocal().toString().split(' ').first}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2015, 1, 1),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                helpText: 'اختر تاريخ الميلاد',
              );
              if (picked != null && mounted) {
                setState(() => _birthDate = picked);
              }
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _name.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                context,
                NewStudentDetails(
                  name: _name.text.trim(),
                  phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                  school: _school.text.trim().isEmpty
                      ? null
                      : _school.text.trim(),
                  grade: _grade.text.trim().isEmpty ? null : _grade.text.trim(),
                  birthDate: _birthDate,
                ),
              ),
        child: const Text('تسجيل'),
      ),
    ],
  );
}
