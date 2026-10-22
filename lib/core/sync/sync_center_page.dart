import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/ui/app_ui.dart';
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
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            if (!offlineSyncEnabled) ...[
              const StatusBanner(
                icon: Icons.info_outline,
                title: 'نمط الاتصال المباشر فقط (Online-Only)',
                message:
                    'تم تعطيل المزامنة المحلية والعمل دون اتصال مؤقتًا. يتصل التطبيق مباشرة بقاعدة البيانات المركزية.',
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'حالة البيانات على هذا الجهاز',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _StatusCard(status: engine.status),
            const SizedBox(height: 14),
            StreamBuilder<int>(
              stream: queue.watchCountByStatus('pending'),
              builder: (context, pending) => StreamBuilder<int>(
                stream: queue.watchCountByStatus('conflict'),
                builder: (context, conflict) {
                  final pendingCount = pending.data ?? 0;
                  final conflictCount = conflict.data ?? 0;
                  return Column(
                    children: [
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(
                          !offlineSyncEnabled
                              ? 'المزامنة معطلة مؤقتًا'
                              : (_working ? 'جارٍ التحقق...' : 'مزامنة الآن'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (conflictCount > 0)
                        OutlinedButton.icon(
                          onPressed: () => context.push('/sync/conflicts'),
                          icon: const Icon(Icons.rule_folder_outlined),
                          label: Text('مراجعة التعارضات ($conflictCount)'),
                        ),
                      if (pendingCount == 0 && conflictCount == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: EmptyState(
                            icon: Icons.cloud_done_outlined,
                            title: 'كل التغييرات متزامنة',
                            message: 'ستظهر هنا أي تغييرات محفوظة دون اتصال.',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  offlineSyncEnabled
                      ? 'يمكنك الاستمرار في تسجيل البيانات دون اتصال. ستبقى محفوظة محليًا حتى تتوفر الشبكة، ثم تُرسل إلى الخدمة عند المزامنة.'
                      : 'يعمل التطبيق حاليًا بالاتصال المباشر بقاعدة البيانات المركزية (Online-only). تم تعطيل الحفظ المحلي والمزامنة مؤقتًا لحين اكتمال التحديثات. البيانات العالقة محفوظة بأمان ولن تُفقد.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final SyncStatus status;
  @override
  Widget build(BuildContext context) {
    final (icon, title, detail, tone) = switch (status) {
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
      SyncStatus.idle => (
        Icons.cloud_done_rounded,
        'جاهز للمزامنة',
        'سيتم إرسال التغييرات عند توفر الاتصال.',
        StatusTone.success,
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatusBanner(
          icon: icon,
          title: title,
          message: detail,
          tone: tone,
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
