// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_providers.dart';
import '../../../app/ui/app_ui.dart';
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
      body: AppContent(
        maxWidth: 900,
        child: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          final filtered = rows
              .where(
                (student) =>
                    student.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

          if (snapshot.connectionState == ConnectionState.waiting && rows.isEmpty) return const LoadingView(message: 'جاري تحميل التلاميذ...');
          if (rows.isEmpty) return const EmptyState(icon: Icons.school_outlined, title: 'لا يوجد تلاميذ في هذا الفصل', message: 'يمكنك تحديث البيانات عند توفر اتصال.');

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: TextField(
                  key: const Key('student_search'),
                  onChanged: (value) => setState(() => query = value.trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: 'بحث باسم التلميذ',
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح البحث',
                            onPressed: () => setState(() => query = ''),
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('${filtered.length} تلميذ', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(icon: Icons.search_off_rounded, title: 'لا توجد نتائج', message: 'جرّب اسمًا مختلفًا.')
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
                                  ? 'في انتظار الاعتماد'
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
      ),
    );
  }
}
