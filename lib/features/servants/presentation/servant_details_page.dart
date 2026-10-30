import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../attendance/domain/entities/meeting.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../auth/domain/entities/servant_profile.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../weekly_prep/domain/weekly_lesson.dart';
import '../../weekly_prep/presentation/weekly_prep_providers.dart';
import '../data/servant_attendance_repository.dart';
import 'servant_attendance_providers.dart';

class ServantDetailsPage extends ConsumerStatefulWidget {
  const ServantDetailsPage({super.key, required this.servant});

  final ServantProfile servant;

  @override
  ConsumerState<ServantDetailsPage> createState() => _ServantDetailsPageState();
}

class _ServantDetailsPageState extends ConsumerState<ServantDetailsPage> {
  late Future<_PreparationOverview> _preparation;
  late Future<List<ServantAttendanceRecord>> _attendance;
  late Future<List<Meeting>> _meetings;
  String? _selectedMeetingId;
  bool _recordingAttendance = false;

  @override
  void initState() {
    super.initState();
    _preparation = _loadPreparation();
    _attendance = _loadAttendance();
    _meetings = ref.read(meetingRepositoryProvider).watchMeetings(widget.servant.serviceId).first;
  }

  DateTime _currentWeekStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - DateTime.monday));
  }

  Future<_PreparationOverview> _loadPreparation() async {
    final servant = widget.servant;
    String? stageId = servant.stageId;
    if (stageId == null && servant.classId != null) {
      final row = await ref
          .read(supabaseClientProvider)
          .from('classes')
          .select('stage_id')
          .eq('id', servant.classId!)
          .maybeSingle();
      stageId = row?['stage_id'] as String?;
    }
    if (stageId == null) {
      return const _PreparationOverview(noStage: true);
    }

    final weekStart = _currentWeekStart();
    final lessons = await ref.read(weeklyLessonRepositoryProvider).list(servant.serviceId);
    WeeklyLesson? lesson;
    for (final item in lessons) {
      final start = DateTime(item.weekStart.year, item.weekStart.month, item.weekStart.day);
      if (item.stageId == stageId && start == weekStart) {
        lesson = item;
        break;
      }
    }
    if (lesson == null) return const _PreparationOverview(noLesson: true);
    final prepared = await ref.read(weeklyLessonRepositoryProvider).isPrepared(
      lessonId: lesson.id,
      servantProfileId: servant.id,
    );
    return _PreparationOverview(lesson: lesson, prepared: prepared);
  }

  Future<List<ServantAttendanceRecord>> _loadAttendance() {
    return ref.read(servantAttendanceRepositoryProvider).listForServant(widget.servant.id);
  }

  bool _isOverallLeader(ServantProfile? profile) =>
      profile != null &&
      profile.serviceId == widget.servant.serviceId &&
      profile.accountStatus == 'active' &&
      profile.role == 'overall_leader';

  Future<void> _recordAttendance(List<Meeting> meetings, ServantProfile actor) async {
    if (_recordingAttendance || !_isOverallLeader(actor)) return;
    final selectedId = _selectedMeetingId ?? (meetings.isEmpty ? null : meetings.first.id);
    final selected = meetings.where((m) => m.id == selectedId);
    final meeting = selected.isEmpty ? null : selected.first;
    if (meeting == null) {
      _message('لا يوجد اجتماع محدد لتسجيل الحضور.');
      return;
    }
    final existing = await _attendance;
    if (existing.any((record) => record.meetingId == meeting.id)) {
      _message('تم تسجيل حضور هذا الخادم في هذا الاجتماع بالفعل.');
      return;
    }
    setState(() => _recordingAttendance = true);
    try {
      await ref.read(servantAttendanceRepositoryProvider).checkIn(
        meetingId: meeting.id,
        servantProfileId: widget.servant.id,
        recordedBy: actor.id,
      );
      if (!mounted) return;
      setState(() => _attendance = _loadAttendance());
      _message('تم تسجيل حضور الخادم بنجاح.');
    } catch (error) {
      if (mounted) _message('تعذر تسجيل الحضور: $error');
    } finally {
      if (mounted) setState(() => _recordingAttendance = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentServantProfileProvider);
    final actor = profileState.hasValue ? profileState.value : null;
    final canRecordAttendance = _isOverallLeader(actor);

    return Scaffold(
      appBar: AppBar(title: Text(widget.servant.name)),
      body: AppContent(
        maxWidth: 900,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.servant.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(_roleLabel(widget.servant.role)),
                  if (widget.servant.phone?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(widget.servant.phone!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('تحضير درس الأسبوع الحالي', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            FutureBuilder<_PreparationOverview>(
              future: _preparation,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const GlassCard(child: LinearProgressIndicator());
                }
                if (snapshot.hasError) {
                  return GlassCard(child: Text('تعذر تحميل حالة التحضير: ${snapshot.error}'));
                }
                final value = snapshot.data ?? const _PreparationOverview(noLesson: true);
                final title = value.noStage
                    ? 'لم يتم تحديد مرحلة أو فصل للخادم.'
                    : value.noLesson
                        ? 'لم يتم رفع درس لهذه المرحلة في الأسبوع الحالي.'
                        : value.prepared
                            ? 'تم تحضير درس هذا الأسبوع.'
                            : 'لم يؤكد الخادم تحضير درس هذا الأسبوع بعد.';
                final color = value.prepared ? const Color(0xFF059669) : const Color(0xFFD97706);
                return GlassCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(value.prepared ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: color, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (value.lesson != null) ...[
                              const SizedBox(height: 4),
                              Text(value.lesson!.fileName, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: Text('سجل حضور الخادم', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                if (canRecordAttendance)
                  Text('صلاحية القائد العام', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Meeting>>(
              future: _meetings,
              builder: (context, meetingSnapshot) {
                final meetings = [...?meetingSnapshot.data]
                  ..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
                if (meetingSnapshot.connectionState == ConnectionState.waiting) {
                  return const GlassCard(child: LinearProgressIndicator());
                }
                if (meetingSnapshot.hasError) {
                  return GlassCard(child: Text('تعذر تحميل الاجتماعات: ${meetingSnapshot.error}'));
                }
                if (meetings.isEmpty) {
                  return const GlassCard(child: Text('لا توجد اجتماعات مسجلة لهذه الخدمة.'));
                }
                final selectedId = meetings.any((m) => m.id == _selectedMeetingId)
                    ? _selectedMeetingId
                    : meetings.first.id;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canRecordAttendance)
                      GlassCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedId,
                            items: [
                              for (final meeting in meetings)
                                DropdownMenuItem(
                                  value: meeting.id,
                                  child: Text('${meeting.name} • ${meeting.meetingDate.toLocal().toString().split(' ').first}'),
                                ),
                            ],
                            onChanged: (value) => setState(() => _selectedMeetingId = value),
                          ),
                        ),
                      ),
                    if (canRecordAttendance) ...[
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _recordingAttendance ? null : () => _recordAttendance(meetings, actor!),
                        icon: _recordingAttendance
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.how_to_reg_rounded),
                        label: const Text('تسجيل حضور الخادم'),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<ServantAttendanceRecord>>(
              future: _attendance,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('تعذر تحميل سجل الحضور: ${snapshot.error}');
                }
                final records = snapshot.data ?? const [];
                if (records.isEmpty) return const Text('لا توجد سجلات حضور لهذا الخادم بعد.');
                return Column(
                  children: [
                    for (final record in records)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available_rounded, color: Color(0xFF059669)),
                        title: Text(record.checkedInAt.toLocal().toString().split('.').first),
                        subtitle: Text('تم تسجيله بواسطة: ${record.recordedBy}'),
                      ),
                  ],
                );
              },
            ),
            if (!canRecordAttendance) ...[
              const SizedBox(height: 8),
              Text('تسجيل حضور الخدام متاح للقائد العام فقط.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'overall_leader' => 'قائد عام',
    'overall_helper' => 'مساعد القائد العام',
    'stage_leader' => 'قائد مرحلة',
    'class_leader' => 'قائد فصل',
    'class_servant' => 'خادم فصل',
    _ => role,
  };
}

class _PreparationOverview {
  const _PreparationOverview({this.lesson, this.prepared = false, this.noLesson = false, this.noStage = false});
  final WeeklyLesson? lesson;
  final bool prepared;
  final bool noLesson;
  final bool noStage;
}
