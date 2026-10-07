// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    return FutureBuilder(
      future: repository.getService(widget.serviceId),
      builder: (context, snapshot) {
        final service = snapshot.data;
        if (service == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = profile.hasValue ? profile.value?.role : null;
        final canManage = role == 'overall_leader' || role == 'overall_helper' || role == 'leader' || role == 'helper';
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return ListView(
                padding: EdgeInsets.fromLTRB(wide ? 32 : 20, 28, wide ? 32 : 20, 40),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحبًا بك', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('لوحة الخدمة', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        key: const Key('dashboard_attendance'),
                        onPressed: () => context.go('/service/' + widget.serviceId + '/attendance'),
                        icon: const Icon(Icons.fact_check_rounded),
                        label: const Text('تسجيل الحضور'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.church_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(service.churchName, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('الوصول السريع', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: [
                      _QuickAction(key: const Key('dashboard_students'), icon: Icons.school_rounded, label: 'التلاميذ', onTap: () => context.go('/service/' + widget.serviceId + '/students')),
                      _QuickAction(icon: Icons.history_edu_rounded, label: 'المتابعة', onTap: () => context.go('/service/' + widget.serviceId + '/follow-up')),
                      if (canManage) _QuickAction(key: const Key('dashboard_reports'), icon: Icons.bar_chart_rounded, label: 'التقارير', onTap: () => context.go('/service/' + widget.serviceId + '/reports')),
                      if (canManage) _QuickAction(key: const Key('dashboard_servants'), icon: Icons.groups_rounded, label: 'الخدام', onTap: () => context.go('/service/' + widget.serviceId + '/servants')),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('المراحل والفصول', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  StreamBuilder(
                    stream: repository.watchStages(widget.serviceId),
                    builder: (context, stageSnapshot) {
                      final stages = stageSnapshot.data ?? const [];
                      if (stages.isEmpty) {
                        return Card(child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(children: [
                            Icon(Icons.school_outlined, size: 42, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(height: 10),
                            const Text('لا توجد مراحل محفوظة محليًا بعد.'),
                            const SizedBox(height: 4),
                            Text('ستظهر بيانات الخدمة هنا بعد المزامنة.', style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        ));
                      }
                      return Column(
                        children: stages.map((stage) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ExpansionTile(
                            key: Key('dashboard_stage_' + stage.id),
                            leading: const Icon(Icons.layers_outlined),
                            title: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            onExpansionChanged: (expanded) { if (expanded) repository.refreshClasses(stage.id); },
                            children: [
                              StreamBuilder(
                                stream: repository.watchClasses(stage.id),
                                builder: (context, classSnapshot) {
                                  final classes = classSnapshot.data ?? const [];
                                  if (classes.isEmpty) {
                                    return const Padding(padding: EdgeInsets.all(16), child: Text('لا توجد فصول محفوظة محليًا.'));
                                  }
                                  return Column(children: classes.map((item) => ListTile(
                                    key: Key('dashboard_class_' + item.id),
                                    leading: const Icon(Icons.groups_outlined),
                                    title: Text(item.name),
                                  )).toList());
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
      },
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