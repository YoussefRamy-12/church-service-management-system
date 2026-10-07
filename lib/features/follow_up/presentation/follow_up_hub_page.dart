// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/presentation/service_providers.dart';
import '../../students/presentation/student_providers.dart';
import 'follow_up_page.dart';
import '../../../app/ui/app_ui.dart';

class FollowUpHubPage extends ConsumerStatefulWidget {
  const FollowUpHubPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<FollowUpHubPage> createState() => _FollowUpHubPageState();
}

class _FollowUpHubPageState extends ConsumerState<FollowUpHubPage> {
  String query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId));
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(serviceRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('المتابعة')),
      body: AppContent(
        maxWidth: 1000,
        child: StreamBuilder(
        stream: services.watchStages(widget.serviceId),
        builder: (context, stageSnapshot) {
          final stages = stageSnapshot.data ?? const [];
          if (stageSnapshot.connectionState == ConnectionState.waiting && stages.isEmpty) return const LoadingView(message: 'جاري تحميل المراحل...');
          if (stages.isEmpty) return const EmptyState(icon: Icons.volunteer_activism_outlined, title: 'لا توجد مراحل متاحة', message: 'حدّث البيانات عند توفر اتصال.');
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('سجل المتابعة', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text('اختر الفصل ثم التلميذ لعرض سجل المتابعة أو إضافة متابعة.'),
              const SizedBox(height: 16),
              TextField(
                key: const Key('follow_up_search'),
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
              const SizedBox(height: 12),
              for (final stage in stages)
                ExpansionTile(
                  key: Key('follow_up_stage_' + stage.id),
                  title: Text(stage.name),
                  onExpansionChanged: (expanded) {
                    if (expanded) services.refreshClasses(stage.id);
                  },
                  children: [
                    StreamBuilder(
                      stream: services.watchClasses(stage.id),
                      builder: (context, classSnapshot) {
                        final classes = classSnapshot.data ?? const [];
                        return Column(children: [
                          for (final item in classes)
                            ExpansionTile(
                              key: Key('follow_up_class_' + item.id),
                              title: Text(item.name),
                              onExpansionChanged: (expanded) {
                                if (expanded) {
                                  ref.read(studentRepositoryProvider).refreshStudents(item.id);
                                }
                              },
                              children: [
                                StreamBuilder(
                                  stream: ref.watch(studentRepositoryProvider).watchStudentsForClass(item.id),
                                  builder: (context, studentSnapshot) {
                                    final students = studentSnapshot.data ?? const [];
                                    final filtered = students.where((student) =>
                                        student.name.toLowerCase().contains(query.toLowerCase())).toList();
                                    if (studentSnapshot.connectionState == ConnectionState.waiting && students.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: LinearProgressIndicator(),
                                      );
                                    }
                                    if (filtered.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('لا توجد نتائج في هذا الفصل.'),
                                      );
                                    }
                                    return Column(children: [
                                      for (final student in filtered
                                        ListTile(
                                          key: Key('follow_up_student_' + student.id),
                                          leading: const Icon(Icons.history_edu_outlined),
                                          title: Text(student.name),
                                          trailing: const Icon(Icons.chevron_left),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => FollowUpPage(student: student),
                                            ),
                                          ),
                                        ),
                                    ]);
                                  },
                                ),
                              ],
                            ),
                        ]);
                      },
                    ),
                  ],
                ),
            ],
          );
        },
      ),
      );
    );
  }
}