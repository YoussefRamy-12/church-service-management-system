import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/student_providers.dart';
import 'follow_up_page.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import 'follow_up_scope.dart';

class WeeklyFollowUpPage extends ConsumerStatefulWidget {
  const WeeklyFollowUpPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<WeeklyFollowUpPage> createState() => _WeeklyFollowUpPageState();
}

class _WeeklyFollowUpPageState extends ConsumerState<WeeklyFollowUpPage> {
  late Future<List<_DueItem>> _dueItems;

  @override
  void initState() {
    super.initState();
    _dueItems = _load();
  }

  Future<List<_DueItem>> _load() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    final scope = await resolveFollowUpClassScope(
      services: ref.read(serviceRepositoryProvider),
      serviceId: widget.serviceId,
      profile: profile,
    );
    final offlineEnabled = ref.read(offlineSyncEnabledProvider);
    final today = DateTime.now();
    final weekEnd = today.add(Duration(days: 7 - today.weekday));
    final todayText = today.toIso8601String().split('T').first;
    final endText = weekEnd.toIso8601String().split('T').first;

    final List<Map<String, dynamic>> records;
    final Map<String, Student> studentMap;

    if (offlineEnabled) {
      final db = ref.read(appDatabaseProvider);
      final repo = ref.read(localStudentRepositoryProvider);
      final dbRecords =
          await (db.select(db.cachedFollowUpRecords)
                ..where(
                  (row) =>
                      row.anotherFollowUpNeeded.equals(true) &
                      row.nextFollowUpDate.isNotNull(),
                )
                ..orderBy([
                  (row) => drift.OrderingTerm(expression: row.nextFollowUpDate),
                ]))
              .get();
      records = dbRecords
          .map((r) => {
                'student_id': r.studentId,
                'next_follow_up_date': r.nextFollowUpDate,
              })
          .toList();
      studentMap = {};
      for (final r in records) {
        final sId = r['student_id'] as String;
        if (!studentMap.containsKey(sId)) {
          final s = await repo.findById(sId);
          if (s != null) studentMap[sId] = s;
        }
      }
    } else {
      final client = ref.read(supabaseClientProvider);
      final remoteRecords = await client
          .from('follow_up_records')
          .select('student_id, next_follow_up_date')
          .eq('another_follow_up_needed', true)
          .not('next_follow_up_date', 'is', null)
          .order('next_follow_up_date');
      records = List<Map<String, dynamic>>.from(remoteRecords);

      final serviceStudents = await ref
          .read(studentRepositoryProvider)
          .watchStudentsForService(widget.serviceId)
          .first;
      studentMap = {for (final s in serviceStudents) s.id: s};
    }

    final results = <_DueItem>[];
    final seen = <String>{};
    for (final record in records) {
      final date = record['next_follow_up_date'] as String?;
      final studentId = record['student_id'] as String;
      if (date == null ||
          date.compareTo(endText) > 0 ||
          !seen.add(studentId)) {
        continue;
      }
      final student = studentMap[studentId];
      if (student != null &&
          student.serviceId == widget.serviceId &&
          (scope.classIds == null ||
              scope.classIds!.contains(student.currentClassId))) {
        results.add(
          _DueItem(
            student: student,
            dueDate: date,
            isOverdue: date.compareTo(todayText) < 0,
          ),
        );
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('متابعات هذا الأسبوع')),
    body: FutureBuilder<List<_DueItem>>(
      future: _dueItems,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'جاري تحميل المتابعات المستحقة...');
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل قائمة الأسبوع',
            message: NetworkErrorFormatter.format(snapshot.error),
            action: OutlinedButton.icon(
              onPressed: () => setState(() => _dueItems = _load()),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          );
        }
        final items = snapshot.data ?? const <_DueItem>[];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'لا توجد متابعات مستحقة هذا الأسبوع',
            message: 'ستظهر هنا المتابعات القادمة والمطلوبة.',
          );
        }
        return AppContent(
          maxWidth: 900,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              Text(
                '${items.length} متابعة مجدولة',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final item in items)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      item.isOverdue
                          ? Icons.notification_important_outlined
                          : Icons.event_note_outlined,
                      color: item.isOverdue
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    title: Text(item.student.name),
                    subtitle: Text(
                      '${item.isOverdue ? 'متأخرة' : 'موعد المتابعة'} • ${item.dueDate}',
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowUpPage(student: item.student),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _DueItem {
  const _DueItem({
    required this.student,
    required this.dueDate,
    required this.isOverdue,
  });
  final Student student;
  final String dueDate;
  final bool isOverdue;
}
