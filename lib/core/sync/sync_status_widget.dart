import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_engine_provider.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(syncQueueRepositoryProvider);
    final engine = ref.watch(syncEngineProvider);
    return FutureBuilder(
      future: Future.wait([queue.countByStatus('pending'), queue.countByStatus('conflict')]),
      builder: (context, snapshot) {
        final values = snapshot.data ?? const [0, 0];
        final pending = values[0];
        final conflicts = values[1];
        final label = conflicts > 0 ? 'تعارض $conflicts' : pending > 0 ? 'معلق $pending' : engine.status == SyncStatus.offline ? 'أوفلاين' : 'متزامن';
        return Chip(avatar: Icon(conflicts > 0 ? Icons.warning_amber : pending > 0 ? Icons.sync : Icons.cloud_done, size: 18), label: Text(label));
      },
    );
  }
}
