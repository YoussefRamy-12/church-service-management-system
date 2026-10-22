import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/config_provider.dart';
import '../network/connectivity_provider.dart';
import '../../app/theme.dart';
import 'sync_engine_provider.dart';
import 'sync_status.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineEnabled = ref.watch(offlineSyncEnabledProvider);
    if (!offlineEnabled) {
      final isOnlineAsync = ref.watch(isOnlineStreamProvider);
      final isOnline = isOnlineAsync.asData?.value ?? true;

      final statusColor = isOnline ? appSuccess : appError;
      final statusIcon = isOnline
          ? Icons.cloud_done_rounded
          : Icons.cloud_off_rounded;
      final label = isOnline ? 'متصل' : 'غير متصل';

      return ActionChip(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOnline
                    ? 'النظام يعمل بالاتصال المباشر بالخادم (Online).'
                    : 'لا يوجد اتصال بالإنترنت. تتطلب العمليات اتصالاً نشطاً بالخادم.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        backgroundColor: statusColor.withValues(alpha: 0.10),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.28),
          width: 1.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        avatar: Container(
          padding: const EdgeInsets.all(2),
          child: Icon(statusIcon, size: 16, color: statusColor),
        ),
        label: Text(
          label,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

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
                : engine.status == SyncStatus.error
                ? 'خطأ مزامنة'
                : engine.status == SyncStatus.syncing
                ? 'جارٍ التزامن'
                : 'متزامن';

            final statusColor = conflicts > 0
                ? appError
                : pending > 0
                ? appWarning
                : engine.status == SyncStatus.offline
                ? const Color(0xFF64748B)
                : engine.status == SyncStatus.error
                ? appError
                : engine.status == SyncStatus.syncing
                ? appAccentCyan
                : appSuccess;

            final statusIcon = conflicts > 0
                ? Icons.warning_amber_rounded
                : pending > 0
                ? Icons.sync_rounded
                : engine.status == SyncStatus.offline
                ? Icons.cloud_off_rounded
                : engine.status == SyncStatus.error
                ? Icons.error_outline_rounded
                : engine.status == SyncStatus.syncing
                ? Icons.sync_rounded
                : Icons.cloud_done_rounded;

            return ActionChip(
              onPressed: () =>
                  context.push(conflicts > 0 ? '/sync/conflicts' : '/sync'),
              backgroundColor: statusColor.withValues(alpha: 0.10),
              side: BorderSide(
                color: statusColor.withValues(alpha: 0.28),
                width: 1.1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              avatar: Container(
                padding: const EdgeInsets.all(2),
                child: Icon(statusIcon, size: 16, color: statusColor),
              ),
              label: Text(
                label,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
