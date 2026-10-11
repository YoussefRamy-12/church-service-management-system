import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'student_providers.dart';

class AddStudentPage extends ConsumerStatefulWidget {
  const AddStudentPage({super.key, required this.serviceId, required this.classId, required this.className});
  final String serviceId;
  final String classId;
  final String className;

  @override
  ConsumerState<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends ConsumerState<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _school = TextEditingController();
  final _grade = TextEditingController();
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _school.dispose(); _grade.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(studentRegistrationProvider).registerPending(
        serviceId: widget.serviceId,
        proposedClassId: widget.classId,
        name: _name.text.trim(),
        birthDate: _birthDate,
        phone: _phone.text,
        school: _school.text,
        grade: _grade.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(const SnackBar(content: Text('تم حفظ التلميذ محليًا. أُضيف إلى قائمة انتظار الاعتماد والمزامنة.')));
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ التلميذ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إضافة تلميذ')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.all(24), children: [
        Card(child: ListTile(leading: const Icon(Icons.groups_outlined), title: const Text('الفصل المقترح'), subtitle: Text(widget.className))),
        const SizedBox(height: 16),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم التلميذ *', prefixIcon: Icon(Icons.person_outline)), validator: (value) => value == null || value.trim().isEmpty ? 'أدخل اسم التلميذ' : null, textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        TextFormField(controller: _school, decoration: const InputDecoration(labelText: 'المدرسة', prefixIcon: Icon(Icons.school_outlined)), textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        TextFormField(controller: _grade, decoration: const InputDecoration(labelText: 'الصف الدراسي', prefixIcon: Icon(Icons.menu_book_outlined)), textInputAction: TextInputAction.next),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('تاريخ الميلاد'),
          subtitle: Text(_birthDate == null ? 'اختياري' : DateFormat('yyyy-MM-dd').format(_birthDate!)),
          trailing: IconButton(tooltip: 'اختيار التاريخ', onPressed: () async {
            final now = DateTime.now();
            final value = await showDatePicker(context: context, initialDate: _birthDate ?? DateTime(now.year - 10), firstDate: DateTime(now.year - 30), lastDate: now);
            if (value != null) setState(() => _birthDate = value);
          }, icon: const Icon(Icons.edit_calendar_outlined)),
        ),
        const SizedBox(height: 12),
        const Text('سيظهر التلميذ بحالة «بانتظار الاعتماد» ويمكن استخدام النظام دون اتصال.'),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add_alt_1_rounded), label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ التلميذ')),
      ]),
    ))),
  );
}
