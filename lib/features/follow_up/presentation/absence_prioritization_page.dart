import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/student_providers.dart';
import 'follow_up_page.dart';

class AbsencePrioritizationPage extends ConsumerStatefulWidget {
  const AbsencePrioritizationPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<AbsencePrioritizationPage> createState() => _AbsencePrioritizationPageState();
}

class _AbsencePrioritizationPageState extends ConsumerState<AbsencePrioritizationPage> {
  late Future<_PriorityData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_PriorityData> _load() async {
    final services = ref.read(serviceRepositoryProvider);
    final localStudents = ref.read(localStudentRepositoryProvider);
    final meetings = ref.read(meetingRepositoryProvider);
    final db = ref.read(appDatabaseProvider);
    try { await services.refreshStages(widget.serviceId); } catch (_) {}
    final stages = await services.local.getStages(widget.serviceId);
    final classes = <dynamic>[];
    for (final stage in stages) {
      try { await services.refreshClasses(stage.id); } catch (_) {}
      classes.addAll(await services.local.getClasses(stage.id));
    }
    final students = <Student>[];
    for (final item in classes) {
      try { await ref.read(studentRepositoryProvider).refreshStudents(item.id); } catch (_) {}
      students.addAll(await localStudents.watchStudentsForClass(item.id).first);
    }
    try { await meetings.refresh(widget.serviceId); } catch (_) {}
    final allMeetings = await meetings.watchMeetings(widget.serviceId).first;
    final recentMeetings = allMeetings.toList()..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
    final meetingIds = recentMeetings.take(3).map((meeting) => meeting.id).toList();
    final approvedStudents = students.where((student) => student.isApproved && student.currentClassId != null).toList();
    final records = meetingIds.isEmpty || approvedStudents.isEmpty
        ? <CachedAttendanceRecord>[]
        : await (db.select(db.cachedAttendanceRecords)
          ..where((row) => row.meetingId.isIn(meetingIds) & row.studentId.isIn(approvedStudents.map((student) => student.id).toList()))).get();
    final attended = <String, Set<String>>{};
    for (final record in records) { attended.putIfAbsent(record.studentId, () => {}).add(record.meetingId); }
    final followUps = approvedStudents.isEmpty
        ? <CachedFollowUpRecord>[]
        : await (db.select(db.cachedFollowUpRecords)..where((row) => row.studentId.isIn(approvedStudents.map((student) => student.id).toList()))).get();
    final followUpDue = <String>{};
    final today = DateTime.now().toIso8601String().split('T').first;
    for (final item in followUps) {
      final next = item.nextFollowUpDate;
      if (item.anotherFollowUpNeeded && next != null && next.compareTo(today) <= 0) followUpDue.add(item.studentId);
    }
    final items = approvedStudents.map((student) => _PriorityItem(
      student: student,
      absences: meetingIds.length - (attended[student.id]?.length ?? 0),
      followUpDue: followUpDue.contains(student.id),
    )).toList()
      ..sort((a, b) {
        final byAbsence = b.absences.compareTo(a.absences);
        return byAbsence != 0 ? byAbsence : (b.followUpDue ? 1 : 0).compareTo(a.followUpDue ? 1 : 0);
      });
    return _PriorityData(items: items, meetingCount: meetingIds.length);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('أولوية المتابعة')),
    body: FutureBuilder<_PriorityData>(future: _data, builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView(message: 'جاري تجهيز قائمة الأولوية...');
      if (snapshot.hasError) return EmptyState(icon: Icons.error_outline, title: 'تعذر تجهيز القائمة', message: '${snapshot.error}', action: OutlinedButton.icon(onPressed: () => setState(() => _data = _load()), icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')));
      final result = snapshot.data!;
      if (result.meetingCount == 0) return const EmptyState(icon: Icons.event_busy_outlined, title: 'لا توجد اجتماعات محفوظة', message: 'سجّل أو حدّث الاجتماعات لتحديد الغياب من آخر اللقاءات.');
      if (result.items.isEmpty) return const EmptyState(icon: Icons.people_outline, title: 'لا يوجد تلاميذ معتمدون', message: 'ستظهر الأولوية هنا بعد اعتماد التلاميذ.');
      return AppContent(maxWidth: 900, child: ListView(padding: const EdgeInsets.symmetric(vertical: 20), children: [
        StatusBanner(icon: Icons.info_outline, title: 'آخر ${result.meetingCount} اجتماعات', message: 'رتّب التلاميذ حسب مرات الغياب، مع إظهار المتابعات المستحقة.'),
        const SizedBox(height: 14),
        for (final item in result.items) Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          key: Key('absence_priority_${item.student.id}'),
          leading: CircleAvatar(child: Text('${item.absences}')),
          title: Text(item.student.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${item.absences} غياب من ${result.meetingCount}${item.followUpDue ? ' • متابعة مستحقة' : ''}'),
          trailing: Chip(label: Text(item.followUpDue || item.absences >= 2 ? 'أولوية عالية' : item.absences == 1 ? 'متابعة' : 'مستقر')),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FollowUpPage(student: item.student))),
        )),
      ]));
    }),
  );
}

class _PriorityData {
  const _PriorityData({required this.items, required this.meetingCount});
  final List<_PriorityItem> items;
  final int meetingCount;
}

class _PriorityItem {
  const _PriorityItem({required this.student, required this.absences, required this.followUpDue});
  final Student student;
  final int absences;
  final bool followUpDue;
}
