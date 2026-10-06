import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/presentation/class_students_page.dart';
import '../../auth/presentation/auth_providers.dart';
import 'package:go_router/go_router.dart';
import '../../attendance/presentation/meeting_list_page.dart';
import 'service_providers.dart';

class ServiceDashboardPage extends ConsumerStatefulWidget {
  const ServiceDashboardPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<ServiceDashboardPage> createState() => _ServiceDashboardPageState();
}

class _ServiceDashboardPageState extends ConsumerState<ServiceDashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId));
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final profile = ref.watch(currentServantProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('خدمة تلاميذ المسيح'),
        actions: [
          if (profile.hasValue &&
              profile.value != null &&
              (profile.value!.role == 'overall_leader' ||
                  profile.value!.role == 'overall_helper'))
            IconButton(
              tooltip: 'إدارة الخدام',
              icon: const Icon(Icons.people_alt),
              onPressed: () => context.push('/servants/${widget.serviceId}'),
            ),
          IconButton(
            tooltip: 'التقارير',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/reports/' + widget.serviceId),
          ),
          IconButton(
            tooltip: 'الاجتماعات',
            icon: const Icon(Icons.event),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MeetingListPage(serviceId: widget.serviceId),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: repository.getService(widget.serviceId),
        builder: (context, snapshot) {
          final service = snapshot.data;
          if (service == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(service.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(service.churchName),
              const SizedBox(height: 24),
              const Text('المراحل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              StreamBuilder(
                stream: repository.watchStages(widget.serviceId),
                builder: (context, stageSnapshot) {
                  final stages = stageSnapshot.data ?? const [];
                  if (stages.isEmpty) return const Text('لا توجد مراحل محفوظة محليًا بعد.');
                  return Column(children: stages.map((stage) => ExpansionTile(
                    title: Text(stage.name),
                    onExpansionChanged: (expanded) {
                      if (expanded) {
                        ref.read(serviceRepositoryProvider).refreshClasses(stage.id);
                      }
                    },
                    children: [
                      StreamBuilder(
                        stream: repository.watchClasses(stage.id),
                        builder: (context, classSnapshot) {
                          final classes = classSnapshot.data ?? const [];
                          return Column(children: classes.map((item) => ListTile(
                            title: Text(item.name),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ClassStudentsPage(classId: item.id, className: item.name, serviceId: widget.serviceId)),
                            ),
                          )).toList());
                        },
                      ),
                    ],
                  )).toList());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
