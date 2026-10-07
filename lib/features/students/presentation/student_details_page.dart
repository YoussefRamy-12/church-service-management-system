import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/entities/student.dart';
import 'student_providers.dart';
import '../../follow_up/presentation/follow_up_page.dart';
import '../../../app/ui/app_ui.dart';

class StudentDetailsPage extends ConsumerStatefulWidget {
  const StudentDetailsPage({super.key, required this.student});

  final Student student;

  @override
  ConsumerState<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends ConsumerState<StudentDetailsPage> {
  late Student student;

  @override
  void initState() {
    super.initState();
    student = widget.student;
  }

  bool _canApprove(String role) =>
      role == 'overall_leader' || role == 'overall_helper';

  String _date(DateTime? value) =>
      value == null ? 'غير محدد' : value.toLocal().toString().split(' ').first;

  Future<void> _approve() async {
    try {
      final updated =
          await ref.read(studentRepositoryProvider).approvePending(student.id);
      if (!mounted) return;
      setState(() => student = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اعتماد التلميذ محليًا وسيتم مزامنته.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اعتماد التلميذ: $error')),
      );
    }
  }

  Future<void> _edit() async {
    final result = await showDialog<StudentEditResult>(
      context: context,
      builder: (_) => StudentEditDialog(student: student),
    );
    if (result == null) return;

    try {
      final updated =
          await ref.read(studentRepositoryProvider).updateStudent(
                studentId: student.id,
                name: result.name,
                birthDate: result.birthDate,
                phone: result.phone,
                school: result.school,
                grade: result.grade,
                notes: result.notes,
              );
      if (!mounted) return;
      setState(() => student = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات محليًا وسيتم مزامنتها.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التعديلات: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
    final canApprove = profile != null && _canApprove(profile.role);

    return Scaffold(
      key: const Key('student_details'),
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(key: const Key('student_follow_up'), icon: const Icon(Icons.history), tooltip: 'المتابعة', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FollowUpPage(student: student)))),
          IconButton(
            key: const Key('student_edit'),
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل',
            onPressed: _edit,
          ),
        ],
      ),
      body: AppContent(maxWidth: 900, child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
        children: [
          if (student.isPending && canApprove)
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: const Text('التلميذ في انتظار الاعتماد'),
                subtitle: const Text('سيتم اعتماد الفصل المقترح كالفصل الحالي.'),
                trailing: FilledButton(
                  onPressed: _approve,
                  child: const Text('اعتماد'),
                ),
              ),
            ),
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
            _row('الحالة', student.isPending ? 'Pending — يحتاج اعتماد' : 'معتمد'),
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
            _row(
              'الصورة',
              student.photoPath == null ? 'لا توجد صورة' : 'صورة محفوظة',
            ),
          ]),
        ],
      )),
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

class StudentEditResult {
  const StudentEditResult({
    required this.name,
    required this.birthDate,
    required this.phone,
    required this.school,
    required this.grade,
    required this.notes,
  });

  final String name;
  final DateTime? birthDate;
  final String phone;
  final String school;
  final String grade;
  final String notes;
}

class StudentEditDialog extends StatefulWidget {
  const StudentEditDialog({super.key, required this.student});

  final Student student;

  @override
  State<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<StudentEditDialog> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController school;
  late final TextEditingController grade;
  late final TextEditingController notes;
  late DateTime? birthDate;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.student.name);
    phone = TextEditingController(text: widget.student.phone ?? '');
    school = TextEditingController(text: widget.student.school ?? '');
    grade = TextEditingController(text: widget.student.grade ?? '');
    notes = TextEditingController(text: widget.student.notes ?? '');
    birthDate = widget.student.birthDate;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    school.dispose();
    grade.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2013),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  String _date(DateTime? value) =>
      value == null ? 'غير محدد' : value.toLocal().toString().split(' ').first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل بيانات التلميذ'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              ),
              TextField(
                controller: school,
                decoration: const InputDecoration(labelText: 'المدرسة'),
              ),
              TextField(
                controller: grade,
                decoration: const InputDecoration(labelText: 'الصف الدراسي'),
              ),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تاريخ الميلاد: ${_date(birthDate)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: _pickBirthDate,
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
            if (name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              StudentEditResult(
                name: name.text,
                birthDate: birthDate,
                phone: phone.text,
                school: school.text,
                grade: grade.text,
                notes: notes.text,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
