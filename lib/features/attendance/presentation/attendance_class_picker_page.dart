// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';

class AttendanceClassPickerPage extends ConsumerStatefulWidget {
  const AttendanceClassPickerPage({
    super.key,
    required this.serviceId,
    required this.meetingId,
  });
  final String serviceId;
  final String meetingId;

  @override
  ConsumerState<AttendanceClassPickerPage> createState() => _AttendanceClassPickerPageState();
}

class _AttendanceClassPickerPageState extends ConsumerState<AttendanceClassPickerPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(serviceRepositoryProvider).refreshStages(widget.serviceId));
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final profile = ref.watch(currentServantProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار الفصل للحضور')),
      body: StreamBuilder(
        stream: repository.watchStages(widget.serviceId),
        builder: (context, snapshot) {
          final stages = snapshot.data ?? const [];
          if (stages.isEmpty) {
            return const Center(child: Text('لا توجد مراحل محفوظة محليًا.'));
          }
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('اختر الفصل الذي ستسجل حضوره.'),
              const SizedBox(height: 16),
              for (final stage in stages)
                ExpansionTile(
                  key: Key('attendance_stage_' + stage.id),
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
                          children: [
                            for (final item in classes)
                              ListTile(
                                key: Key('attendance_class_' + item.id),
                                title: Text(item.name),
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () => context.go(
                                  '/service/' + widget.serviceId +
                                  '/attendance/session/' + widget.meetingId +
                                  '/' + item.id +
                                  '?recordedBy=' + profile.id,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}