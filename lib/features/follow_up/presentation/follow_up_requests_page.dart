import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/entities/follow_up_record.dart';
import 'follow_up_page.dart';
import 'follow_up_providers.dart';

class FollowUpRequestsPage extends ConsumerStatefulWidget {
  const FollowUpRequestsPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<FollowUpRequestsPage> createState() => _FollowUpRequestsPageState();
}

class _FollowUpRequestsPageState extends ConsumerState<FollowUpRequestsPage> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    if (profile == null) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await ref.read(followUpRepositoryProvider).refreshAssignedTo(profile.id);
      await ref.read(studentRepositoryProvider).refreshStudentsForService(widget.serviceId);
    } catch (_) {
      // Cached assignments and student records remain visible offline.
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _updateStatus(FollowUpRecord request, String status) async {
    try {
      await ref.read(followUpRepositoryProvider).updateRequestStatus(
        requestId: request.id,
        status: status,
      );
      if (ref.read(offlineSyncEnabledProvider)) {
        await ref.read(syncEngineProvider).syncNow();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'completed' ? 'تم إكمال طلب المتابعة.' : 'تم بدء المتابعة.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث الطلب: $error')),
        );
      }
    }
  }

  String _statusLabel(String status) => switch (status) {
    'completed' => 'مكتمل',
    'in_progress' => 'قيد التنفيذ',
    _ => 'جديد',
  };

  Color _statusColor(String status) => switch (status) {
    'completed' => const Color(0xFF059669),
    'in_progress' => const Color(0xFFD97706),
    _ => const Color(0xFF4F46E5),
  };

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات المتابعة المسندة إليّ'),
        actions: [
          IconButton(
            tooltip: 'تحديث الطلبات',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: profile == null
          ? const LoadingView(message: 'جاري تجهيز حساب الخادم...')
          : StreamBuilder<List<FollowUpRecord>>(
              stream: ref.watch(followUpRepositoryProvider).watchAssignedTo(profile.id),
              builder: (context, requestSnapshot) => StreamBuilder(
                stream: ref.watch(studentRepositoryProvider).watchStudentsForService(widget.serviceId),
                builder: (context, studentSnapshot) {
                  final requests = requestSnapshot.data ?? const <FollowUpRecord>[];
                  final students = studentSnapshot.data ?? const [];
                  if (requestSnapshot.connectionState == ConnectionState.waiting && requests.isEmpty) {
                    return const LoadingView(message: 'جاري تحميل طلبات المتابعة...');
                  }
                  if (requests.isEmpty) {
                    return const EmptyState(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'لا توجد طلبات متابعة مسندة',
                      message: 'عندما يسند القائد طلب متابعة إليك سيظهر هنا.',
                    );
                  }
                  return AppContent(
                    maxWidth: 900,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final matching = students.where((student) => student.id == request.studentId);
                        final student = matching.isEmpty ? null : matching.first;
                        final status = request.requestStatus;
                        final color = _statusColor(status);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color.withValues(alpha: .12),
                                      child: Icon(Icons.assignment_outlined, color: color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(student?.name ?? 'تلميذ رقم ${request.studentId}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          Text(request.actionRequired ?? 'مطلوب متابعة التلميذ'),
                                          if (request.notes?.trim().isNotEmpty == true) ...[
                                            const SizedBox(height: 4),
                                            Text(request.notes!, style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                          const SizedBox(height: 8),
                                          Wrap(spacing: 8, runSpacing: 6, children: [
                                            Chip(label: Text('الموعد: ${request.followUpDate}')),
                                            Chip(
                                              label: Text(_statusLabel(status)),
                                              backgroundColor: color.withValues(alpha: .12),
                                              side: BorderSide(color: color.withValues(alpha: .3)),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (student != null)
                                      OutlinedButton.icon(
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(builder: (_) => FollowUpPage(student: student)),
                                        ),
                                        icon: const Icon(Icons.phone_in_talk_outlined),
                                        label: const Text('تسجيل المتابعة'),
                                      ),
                                    if (status == 'open')
                                      FilledButton.icon(
                                        onPressed: () => _updateStatus(request, 'in_progress'),
                                        icon: const Icon(Icons.play_arrow_rounded),
                                        label: const Text('بدء التنفيذ'),
                                      )
                                    else if (status == 'in_progress')
                                      FilledButton.icon(
                                        onPressed: () => _updateStatus(request, 'completed'),
                                        icon: const Icon(Icons.check_circle_outline_rounded),
                                        label: const Text('إكمال الطلب'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
