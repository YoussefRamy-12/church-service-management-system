import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/service_report.dart';
import 'report_providers.dart';
import '../../../app/ui/app_ui.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key, required this.serviceId});
  final String serviceId;
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
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
        final classes = await service.getClasses(profile!.stageId!);
        classIds = classes.map((item) => item.id).toSet();
      }
      final value = await ref
          .read(reportRepositoryProvider)
          .fetch(
            serviceId: widget.serviceId,
            start: start,
            end: end,
            classIds: classIds,
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

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      end = now;
      if (preset == 'month') {
        start = DateTime(now.year, now.month, 1);
      } else if (preset == '3months') {
        start = DateTime(now.year, now.month - 3, 1);
      } else if (preset == 'year') {
        start = DateTime(now.year, 1, 1);
      }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy/MM/dd');
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير الخدمة'),
        actions: [
          IconButton(
            tooltip: 'تحديث التقرير',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.5,
        child: AppContent(
          maxWidth: 960,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // Date Range Filter Card
              GlassCard(
                borderRadius: 22,
                padding: const EdgeInsets.all(18),
                hoverElevation: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الفترة الزمنية للتقرير',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        // Preset chips
                        Wrap(
                          spacing: 6,
                          children: [
                            _presetChip('هذا الشهر', 'month'),
                            _presetChip('٣ أشهر', '3months'),
                            _presetChip('هذا العام', 'year'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _dateButton(
                            context,
                            label: 'من تاريخ',
                            value: formatter.format(start),
                            onPick: (value) {
                              setState(() => start = value);
                              _load();
                            },
                            initialDate: start,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateButton(
                            context,
                            label: 'إلى تاريخ',
                            value: formatter.format(end),
                            onPick: (value) {
                              setState(() => end = value);
                              _load();
                            },
                            initialDate: end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: LoadingView(message: 'جاري حساب إحصائيات التقرير...'),
                )
              else if (report == null)
                GlassCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'لا توجد بيانات تقرير متاحة لهذه الفترة',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _ReportSummary(
                  report: report!,
                  onMetricTap: _showDetails,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String label, String preset) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _setDatePreset(preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(String key, String title) async {
    final items = report?.details[key] ?? const <String>[];
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ReportMetricDetailPage(
          metricKey: key,
          title: title,
          items: items,
          start: start,
          end: end,
        ),
      ),
    );
  }

  Widget _dateButton(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<DateTime> onPick,
    required DateTime initialDate,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (selected != null && context.mounted) onPick(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report, required this.onMetricTap});
  final ServiceReport report;
  final void Function(String key, String title) onMetricTap;

  @override
  Widget build(BuildContext context) {
    final rate = report.attendancePercentage;
    final rateColor = rate >= 75
        ? const Color(0xFF10B981)
        : rate >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Column(
      children: [
        // Hero Attendance Banner
        GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  // Circular Progress Indicator
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (rate / 100).clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor: rateColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          '${rate.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: rateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'معدل الحضور العام',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            GlassBadge(
                              label: rate >= 75
                                  ? 'ممتاز'
                                  : rate >= 50
                                  ? 'متوسط'
                                  : 'يحتاج متابعة',
                              color: rateColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'حضر ${report.present} من أصل ${report.expectedAttendance} حضور متوقع عبر ${report.meetings} اجتماعات',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (rate / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: rateColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Metric cards grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _metric(
              context,
              'إجمالي التلاميذ',
              report.students.toString(),
              Icons.school_rounded,
              const Color(0xFF4F46E5),
              'students',
            ),
            _metric(
              context,
              'الاجتماعات',
              report.meetings.toString(),
              Icons.event_available_rounded,
              const Color(0xFF7C3AED),
              'meetings',
            ),
            _metric(
              context,
              'حضور مبكر',
              report.early.toString(),
              Icons.timer_rounded,
              const Color(0xFF06B6D4),
              'early',
            ),
            _metric(
              context,
              'قبل بداية الاجتماع',
              report.before.toString(),
              Icons.access_time_filled_rounded,
              const Color(0xFF4F46E5),
              'before',
            ),
            _metric(
              context,
              'حضور عادي',
              report.normal.toString(),
              Icons.schedule_rounded,
              const Color(0xFF3B82F6),
              'normal',
            ),
            _metric(
              context,
              'المتابعات المنجزة',
              report.followUps.toString(),
              Icons.volunteer_activism_rounded,
              const Color(0xFFEC4899),
              'followUps',
            ),
            _metric(
              context,
              'إجمالي الحضور',
              '${report.present}/${report.expectedAttendance}',
              Icons.fact_check_rounded,
              const Color(0xFF10B981),
              'attendance',
            ),
          ],
        ),
      ],
    );
  }

  Widget _metric(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String key,
  ) {
    return GlassCard(
      onTap: () => onMetricTap(key, title),
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetricDetailPage extends StatelessWidget {
  const _ReportMetricDetailPage({
    required this.metricKey,
    required this.title,
    required this.items,
    required this.start,
    required this.end,
  });

  final String title;
  final String metricKey;
  final List<String> items;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy/MM/dd');
    final description = switch (metricKey) {
      'students' => 'التلاميذ المشمولون في نطاق التقرير.',
      'meetings' => 'الاجتماعات التي عُقدت خلال الفترة المحددة.',
      'early' => 'تسجيلات الحضور من بداية الاجتماع وحتى نهاية فترة الحضور المبكر.',
      'before' => 'تسجيلات الحضور التي تمت قبل وقت بداية الاجتماع.',
      'normal' => 'تسجيلات الحضور بعد انتهاء فترة الحضور المبكر.',
      'followUps' => 'متابعات التلاميذ المسجلة خلال الفترة.',
      'attendance' => 'كل تسجيلات الحضور مع اسم التلميذ ووقت التسجيل.',
      _ => 'تفاصيل المؤشر خلال الفترة المحددة.',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AmbientBackground(
        intensity: 0.35,
        child: AppContent(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الفترة: ${formatter.format(start)} – ${formatter.format(end)}', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 5),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text('الإجمالي: ${items.length} ${metricKey == 'students' ? 'تلميذ' : metricKey == 'meetings' ? 'اجتماع' : 'سجل'}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'لا توجد تفاصيل مسجلة',
                        message: 'لا توجد سجلات لهذا المؤشر في الفترة المحددة.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final parts = items[index].split(' • ');
                          final titleText = metricKey == 'students'
                              ? items[index]
                              : metricKey == 'meetings'
                              ? 'اجتماع ${parts.first}'
                              : parts.last;
                          final detailText = metricKey == 'meetings'
                              ? 'وقت بداية الاجتماع: ${parts.length > 1 ? parts[1] : 'غير محدد'}'
                              : parts.length > 1 ? '${parts.first} • ${parts.sublist(1, parts.length - 1).join(' • ')}' : description;
                          return GlassCard(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            hoverElevation: false,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(child: Icon(metricKey == 'meetings' ? Icons.event_available_rounded : metricKey == 'students' ? Icons.person_rounded : Icons.check_circle_outline_rounded)),
                              title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text(detailText),
                              isThreeLine: false,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
