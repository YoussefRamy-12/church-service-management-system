import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import 'service_providers.dart';

class ServiceSettingsPage extends ConsumerStatefulWidget {
  const ServiceSettingsPage({super.key, required this.serviceId});
  final String serviceId;
  @override ConsumerState<ServiceSettingsPage> createState() => _ServiceSettingsPageState();
}

class _ServiceSettingsPageState extends ConsumerState<ServiceSettingsPage> {
  final nameController = TextEditingController();
  final churchController = TextEditingController();
  TimeOfDay meetingTime = const TimeOfDay(hour: 15, minute: 0);
  bool loading = true;
  bool saving = false;

  @override void initState() { super.initState(); Future.microtask(_load); }
  @override void dispose() { nameController.dispose(); churchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    final service = await ref.read(serviceRepositoryProvider).getService(widget.serviceId);
    if (!mounted) return;
    if (profile?.role != 'overall_leader' && profile?.role != 'overall_helper') { setState(() => loading = false); return; }
    if (service != null) {
      nameController.text = service.name;
      churchController.text = service.churchName;
      final parts = service.meetingStartTime.split(':');
      meetingTime = TimeOfDay(hour: int.tryParse(parts.first) ?? 15, minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    }
    try { await ref.read(serviceRepositoryProvider).refreshReportingPeriods(widget.serviceId); } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveMeetingTime() async {
    setState(() => saving = true);
    try {
      await ref.read(serviceRepositoryProvider).updateMeetingStartTime(
        serviceId: widget.serviceId,
        meetingStartTime: '${meetingTime.hour.toString().padLeft(2, '0')}:${meetingTime.minute.toString().padLeft(2, '0')}:00',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ وقت بداية الاجتماع محليًا وسيتم مزامنته.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: ${error.toString()}')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  Future<void> _addPeriod() async {
    final name = TextEditingController();
    String type = 'semester';
    DateTime start = DateTime(DateTime.now().year, 1, 1);
    DateTime end = DateTime(DateTime.now().year, 6, 30);
    final result = await showDialog<(String, String, DateTime, DateTime)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة فترة'),
          content: SingleChildScrollView(child: Column(children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الفترة')),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'النوع'),
              items: const [
                DropdownMenuItem(value: 'semester', child: Text('ترم')),
                DropdownMenuItem(value: 'service_year', child: Text('سنة خدمة')),
              ],
              onChanged: (value) { if (value != null) setDialogState(() => type = value); },
            ),
            ListTile(
              title: Text('من: ${start.toIso8601String().split('T').first}'),
              onTap: () async {
                final value = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (value != null) setDialogState(() => start = value);
              },
            ),
            ListTile(
              title: Text('إلى: ${end.toIso8601String().split('T').first}'),
              onTap: () async {
                final value = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (value != null) setDialogState(() => end = value);
              },
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, (name.text.trim(), type, start, end)), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    name.dispose();
    if (result == null || result.$1.isEmpty || result.$4.isBefore(result.$3)) return;
    final id = const Uuid().v4();
    final startDate = result.$3.toIso8601String().split('T').first;
    final endDate = result.$4.toIso8601String().split('T').first;
    await ref.read(serviceRepositoryProvider).local.cacheReportingPeriods([
      CachedReportingPeriodsCompanion.insert(id: id, serviceId: widget.serviceId, name: result.$1, type: result.$2, startDate: startDate, endDate: endDate, cachedAt: DateTime.now()),
    ]);
    await ref.read(syncQueueRepositoryProvider).enqueue(SyncOperation(
      operationId: id,
      entityType: 'reporting_period',
      operationType: 'insert',
      payloadJson: jsonEncode({'id': id, 'service_id': widget.serviceId, 'name': result.$1, 'type': result.$2, 'start_date': startDate, 'end_date': endDate}),
    ));
    if (mounted) setState(() {});
  }

  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الخدمة')),
      body: FutureBuilder<List<CachedReportingPeriod>>(
        future: ref.read(serviceRepositoryProvider).getReportingPeriods(widget.serviceId),
        builder: (context, snapshot) {
          final periods = snapshot.data ?? const <CachedReportingPeriod>[];
          return ListView(padding: const EdgeInsets.all(20), children: [
            TextField(controller: nameController, readOnly: true, decoration: const InputDecoration(labelText: 'اسم الخدمة')),
            TextField(controller: churchController, readOnly: true, decoration: const InputDecoration(labelText: 'الكنيسة')),
            ListTile(
              title: const Text('بداية الاجتماع'),
              subtitle: Text(meetingTime.format(context)),
              trailing: const Icon(Icons.schedule),
              onTap: () async {
                final value = await showTimePicker(context: context, initialTime: meetingTime);
                if (value != null && mounted) setState(() => meetingTime = value);
              },
            ),
            FilledButton.icon(onPressed: saving ? null : _saveMeetingTime, icon: const Icon(Icons.save), label: const Text('حفظ وقت الاجتماع')),
            const SizedBox(height: 28),
            Row(children: [
              const Expanded(child: Text('فترات التقارير', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              IconButton(onPressed: _addPeriod, icon: const Icon(Icons.add)),
            ]),
            ...periods.map((period) => Card(child: ListTile(title: Text(period.name), subtitle: Text('${period.type} • ${period.startDate} → ${period.endDate}')))),
          ]);
        },
      ),
    );
  }
}