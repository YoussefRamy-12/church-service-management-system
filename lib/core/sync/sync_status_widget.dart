import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'sync_engine_provider.dart';
import 'sync_status.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(syncQueueRepositoryProvider);
    final engine = ref.watch(syncEngineProvider);
    return StreamBuilder<int>(
      stream: queue.watchCountByStatus('pending'),
      builder: (context, pendingSnapshot) {
        return StreamBuilder<int>(
          stream: queue.watchCountByStatus('conflict'),
          builder: (context, conflictSnapshot) {
            final pending = pendingSnapshot.data ?? 0;
            final conflicts = conflictSnapshot.data ?? 0;
            final label = conflicts > 0
                ? 'تعارض $conflicts'
                : pending > 0
                    ? 'معلق $pending'
                    : engine.status == SyncStatus.offline
                        ? 'أوفلاين'
                        : 'متزامن';
            return ActionChip(
              onPressed: conflicts > 0 ? () => context.push('/sync/conflicts') : null,
              avatar: Icon(
                conflicts > 0
                    ? Icons.warning_amber
                    : pending > 0
                        ? Icons.sync
                        : Icons.cloud_done,
                size: 18,
              ),
              label: Text(label),
            );
          },
        );
      },
    );
  }
}