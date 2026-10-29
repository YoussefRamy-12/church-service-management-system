import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import 'meeting_providers.dart';

class MeetingSchedulesPage extends ConsumerStatefulWidget {
  const MeetingSchedulesPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<MeetingSchedulesPage> createState() => _MeetingSchedulesPageState();
}

class _MeetingSchedulesPageState extends ConsumerState<MeetingSchedulesPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _schedules = [];

  static const _weekdays = <String>[
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await ref.read(supabaseClientProvider)
          .from('meeting_schedules')
          .select('id, name, frequency, weekday, month_day, start_time, is_active')
          .eq('service_id', widget.serviceId)
          .order('created_at', ascending: true);
      if (mounted) setState(() {
        _schedules = rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = error.toString(); _loading = false; });
    }
  }

  bool _canManage() {
    final profile = ref.read(currentServantProfileProvider).valueOrNull;
    return ref.read(isSuperAdminProvider) ||
        profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper';
  }

  Future<void> _createSchedule() async {
    final name = TextEditingController();
    var frequency = 'weekly';
    var weekday = 5;
    var monthDay = 1;
    var startTime = const TimeOfDay(hour: 15, minute: 0);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة نوع اجتماع'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'اسم الاجتماع', hintText: 'مثال: اجتماع القداس / اجتماع الفصل'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'التكرار'),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                    DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                  ],
                  onChanged: (value) => setDialogState(() => frequency = value ?? 'weekly'),
                ),
                if (frequency == 'weekly')
                  DropdownButtonFormField<int>(
                    value: weekday,
                    decoration: const InputDecoration(labelText: 'يوم الاجتماع'),
                    items: List.generate(7, (index) => DropdownMenuItem(value: index + 1, child: Text(_weekdays[index]))),
                    onChanged: (value) => setDialogState(() => weekday = value ?? 5),
                  ),
                if (frequency == 'monthly')
                  DropdownButtonFormField<int>(
                    value: monthDay,
                    decoration: const InputDecoration(labelText: 'يوم الشهر'),
                    items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                    onChanged: (value) => setDialogState(() => monthDay = value ?? 1),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('وقت البداية'),
                  subtitle: Text(startTime.format(context)),
                  trailing: const Icon(Icons.schedule_rounded),
                  onTap: () async {
                    final selected = await showTimePicker(context: context, initialTime: startTime);
                    if (selected != null) setDialogState(() => startTime = selected);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().length < 2) return;
                Navigator.pop(dialogContext, {
                  'name': name.text.trim(),
                  'frequency': frequency,
                  'weekday': weekday,
                  'month_day': monthDay,
                  'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                });
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final schedule = await client.from('meeting_schedules').insert({
        ...result,
        'service_id': widget.serviceId,
      }).select('id, name, frequency, weekday, month_day, start_time, is_active').single();
      await _generateOccurrences(Map<String, dynamic>.from(schedule as Map));
      await ref.read(meetingRepositoryProvider).refresh(widget.serviceId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إنشاء الاجتماع وجدولة مواعيده القادمة.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء جدول الاجتماع: $error')),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateOccurrences(Map<String, dynamic> schedule) async {
    final client = ref.read(supabaseClientProvider);
    final scheduleId = schedule['id'] as String;
    final rows = await client.from('meetings').select('meeting_date')
        .eq('service_id', widget.serviceId).eq('schedule_id', scheduleId);
    final existing = rows.map((row) => row['meeting_date'].toString().split('T').first).toSet();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(start.year, start.month + 12, start.day);
    final parts = (schedule['start_time'] as String).split(':');
    final time = '${parts.first.padLeft(2, '0')}:${(parts.length > 1 ? parts[1] : '00').padLeft(2, '0')}';
    for (var date = start; !date.isAfter(end); date = date.add(const Duration(days: 1))) {
      final matches = schedule['frequency'] == 'monthly'
          ? date.day == (schedule['month_day'] as int).clamp(1, DateTime(date.year, date.month + 1, 0).day)
          : date.weekday == schedule['weekday'];
      final key = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (!matches || existing.contains(key)) continue;
      await ref.read(meetingRepositoryProvider).create(
        serviceId: widget.serviceId,
        date: date,
        startTime: time,
        name: schedule['name'] as String,
        scheduleId: scheduleId,
      );
      existing.add(key);
    }
  }


  @override
  Widget build(BuildContext context) {
    final canManage = _canManage();
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات اجتماعات الخدمة'),
        actions: [IconButton(tooltip: 'تحديث', onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      floatingActionButton: canManage ? FloatingActionButton.extended(
        onPressed: _saving ? null : _createSchedule,
        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_rounded),
        label: const Text('إضافة اجتماع'),
      ) : null,
      body: AppContent(
        maxWidth: 900,
        child: _loading
            ? const LoadingView(message: 'جاري تحميل جداول الاجتماعات...')
            : _error != null
                ? EmptyState(icon: Icons.cloud_off_rounded, title: 'تعذر تحميل إعدادات الاجتماعات', message: _error!, action: OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      const Text('يمكن للخدمة تنظيم أكثر من اجتماع، ولكل اجتماع اسم ووقت وتكرار مستقل. تتم جدولة المواعيد القادمة لمدة 12 شهرًا.'),
                      const SizedBox(height: 12),
                      if (_schedules.isEmpty)
                        const EmptyState(icon: Icons.event_note_rounded, title: 'لا توجد جداول اجتماعات', message: 'أضف اجتماعًا جديدًا لتحديد اسمه وموعده.'),
                      for (final schedule in _schedules)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Icon((schedule['is_active'] as bool) ? Icons.event_available_rounded : Icons.pause_circle_outline_rounded)),
                            title: Text(schedule['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              '${schedule['frequency'] == 'weekly' ? 'أسبوعي — ${_weekdays[(schedule['weekday'] as int) - 1]}' : 'شهري — يوم ${schedule['month_day']}'} • ${(schedule['start_time'] as String).substring(0, 5)}${(schedule['is_active'] as bool) ? '' : ' • متوقف'}',
                            ),
                            trailing: const Icon(Icons.event_repeat_rounded),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
