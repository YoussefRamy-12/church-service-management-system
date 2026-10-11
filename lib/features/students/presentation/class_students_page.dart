// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_providers.dart';
import '../../../app/ui/app_ui.dart';
import '../../attendance/presentation/meeting_picker_page.dart';
import 'student_details_page.dart';
import 'add_student_page.dart';

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
  String statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try { await ref.read(studentRepositoryProvider).refreshStudents(widget.classId); } catch (_) { /* Keep showing the local offline cache. */ }
    });
  }

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
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('student_add'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(
          builder: (_) => AddStudentPage(serviceId: widget.serviceId, classId: widget.classId, className: widget.className),
        )),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إضافة تلميذ'),
      ),
      body: AppContent(
        maxWidth: 900,
        child: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          if (snapshot.connectionState == ConnectionState.waiting && rows.isEmpty) return const LoadingView(message: 'جاري تحميل التلاميذ...');
          if (snapshot.hasError && rows.isEmpty) return EmptyState(icon: Icons.cloud_off_rounded, title: 'تعذر تحميل التلاميذ', message: 'تحقق من الاتصال أو حاول مجددًا.', action: OutlinedButton.icon(onPressed: () => ref.read(studentRepositoryProvider).refreshStudents(widget.classId), icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')));
          if (rows.isEmpty) return const EmptyState(icon: Icons.school_outlined, title: 'لا يوجد تلاميذ في هذا الفصل', message: 'يمكنك تحديث البيانات عند توفر اتصال.');

          final statusRows = rows.where((student) => switch (statusFilter) {
            'pending' => student.isPending,
            'approved' => student.isApproved,
            _ => true,
          }).toList();
          final filteredRows = statusRows.where((student) => student.name.toLowerCase().contains(query.toLowerCase())).toList();
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 8),
                child: Row(children: [
                  _filterChip('all', 'الكل', rows.length),
                  const SizedBox(width: 8),
                  _filterChip('pending', 'بانتظار الاعتماد', rows.where((student) => student.isPending).length),
                  const SizedBox(width: 8),
                  _filterChip('approved', 'معتمد', rows.where((student) => student.isApproved).length),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('${filteredRows.length} تلميذ', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              Expanded(
                child: filteredRows.isEmpty
                    ? const EmptyState(icon: Icons.search_off_rounded, title: 'لا توجد نتائج', message: 'جرّب اسمًا مختلفًا.')
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredRows.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final student = filteredRows[index];
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
                            trailing: student.isPending
                                ? const Chip(avatar: Icon(Icons.hourglass_top_rounded, size: 16), label: Text('معلق'))
                                : const Icon(Icons.chevron_left),
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

  Widget _filterChip(String value, String label, int count) => ChoiceChip(
    key: Key('student_filter_$value'),
    selected: statusFilter == value,
    label: Text('$label ($count)'),
    onSelected: (_) => setState(() => statusFilter = value),
  );
}
