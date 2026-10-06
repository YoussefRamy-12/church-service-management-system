import 'package:flutter/material.dart';
import '../domain/entities/student.dart';

class StudentDetailsPage extends StatelessWidget {
  const StudentDetailsPage({super.key, required this.student});
  final Student student;

  String _date(DateTime? value) =>
      value == null ? 'غير محدد' : value.toLocal().toString().split(' ').first;

  @override
  Widget build(BuildContext context) {
    final pending = student.isPending;
    return Scaffold(
      appBar: AppBar(title: Text(student.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              child: Text(
                student.name.characters.first,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _section(context, 'البيانات الأساسية', [
            _row('الاسم', student.name),
            _row('الحالة', pending ? 'Pending — يحتاج اعتماد' : 'معتمد'),
            _row('تاريخ الميلاد', _date(student.birthDate)),
            _row('تاريخ الالتحاق', _date(student.enrollmentAt)),
            _row('رقم الهاتف', student.phone ?? 'غير محدد'),
          ]),
          _section(context, 'الدراسة', [
            _row('المدرسة', student.school ?? 'غير محددة'),
            _row('الصف الدراسي', student.grade ?? 'غير محدد'),
          ]),
          _section(context, 'معلومات إضافية', [
            _row('ملاحظات', student.notes ?? 'لا توجد ملاحظات'),
            _row('الصورة', student.photoPath == null ? 'لا توجد صورة' : 'صورة محفوظة'),
          ]),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
