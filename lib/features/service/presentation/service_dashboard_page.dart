import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import 'service_providers.dart';

class ServiceDashboardPage extends ConsumerStatefulWidget {
  const ServiceDashboardPage({super.key, required this.serviceId});
  final String serviceId;
  @override ConsumerState<ServiceDashboardPage> createState() => _ServiceDashboardPageState();
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
      appBar: AppBar(title: const Text('الرئيسية')),
      body: FutureBuilder(
        future: repository.getService(widget.serviceId),
        builder: (context, snapshot) {
          final service = snapshot.data;
          if (service == null) return const Center(child: CircularProgressIndicator());

          final canManage = profile.hasValue &&
              profile.value != null &&
              (profile.value!.role == 'overall_leader' ||
                  profile.value!.role == 'overall_helper');

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.church, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(service.churchName),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              Text('الوصول السريع', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickAction(
                    key: const Key('dashboard_students'),
                    icon: Icons.school_outlined,
                    label: 'التلاميذ',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('استخدم قائمة التلاميذ من القائمة الجانبية.'))),
                  ),
                  _QuickAction(
                    key: const Key('dashboard_attendance'),
                    icon: Icons.fact_check_outlined,
                    label: 'الحضور',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('استخدم قائمة الحضور من القائمة الجانبية.'))),
                  ),
                  _QuickAction(
                    key: const Key('dashboard_follow_up'),
                    icon: Icons.history_edu_outlined,
                    label: 'المتابعة',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('استخدم قائمة المتابعة من القائمة الجانبية.'))),
                  ),
                  if (canManage)
                    _QuickAction(
                      key: const Key('dashboard_servants'),
                      icon: Icons.people_alt_outlined,
                      label: 'الخدام',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('استخدم قائمة الخدام من القائمة الجانبية.'))),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('المراحل', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              StreamBuilder(
                stream: repository.watchStages(widget.serviceId),
                builder: (context, stageSnapshot) {
                  final stages = stageSnapshot.data ?? const [];
                  if (stages.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('لا توجد مراحل محفوظة محليًا بعد.'),
                      ),
                    );
                  }
                  return Column(
                    children: stages.map((stage) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        key: Key('dashboard_stage_' + stage.id),
                        title: Text(stage.name),
                        onExpansionChanged: (expanded) {
                          if (expanded) repository.refreshClasses(stage.id);
                        },
                        children: [
                          StreamBuilder(
                            stream: repository.watchClasses(stage.id),
                            builder: (context, classSnapshot) {
                              final classes = classSnapshot.data ?? const [];
                              return Column(
                                children: classes.map((item) => ListTile(
                                  key: Key('dashboard_class_' + item.id),
                                  title: Text(item.name),
                                  trailing: const Icon(Icons.chevron_left),
                                )).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      );
}