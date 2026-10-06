import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_engine_provider.dart';

class SyncConflictPage extends ConsumerWidget {
  const SyncConflictPage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(syncQueueRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('تعارضات المزامنة'), actions: [
        IconButton(
          tooltip: 'إعادة محاولة الكل',
          icon: const Icon(Icons.refresh),
          onPressed: () async { await queue.retryAllConflicts(); await ref.read(syncEngineProvider).syncNow(); },
        ),
      ]),
      body: StreamBuilder<List<SyncConflictItem>>(
        stream: queue.watchConflicts(),
        builder: (context, snapshot) {
          final conflicts = snapshot.data ?? const <SyncConflictItem>[];
          if (conflicts.isEmpty) return const Center(child: Text('لا توجد تعارضات معلقة.'));
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: conflicts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = conflicts[index];
              return Card(child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: Text(_entityLabel(item.entityType)),
                subtitle: Text(item.operationType + ' • ' + item.createdAt.toIso8601String().split('T').first),
                trailing: IconButton(
                  tooltip: 'إعادة المحاولة',
                  icon: const Icon(Icons.refresh),
                  onPressed: () async { await queue.retryConflict(item.operationId); await ref.read(syncEngineProvider).syncNow(); },
                ),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('تفاصيل التعارض'),
                    content: Text(_safeSummary(item.payloadJson)),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
                  ),
                ),
              ));
            },
          );
        },
      ),
    );
  }

  String _entityLabel(String value) => switch (value) {
    'student' => 'تعديل تلميذ',
    'attendance' => 'حضور',
    'follow_up' => 'متابعة',
    'servant' => 'بيانات خادم',
    'service' => 'إعدادات الخدمة',
    'reporting_period' => 'فترة تقرير',
    'meeting' => 'اجتماع',
    _ => value,
  };

  String _safeSummary(String payloadJson) {
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    final keys = payload.keys.where((key) => !{
      'phone', 'birth_date', 'work_study', 'notes',
      'student_response', 'parent_response', 'absence_reason', 'action_required',
    }.contains(key));
    return keys.map((key) => '$key: ${payload[key]}').join('\n');
  }
}