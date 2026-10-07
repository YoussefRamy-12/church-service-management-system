import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/presentation/service_providers.dart';
import 'class_students_page.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId));
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('التلاميذ'), actions: [
        IconButton(
          key: const Key('students_refresh'),
          tooltip: 'تحديث',
          onPressed: () => repository.refreshStages(widget.serviceId),
          icon: const Icon(Icons.sync),
        ),
      ]),
      body: StreamBuilder(
        stream: repository.watchStages(widget.serviceId),
        builder: (context, snapshot) {
          final stages = snapshot.data ?? const [];
          if (snapshot.connectionState == ConnectionState.waiting && stages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (stages.isEmpty) {
            return const Center(child: Text('لا توجد مراحل محفوظة محليًا بعد.'));
          }
          return ListView(
            key: const Key('students_stage_list'),
            padding: const EdgeInsets.all(20),
            children: [
              Text('المراحل والفصول', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              const Text('اختر الفصل لإدارة التلاميذ والحضور.'),
              const SizedBox(height: 20),
              for (final stage in stages)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    key: Key('stage_' + stage.id),
                    title: Text(stage.name),
                    onExpansionChanged: (expanded) {
                      if (expanded) repository.refreshClasses(stage.id);
                    },
                    children: [
                      StreamBuilder(
                        stream: repository.watchClasses(stage.id),
                        builder: (context, classSnapshot) {
                          final classes = classSnapshot.data ?? const [];
                          if (classes.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('لا توجد فصول محفوظة محليًا.'),
                            );
                          }
                          return Column(children: [
                            for (final item in classes)
                              ListTile(
                                key: Key('class_' + item.id),
                                leading: const Icon(Icons.groups_outlined),
                                title: Text(item.name),
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ClassStudentsPage(
                                      classId: item.id,
                                      className: item.name,
                                      serviceId: widget.serviceId,
                                    ),
                                  ),
                                ),
                              ),
                          ]);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}