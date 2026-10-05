import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_providers.dart';
import '../../attendance/presentation/meeting_picker_page.dart';

class ClassStudentsPage extends ConsumerWidget {
  const ClassStudentsPage({super.key, required this.classId, required this.className, required this.serviceId});
  final String classId;
  final String className;
  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(studentRepositoryProvider).watchStudentsForClass(classId);
    return Scaffold(
      appBar: AppBar(title: Text(className), actions: [IconButton(icon: const Icon(Icons.fact_check), tooltip: 'الحضور', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPickerPage(serviceId: serviceId, classId: classId)))),IconButton(icon: const Icon(Icons.sync), tooltip: 'مزامنة', onPressed: () => ref.read(studentRepositoryProvider).refreshStudents(classId))]),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) return const Center(child: Text('لا يوجد تلاميذ محفوظون محليًا.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) => ListTile(
              leading: CircleAvatar(child: Text(rows[index].name.characters.first)),
              title: Text(rows[index].name),
              subtitle: Text(rows[index].school ?? 'بدون مدرسة مسجلة'),
            ),
          );
        },
      ),
    );
  }
}
