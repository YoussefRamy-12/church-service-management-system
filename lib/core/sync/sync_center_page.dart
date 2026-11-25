import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/ui/app_ui.dart';
import '../../app/ui/components/sync_badge.dart';
import '../config/config_provider.dart';
import 'sync_engine_provider.dart';
import 'sync_status.dart';

class SyncCenterPage extends ConsumerStatefulWidget {
  const SyncCenterPage({super.key});
  @override
  ConsumerState<SyncCenterPage> createState() => _SyncCenterPageState();
}

class _SyncCenterPageState extends ConsumerState<SyncCenterPage> {
  bool _working = false;

  Future<void> _sync() async {
    final offlineSyncEnabled = ref.read(offlineSyncEnabledProvider);
    if (!offlineSyncEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المزامنة دون اتصال معطلة مؤقتًا؛ يعمل التطبيق بنمط الاتصال المباشر.'),
        ),
      );
      return;
    }
    setState(() => _working = true);
    try {
      await ref.read(syncEngineProvider).syncNow();
      if (!mounted) return;
      final engine = ref.read(syncEngineProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            engine.status == SyncStatus.offline
                ? 'أنت غير متصل. ستبقى التغييرات محفوظة على هذا الجهاز.'
                : engine.status == SyncStatus.error
                ? 'تعذرت المزامنة. حاول مرة أخرى.'
                : 'اكتملت محاولة المزامنة.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذرت المزامنة: $error')));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(syncQueueRepositoryProvider);
    final engine = ref.watch(syncEngineProvider);
    final offlineSyncEnabled = ref.watch(offlineSyncEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('مركز المزامنة')),
      body: AppContent(
        maxWidth: 850,
        child: StreamBuilder<int>(
          stream: queue.watchCountByStatus('pending'),
          builder: (context, pending) => StreamBuilder<int>(
            stream: queue.watchCountByStatus('conflict'),
            builder: (context, conflict) {
              final pendingCount = pending.data ?? 0;
              final conflictCount = conflict.data ?? 0;
              final syncState = conflictCount > 0
                  ? SyncState.conflict
                  : (pendingCount > 0 ? SyncState.pending : SyncState.synced);

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _SyncStatusHero(
                    offlineSyncEnabled: offlineSyncEnabled,
                    engineStatus: engine.status,
                    syncState: syncState,
                    pendingCount: pendingCount,
                    conflictCount: conflictCount,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CountCard(
                          icon: Icons.cloud_upload_outlined,
                          title: 'بانتظار المزامنة',
                          count: pendingCount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CountCard(
                          icon: Icons.warning_amber_rounded,
                          title: 'تحتاج مراجعة',
                          count: conflictCount,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const Key('sync_now'),
                    onPressed: (_working || !offlineSyncEnabled) ? null : _sync,
                    icon: _working
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(
                      !offlineSyncEnabled
                          ? 'المزامنة معطلة مؤقتًا'
                          : (_working ? 'جارٍ التحقق...' : 'مزامنة الآن'),
                    ),
                  ),
                  if (conflictCount > 0) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/sync/conflicts'),
                      icon: const Icon(Icons.rule_folder_outlined),
                      label: Text('مراجعة التعارضات ($conflictCount)'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (pendingCount == 0 && conflictCount == 0)
                    const EmptyState(
                      icon: Icons.cloud_done_outlined,
                      title: 'كل شيء متزامن',
                      message:
                          'لا توجد تغييرات معلقة أو تعارضات. بيانات هذا الجهاز متزامنة.',
                    )
                  else ...[
                    if (conflictCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StatusBanner(
                          icon: Icons.warning_amber_rounded,
                          title: 'تعارضات تحتاج مراجعة ($conflictCount)',
                          message:
                              'افتح شاشة مراجعة التعارضات لاختيار النسخة المعتمدة قبل إعادة المزامنة.',
                          tone: StatusTone.error,
                        ),
                      ),
                    if (pendingCount > 0)
                      FutureBuilder(
                        future: queue.pending(),
                        builder: (context, itemsSnapshot) {
                          final items = itemsSnapshot.data;
                          if (items == null || items.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'التغييرات في انتظار المزامنة',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              for (final item in items)
                                Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.cloud_upload_outlined,
                                    ),
                                    title: Text(item.entityType),
                                    subtitle: Text(item.operationType),
                                    trailing: const Icon(Icons.schedule),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SyncStatusHero extends StatelessWidget {
  const _SyncStatusHero({
    required this.offlineSyncEnabled,
    required this.engineStatus,
    required this.syncState,
    required this.pendingCount,
    required this.conflictCount,
  });

  final bool offlineSyncEnabled;
  final SyncStatus engineStatus;
  final SyncState syncState;
  final int pendingCount;
  final int conflictCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, detail, tone) = !offlineSyncEnabled
        ? (
            Icons.cloud_queue_rounded,
            'الاتصال المباشر فقط',
            'تم تعطيل المزامنة المحلية مؤقتًا، ويتصل التطبيق مباشرة بقاعدة البيانات المركزية.',
            StatusTone.neutral,
          )
        : conflictCount > 0
        ? (
            Icons.warning_amber_rounded,
            'تعارضات تحتاج مراجعة',
            'توجد عناصر متعارضة تحتاج مراجعتك قبل إعادة المزامنة.',
            StatusTone.error,
          )
        : switch (engineStatus) {
            SyncStatus.offline => (
              Icons.cloud_off_rounded,
              'غير متصل',
              'التغييرات محفوظة محليًا على هذا الجهاز.',
              StatusTone.warning,
            ),
            SyncStatus.syncing => (
              Icons.sync_rounded,
              'جارٍ التزامن',
              'يتم إرسال التغييرات المحفوظة.',
              StatusTone.neutral,
            ),
            SyncStatus.error => (
              Icons.error_outline_rounded,
              'تعذرت المزامنة',
              'تحقق من الشبكة ثم أعد المحاولة.',
              StatusTone.error,
            ),
            SyncStatus.idle => pendingCount > 0
                ? (
                    Icons.hourglass_top_rounded,
                    'في انتظار المزامنة',
                    'توجد تغييرات محفوظة محليًا جاهزة للإرسال عند المزامنة.',
                    StatusTone.warning,
                  )
                : (
                    Icons.cloud_done_rounded,
                    'تمت المزامنة',
                    'كل البيانات على هذا الجهاز محدثة ومتزامنة.',
                    StatusTone.success,
                  ),
          };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'حالة البيانات على هذا الجهاز',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SyncBadge(
                  state: syncState,
                  count: pendingCount,
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatusBanner(
              icon: icon,
              title: title,
              message: detail,
              tone: tone,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.icon,
    required this.title,
    required this.count,
  });
  final IconData icon;
  final String title;
  final int count;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(title),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
