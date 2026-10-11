import 'dart:convert';

import 'package:church_service_management_system/app/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import 'service_providers.dart';

class ServiceSettingsPage extends ConsumerStatefulWidget {
  const ServiceSettingsPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<ServiceSettingsPage> createState() =>
      _ServiceSettingsPageState();
}

class _ServiceSettingsPageState extends ConsumerState<ServiceSettingsPage> {
  final nameController = TextEditingController();
  final churchController = TextEditingController();
  TimeOfDay meetingTime = const TimeOfDay(hour: 15, minute: 0);
  String meetingFrequency = 'weekly';
  int meetingWeekday = 5;
  int meetingMonthDay = 1;
  bool loading = true;
  bool saving = false;
  bool denied = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    nameController.dispose();
    churchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    final service = await ref
        .read(serviceRepositoryProvider)
        .getService(widget.serviceId);
    if (!mounted) return;
    if (!ref.read(isSuperAdminProvider) &&
        profile?.role != 'overall_leader' &&
        profile?.role != 'overall_helper') {
      setState(() {
        loading = false;
        denied = true;
      });
      return;
    }
    if (service != null) {
      nameController.text = service.name;
      churchController.text = service.churchName;
      final parts = service.meetingStartTime.split(':');
      meetingTime = TimeOfDay(
        hour: int.tryParse(parts.first) ?? 15,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      );
      meetingFrequency = service.meetingFrequency;
      meetingWeekday = service.meetingWeekday;
      meetingMonthDay = service.meetingMonthDay;
    }
    try {
      await ref
          .read(serviceRepositoryProvider)
          .refreshReportingPeriods(widget.serviceId);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveMeetingTime() async {
    setState(() => saving = true);
    try {
      await ref
          .read(serviceRepositoryProvider)
          .updateMeetingSchedule(
            serviceId: widget.serviceId,
            meetingStartTime:
                '${meetingTime.hour.toString().padLeft(2, '0')}:${meetingTime.minute.toString().padLeft(2, '0')}:00',
            meetingFrequency: meetingFrequency,
            meetingWeekday: meetingWeekday,
            meetingMonthDay: meetingMonthDay,
          );
      final service = await ref.read(serviceRepositoryProvider).local.getService(widget.serviceId);
      if (service != null) {
        await ref.read(meetingRepositoryProvider).ensureConfiguredSchedule(service);
      }
      await ref.read(syncEngineProvider).syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ جدول الاجتماع محليًا وسيتم مزامنته.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _addPeriod() async {
    final result = await showDialog<(String, String, DateTime, DateTime)>(
      context: context,
      builder: (_) => const _AddPeriodDialog(),
    );
    if (result == null || result.$1.isEmpty || result.$4.isBefore(result.$3))
      return;
    final id = const Uuid().v4();
    final startDate = result.$3.toIso8601String().split('T').first;
    final endDate = result.$4.toIso8601String().split('T').first;
    await ref.read(serviceRepositoryProvider).local.cacheReportingPeriods([
      CachedReportingPeriodsCompanion.insert(
        id: id,
        serviceId: widget.serviceId,
        name: result.$1,
        type: result.$2,
        startDate: startDate,
        endDate: endDate,
        cachedAt: DateTime.now(),
      ),
    ]);
    await ref
        .read(syncQueueRepositoryProvider)
        .enqueue(
          SyncOperation(
            operationId: id,
            entityType: 'reporting_period',
            operationType: 'insert',
            payloadJson: jsonEncode({
              'id': id,
              'service_id': widget.serviceId,
              'name': result.$1,
              'type': result.$2,
              'start_date': startDate,
              'end_date': endDate,
            }),
          ),
        );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (denied) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'لا تملك صلاحية الوصول',
          message: 'تحتاج إلى دور مسؤول الخدمة لفتح إعدادات هذه الخدمة.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الخدمة')),
      body: FutureBuilder<List<CachedReportingPeriod>>(
        future: ref
            .read(serviceRepositoryProvider)
            .getReportingPeriods(widget.serviceId),
        builder: (context, snapshot) {
          final periods = snapshot.data ?? const <CachedReportingPeriod>[];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: nameController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'اسم الخدمة'),
              ),
              TextField(
                controller: churchController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'الكنيسة'),
              ),
              ListTile(
                title: const Text('وقت الاجتماع'),
                subtitle: Text(meetingTime.format(context)),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: meetingTime,
                  );
                  if (value != null && mounted)
                    setState(() => meetingTime = value);
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: meetingFrequency,
                decoration: const InputDecoration(labelText: 'تكرار الاجتماع'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                  DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => meetingFrequency = value);
                },
              ),
              if (meetingFrequency == 'weekly')
                DropdownButtonFormField<int>(
                  initialValue: meetingWeekday,
                  decoration: const InputDecoration(labelText: 'يوم الاجتماع'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('الاثنين')),
                    DropdownMenuItem(value: 2, child: Text('الثلاثاء')),
                    DropdownMenuItem(value: 3, child: Text('الأربعاء')),
                    DropdownMenuItem(value: 4, child: Text('الخميس')),
                    DropdownMenuItem(value: 5, child: Text('الجمعة')),
                    DropdownMenuItem(value: 6, child: Text('السبت')),
                    DropdownMenuItem(value: 7, child: Text('الأحد')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => meetingWeekday = value);
                  },
                ),
              if (meetingFrequency == 'monthly')
                DropdownButtonFormField<int>(
                  initialValue: meetingMonthDay,
                  decoration: const InputDecoration(labelText: 'يوم الشهر'),
                  items: [
                    for (var day = 1; day <= 31; day++)
                      DropdownMenuItem(value: day, child: Text('$day')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => meetingMonthDay = value);
                  },
                ),
              FilledButton.icon(
                onPressed: saving ? null : _saveMeetingTime,
                icon: const Icon(Icons.save),
                label: const Text('حفظ جدول الاجتماع'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  '/service/${widget.serviceId}/settings/structure',
                ),
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('إدارة المراحل والفصول'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('/service/${widget.serviceId}/settings/system'),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('إعدادات النظام والحساب'),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'فترات التقارير',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addPeriod,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              ...periods.map(
                (period) => Card(
                  child: ListTile(
                    title: Text(period.name),
                    subtitle: Text(
                      '${period.type} • ${period.startDate} → ${period.endDate}',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddPeriodDialog extends StatefulWidget {
  const _AddPeriodDialog();
  @override
  State<_AddPeriodDialog> createState() => _AddPeriodDialogState();
}

class _AddPeriodDialogState extends State<_AddPeriodDialog> {
  final _name = TextEditingController();
  String _type = 'semester';
  DateTime _start = DateTime(DateTime.now().year, 1, 1);
  DateTime _end = DateTime(DateTime.now().year, 6, 30);

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _start : _end;
    final value = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (value != null && mounted) setState(() { if (start) { _start = value; } else { _end = value; } });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('إضافة فترة'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الفترة')),
      DropdownButtonFormField<String>(initialValue: _type, decoration: const InputDecoration(labelText: 'النوع'), items: const [
        DropdownMenuItem(value: 'semester', child: Text('ترم')),
        DropdownMenuItem(value: 'service_year', child: Text('سنة خدمة')),
      ], onChanged: (value) { if (value != null) setState(() => _type = value); }),
      ListTile(title: Text('من: ${_start.toIso8601String().split('T').first}'), onTap: () => _pickDate(start: true)),
      ListTile(title: Text('إلى: ${_end.toIso8601String().split('T').first}'), onTap: () => _pickDate(start: false)),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: () => Navigator.pop(context, (_name.text.trim(), _type, _start, _end)), child: const Text('حفظ')),
    ],
  );
}
