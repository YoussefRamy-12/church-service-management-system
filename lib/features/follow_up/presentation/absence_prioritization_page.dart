import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../../students/domain/entities/student.dart';
import '../../students/presentation/student_providers.dart';
import 'follow_up_page.dart';
import '../../auth/presentation/auth_providers.dart';
import 'follow_up_scope.dart';

class AbsencePrioritizationPage extends ConsumerStatefulWidget {
  const AbsencePrioritizationPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<AbsencePrioritizationPage> createState() =>
      _AbsencePrioritizationPageState();
}

class _AbsencePrioritizationPageState
    extends ConsumerState<AbsencePrioritizationPage> {
  late Future<_PriorityData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_PriorityData> _load() async {
    try {
      final offlineSyncEnabled = ref.read(offlineSyncEnabledProvider);
      final services = ref.read(serviceRepositoryProvider);
      final profile = await ref.read(currentServantProfileProvider.future);
      final scope = await resolveFollowUpClassScope(
        services: services,
        serviceId: widget.serviceId,
        profile: profile,
      );
      final studentRepo = ref.read(studentRepositoryProvider);
      final localStudents = ref.read(localStudentRepositoryProvider);
      final meetings = ref.read(meetingRepositoryProvider);
      final db = ref.read(appDatabaseProvider);
      try {
        await services.refreshStages(widget.serviceId);
      } catch (_) {}
      final stages = (await services.getStages(widget.serviceId))
          .where(
            (stage) =>
                scope.stageIds == null || scope.stageIds!.contains(stage.id),
          )
          .toList();
      final classes = <dynamic>[];
      for (final stage in stages) {
        try {
          await services.refreshClasses(stage.id);
        } catch (_) {}
        final stageClasses = await services.getClasses(stage.id);
        classes.addAll(
          stageClasses.where(
            (item) => scope.classIds == null || scope.classIds!.contains(item.id),
          ),
        );
      }
      final students = <Student>[];
      for (final item in classes) {
        try {
          await studentRepo.refreshStudents(item.id);
        } catch (_) {}
        final list = offlineSyncEnabled
            ? await localStudents.watchStudentsForClass(item.id).first
            : await studentRepo.watchStudentsForClass(item.id).first;
        students.addAll(list);
      }
      try {
        await meetings.refresh(widget.serviceId);
      } catch (_) {}
      final allMeetings = await meetings.watchMeetings(widget.serviceId).first;
      // Future meetings are scheduled in advance, but they cannot count as an
      // absence. Every student's denominator starts on their enrollment date.
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final completedMeetings =
          allMeetings
              .where((meeting) => !meeting.meetingDate.isAfter(todayDate))
              .toList()
            ..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
      final meetingIds = completedMeetings.map((meeting) => meeting.id).toList();
      final approvedStudents = students
          .where(
            (student) => student.isApproved && student.currentClassId != null,
          )
          .toList();

      final attended = <String, Set<String>>{};
      final followUpDue = <String>{};
      final todayText = today.toIso8601String().split('T').first;

      if (offlineSyncEnabled) {
        final records = meetingIds.isEmpty || approvedStudents.isEmpty
            ? <CachedAttendanceRecord>[]
            : await (db.select(db.cachedAttendanceRecords)..where(
                    (row) =>
                        row.meetingId.isIn(meetingIds) &
                        row.studentId.isIn(
                          approvedStudents.map((student) => student.id).toList(),
                        ),
                  ))
                  .get();
        for (final record in records) {
          attended.putIfAbsent(record.studentId, () => {}).add(record.meetingId);
        }
        if (meetingIds.isNotEmpty && approvedStudents.isNotEmpty) {
          try {
            final remoteRecords = await ref
                .read(supabaseClientProvider)
                .from('attendance_records')
                .select('meeting_id, student_id')
                .inFilter('meeting_id', meetingIds)
                .inFilter(
                  'student_id',
                  approvedStudents.map((student) => student.id).toList(),
                );
            for (final record in remoteRecords) {
              final studentId = record['student_id'] as String;
              final meetingId = record['meeting_id'] as String;
              attended.putIfAbsent(studentId, () => {}).add(meetingId);
            }
          } catch (_) {
            // Cached attendance is the offline fallback.
          }
        }
        final followUps = approvedStudents.isEmpty
            ? <CachedFollowUpRecord>[]
            : await (db.select(db.cachedFollowUpRecords)..where(
                    (row) => row.studentId.isIn(
                      approvedStudents.map((student) => student.id).toList(),
                    ),
                  ))
                  .get();
        for (final item in followUps) {
          final next = item.nextFollowUpDate;
          if (item.anotherFollowUpNeeded &&
              next != null &&
              next.compareTo(todayText) <= 0) {
            followUpDue.add(item.studentId);
          }
        }
      } else {
        // Online-only mode: Query Supabase directly with no local cache access
        if (meetingIds.isNotEmpty && approvedStudents.isNotEmpty) {
          final remoteRecords = await ref
              .read(supabaseClientProvider)
              .from('attendance_records')
              .select('meeting_id, student_id')
              .inFilter('meeting_id', meetingIds)
              .inFilter(
                'student_id',
                approvedStudents.map((student) => student.id).toList(),
              );
          for (final record in remoteRecords) {
            final studentId = record['student_id'] as String;
            final meetingId = record['meeting_id'] as String;
            attended.putIfAbsent(studentId, () => {}).add(meetingId);
          }
        }
        if (approvedStudents.isNotEmpty) {
          final remoteFollowUps = await ref
              .read(supabaseClientProvider)
              .from('follow_up_records')
              .select('student_id, next_follow_up_date, another_follow_up_needed')
              .inFilter(
                'student_id',
                approvedStudents.map((student) => student.id).toList(),
              );
          for (final item in remoteFollowUps) {
            final next = item['next_follow_up_date'] as String?;
            final needed = item['another_follow_up_needed'] == true;
            if (needed && next != null && next.compareTo(todayText) <= 0) {
              followUpDue.add(item['student_id'] as String);
            }
          }
        }
      }
    final items =
        approvedStudents.map((student) {
          final enrolledAt = student.enrollmentAt;
          final enrollmentDate = enrolledAt == null
              ? todayDate
              : DateTime(enrolledAt.year, enrolledAt.month, enrolledAt.day);
          final availableMeetings = completedMeetings
              .where((meeting) => !meeting.meetingDate.isBefore(enrollmentDate))
              .toList();
          final availableIds = availableMeetings
              .map((meeting) => meeting.id)
              .toSet();
          final attendedCount = (attended[student.id] ?? const <String>{})
              .where(availableIds.contains)
              .length;
          return _PriorityItem(
            student: student,
            availableMeetings: availableMeetings.length,
            absences: availableMeetings.length - attendedCount,
            followUpDue: followUpDue.contains(student.id),
          );
        }).toList()..sort((a, b) {
          final byAbsence = b.absences.compareTo(a.absences);
          return byAbsence != 0
              ? byAbsence
              : (b.followUpDue ? 1 : 0).compareTo(a.followUpDue ? 1 : 0);
        });
    return _PriorityData(items: items, meetingCount: completedMeetings.length);
    } catch (e) {
      throw Exception(NetworkErrorFormatter.format(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('أولوية المتابعة')),
    body: FutureBuilder<_PriorityData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'جاري تجهيز قائمة الأولوية...');
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تجهيز القائمة',
            message: '${snapshot.error}',
            action: OutlinedButton.icon(
              onPressed: () => setState(() => _data = _load()),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          );
        }
        final result = snapshot.data!;
        if (result.meetingCount == 0) {
          return const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'لا توجد اجتماعات محفوظة',
            message: 'سجّل أو حدّث الاجتماعات لتحديد الغياب من آخر اللقاءات.',
          );
        }
        if (result.items.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'لا يوجد تلاميذ معتمدون',
            message: 'ستظهر الأولوية هنا بعد اعتماد التلاميذ.',
          );
        }
        return AppContent(
          maxWidth: 900,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              StatusBanner(
                icon: Icons.info_outline,
                title: '${result.meetingCount} اجتماعات مكتملة',
                message:
                    'يُحسب الغياب لكل تلميذ من تاريخ التحاقه بالخدمة، مع إظهار المتابعات المستحقة.',
              ),
              const SizedBox(height: 16),
              for (final item in result.items)
                SolidCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  borderRadius: 16,
                  child: InkWell(
                    key: Key('absence_priority_${item.student.id}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FollowUpPage(student: item.student),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                (item.absences >= 2
                                        ? const Color(0xFFDC2626)
                                        : (item.absences == 1
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF059669)))
                                    .withValues(alpha: 0.12),
                            border: Border.all(
                              color:
                                  (item.absences >= 2
                                          ? const Color(0xFFDC2626)
                                          : (item.absences == 1
                                                ? const Color(0xFFD97706)
                                                : const Color(0xFF059669)))
                                      .withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.absences}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: item.absences >= 2
                                  ? const Color(0xFFDC2626)
                                  : (item.absences == 1
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF059669)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.student.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.absences} غياب من أصل ${item.availableMeetings} لقاء${item.followUpDue ? ' • متابعة مستحقة اليوم' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.followUpDue
                                      ? const Color(0xFFDC2626)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  fontWeight: item.followUpDue
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassBadge(
                          label: item.followUpDue || item.absences >= 2
                              ? 'أولوية عاجلة'
                              : (item.absences == 1 ? 'متابعة' : 'مستقر'),
                          color: item.followUpDue || item.absences >= 2
                              ? const Color(0xFFDC2626)
                              : (item.absences == 1
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF059669)),
                          showDot: item.followUpDue || item.absences >= 2,
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_left_rounded, size: 20),
                      ],
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

class _PriorityData {
  const _PriorityData({required this.items, required this.meetingCount});
  final List<_PriorityItem> items;
  final int meetingCount;
}

class _PriorityItem {
  const _PriorityItem({
    required this.student,
    required this.availableMeetings,
    required this.absences,
    required this.followUpDue,
  });
  final Student student;
  final int availableMeetings;
  final int absences;
  final bool followUpDue;
}
