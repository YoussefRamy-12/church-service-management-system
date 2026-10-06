import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/student.dart';
import '../../auth/presentation/auth_providers.dart';
import 'student_providers.dart';

class StudentDetailsPage extends ConsumerStatefulWidget {
  const StudentDetailsPage({super.key, required this.student});
  final Student student;

  @override
  ConsumerState<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends ConsumerState<StudentDetailsPage> {
  late Student student;
  @override void initState() { super.initState(); student = widget.student; }
  String _date(DateTime? value) =>
      value == null ? 'غير محدد' : value.toLocal().toString().split(' ').first;

  Future<void> _approve() async {
    final updated = await ref.read(studentRepositoryProvider).approvePending(student.id);
    if (!mounted) return; setState(() => student = updated);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentServantProfileProvider).valueOrNull;
    final canApprove = profile != null && (profile.role == 'overall_leader' || profile.role == 'overall_helper');
    final pending = student.isPending;
    return Scaffold(
      appBar: AppBar(title: Text(student.name), actions: [IconButton(icon: const Icon(Icons.edit), onPressed: () async {
        final name = TextEditingController(text: student.name);
        final phone = TextEditingController(text: student.phone ?? '');
        final school = TextEditingController(text: student.school ?? '');
        final grade = TextEditingController(text: student.grade ?? '');
        final notes = TextEditingController(text: student.notes ?? '');
        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('تعديل بيانات التلميذ'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')), TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')), TextField(controller: school, decoration: const InputDecoration(labelText: 'المدرسة')), TextField(controller: grade, decoration: const InputDecoration(labelText: 'الصف')), TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'ملاحظات'))])), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty) return; await ref.read(studentRepositoryProvider).updateStudent(studentId: student.id, name: name.text, birthDate: student.birthDate, phone: phone.text, school: school.text, grade: grade.text, notes: notes.text); if (context.mounted) Navigator.pop(context, true); }, child: const Text('حفظ'))]));
        name.dispose(); phone.dispose(); school.dispose(); grade.dispose(); notes.dispose();
        if (ok == true && mounted) setState(() {});
      })]),
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
          if (pending && canApprove) Card(child: ListTile(title: const Text('التلميذ في انتظار الاعتماد'), trailing: FilledButton(onPressed: _approve, child: const Text('اعتماد')))),
          _section(context, 'البيانات الأساسية',
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
