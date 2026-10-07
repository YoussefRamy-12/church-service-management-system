// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_providers.dart';
import '../../attendance/presentation/meeting_picker_page.dart';
import 'student_details_page.dart';

class ClassStudentsPage extends ConsumerStatefulWidget {
  const ClassStudentsPage({
    super.key,
    required this.classId,
    required this.className,
    required this.serviceId,
  });

  final String classId;
  final String className;
  final String serviceId;

  @override
  ConsumerState<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends ConsumerState<ClassStudentsPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final stream =
        ref.watch(studentRepositoryProvider).watchStudentsForClass(widget.classId);

    return Scaffold(
      key: const Key('students_class_page'),
      appBar: AppBar(
        title: Text(widget.className),
        actions: [
          IconButton(
            key: const Key('attendance_open'),
            icon: const Icon(Icons.fact_check),
            tooltip: 'الحضور',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MeetingPickerPage(
                  serviceId: widget.serviceId,
                  classId: widget.classId,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'مزامنة',
            onPressed: () =>
                ref.read(studentRepositoryProvider).refreshStudents(widget.classId),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          final filtered = rows
              .where(
                (student) =>
                    student.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

          if (rows.isEmpty) {
            return const Center(
              child: Text('لا يوجد تلاميذ محفوظون محليًا.'),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  key: const Key('student_search'),
                  onChanged: (value) => setState(() => query = value.trim()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'بحث باسم التلميذ',
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('لا توجد نتائج للبحث.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final student = filtered[index];
                          return ListTile(
                            key: Key('student_item_' + student.id),
                            leading: CircleAvatar(
                              child: Text(student.name.characters.first),
                            ),
                            title: Text(student.name),
                            subtitle: Text(
                              student.isPending
                                  ? 'Pending — يحتاج اعتماد'
                                  : (student.school ?? 'بدون مدرسة مسجلة'),
                            ),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentDetailsPage(student: student),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
