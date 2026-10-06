import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/service_report.dart';
import 'report_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key, required this.serviceId});
  final String serviceId;
  @override ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTime start = DateTime(DateTime.now().year, 1, 1);
  DateTime end = DateTime.now();
  ServiceReport? report;
  bool loading = false;

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final profile = await ref.read(currentServantProfileProvider.future);
      final service = ref.read(serviceRepositoryProvider);
      Set<String>? classIds;
      if (profile?.role == 'class_leader' || profile?.role == 'class_servant') {
        if (profile?.classId != null) classIds = {profile!.classId!};
      } else if (profile?.role == 'stage_leader' && profile?.stageId != null) {
        final classes = await service.local.getClasses(profile!.stageId!);
        classIds = classes.map((item) => item.id).toSet();
      }
      final value = await ref.read(reportRepositoryProvider).fetch(
        serviceId: widget.serviceId, start: start, end: end, classIds: classIds,
      );
      if (!mounted) return;
      setState(() => report = value);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل التقرير: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override void initState() { super.initState(); Future.microtask(_load); }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير'), actions: [
        IconButton(tooltip: 'تحديث التقرير', onPressed: loading ? null : _load, icon: const Icon(Icons.refresh)),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Expanded(child: _dateButton(context, label: 'من', value: formatter.format(start), onPick: (value) => setState(() => start = value), initialDate: start)),
          const SizedBox(width: 12),
          Expanded(child: _dateButton(context, label: 'إلى', value: formatter.format(end), onPick: (value) => setState(() => end = value), initialDate: end)),
        ]),
        const SizedBox(height: 16),
        if (loading) const Center(child: CircularProgressIndicator())
        else if (report == null) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('لا توجد بيانات تقرير متاحة.')))
        else _ReportSummary(report: report!),
      ]),
    );
  }

  Widget _dateButton(BuildContext context, {required String label, required String value, required ValueChanged<DateTime> onPick, required DateTime initialDate}) {
    return OutlinedButton.icon(
      onPressed: () async {
        final selected = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (selected != null && context.mounted) onPick(selected);
      },
      icon: const Icon(Icons.calendar_month),
      label: Text('$label: $value'),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});
  final ServiceReport report;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.7,
        children: [
          _metric('التلاميذ', report.students.toString(), Icons.groups),
          _metric('الاجتماعات', report.meetings.toString(), Icons.event),
          _metric('الحضور', '${report.present}/${report.expectedAttendance}', Icons.fact_check),
          _metric('نسبة الحضور', '${report.attendancePercentage.toStringAsFixed(1)}%', Icons.percent),
          _metric('مبكر', report.early.toString(), Icons.schedule),
          _metric('عادي', report.normal.toString(), Icons.access_time),
          _metric('المتابعات', report.followUps.toString(), Icons.phone),
        ],
      ),
      const SizedBox(height: 20),
      LinearProgressIndicator(value: report.attendancePercentage / 100),
    ]);
  }

  Widget _metric(String title, String value, IconData icon) => Card(
    child: Padding(padding: const EdgeInsets.all(14), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon), const SizedBox(height: 6), Text(title),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    ])),
  );
}