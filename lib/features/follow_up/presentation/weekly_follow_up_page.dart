import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/student_providers.dart';
import 'follow_up_page.dart';

class WeeklyFollowUpPage extends ConsumerStatefulWidget {
  const WeeklyFollowUpPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<WeeklyFollowUpPage> createState() => _WeeklyFollowUpPageState();
}

class _WeeklyFollowUpPageState extends ConsumerState<WeeklyFollowUpPage> {
  late Future<List<_DueItem>> _dueItems;

  @override
  void initState() { super.initState(); _dueItems = _load(); }

  Future<List<_DueItem>> _load() async {
    final db = ref.read(appDatabaseProvider);
    final repo = ref.read(localStudentRepositoryProvider);
    final today = DateTime.now();
    final weekEnd = today.add(Duration(days: 7 - today.weekday));
    final todayText = today.toIso8601String().split('T').first;
    final endText = weekEnd.toIso8601String().split('T').first;
    final records = await (db.select(db.cachedFollowUpRecords)
      ..where((row) => row.anotherFollowUpNeeded.equals(true) & row.nextFollowUpDate.isNotNull())
      ..orderBy([(row) => OrderingTerm(expression: row.nextFollowUpDate)])).get();
    final results = <_DueItem>[];
    final seen = <String>{};
    for (final record in records) {
      final date = record.nextFollowUpDate;
      if (date == null || date.compareTo(endText) > 0 || !seen.add(record.studentId)) continue;
      final student = await repo.findById(record.studentId);
      if (student != null && student.serviceId == widget.serviceId) results.add(_DueItem(student: student, dueDate: date, isOverdue: date.compareTo(todayText) < 0));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('متابعات هذا الأسبوع')),
    body: FutureBuilder<List<_DueItem>>(future: _dueItems, builder: (context, snapshot) {
      if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) return const LoadingView(message: 'جاري تحميل المتابعات المستحقة...');
      if (snapshot.hasError) return EmptyState(icon: Icons.error_outline, title: 'تعذر تحميل قائمة الأسبوع', message: '${snapshot.error}', action: OutlinedButton.icon(onPressed: () => setState(() => _dueItems = _load()), icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')));
      final items = snapshot.data ?? const <_DueItem>[];
      if (items.isEmpty) return const EmptyState(icon: Icons.event_available_outlined, title: 'لا توجد متابعات مستحقة هذا الأسبوع', message: 'ستظهر هنا المتابعات القادمة والمسجلة محليًا.');
      return AppContent(maxWidth: 900, child: ListView(padding: const EdgeInsets.symmetric(vertical: 20), children: [
        Text('${items.length} متابعة مجدولة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final item in items) Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          leading: Icon(item.isOverdue ? Icons.notification_important_outlined : Icons.event_note_outlined, color: item.isOverdue ? Theme.of(context).colorScheme.error : null),
          title: Text(item.student.name),
          subtitle: Text('${item.isOverdue ? 'متأخرة' : 'موعد المتابعة'} • ${item.dueDate}'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FollowUpPage(student: item.student))),
        )),
      ]));
    }),
  );
}

class _DueItem {
  const _DueItem({required this.student, required this.dueDate, required this.isOverdue});
  final Student student;
  final String dueDate;
  final bool isOverdue;
}
