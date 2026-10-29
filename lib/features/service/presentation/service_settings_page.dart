import 'package:church_service_management_system/app/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../../core/sync/sync_engine_provider.dart';
import '../../../core/utils/web_app_install.dart';
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
  int earlyAttendanceMinutes = 15;
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
        profile?.role != 'overall_leader') {
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
      earlyAttendanceMinutes = service.earlyAttendanceMinutes;
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
            earlyAttendanceMinutes: earlyAttendanceMinutes,
          );
      final service = await ref
          .read(serviceRepositoryProvider)
          .getService(widget.serviceId);
      if (service != null) {
        await ref
            .read(meetingRepositoryProvider)
            .ensureConfiguredSchedule(service);
      }
      final isOffline = ref.read(offlineSyncEnabledProvider);
      if (isOffline) {
        await ref.read(syncEngineProvider).syncNow();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'تم حفظ جدول الاجتماع محليًا وسيتم مزامنته.'
                : 'تم حفظ جدول الاجتماع بنجاح.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر الحفظ: ${NetworkErrorFormatter.format(error)}')),
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
    if (result == null || result.$1.isEmpty || result.$4.isBefore(result.$3)) {
      return;
    }

    final startDate = result.$3.toIso8601String().split('T').first;
    final endDate = result.$4.toIso8601String().split('T').first;
    await ref
        .read(serviceRepositoryProvider)
        .addReportingPeriod(
          serviceId: widget.serviceId,
          name: result.$1,
          type: result.$2,
          startDate: startDate,
          endDate: endDate,
        );
    /*
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
        );*/
    if (mounted) setState(() {});
  }

  Future<void> _installApp() async {
    if (canPromptToInstall) {
      final installed = await promptToInstall();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            installed ? 'تم تثبيت التطبيق.' : 'يمكنك تثبيت التطبيق من قائمة المتصفح.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة التطبيق إلى الهاتف'),
        content: const Text(
          'على iPhone أو iPad: افتح الصفحة في Safari، واضغط «مشاركة» ثم «إضافة إلى الشاشة الرئيسية»\n\n'
          'على Android: افتح قائمة المتصفح (⋮) ثم اختر «تثبيت التطبيق» أو «إضافة إلى الشاشة الرئيسية».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
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
          final currentThemeMode = ref.watch(themeModeProvider);

          return AppContent(
            maxWidth: 800,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                if (kIsWeb && !isRunningAsInstalledApp)
                  SolidCard(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.install_mobile_rounded,
                                color: Color(0xFF4F46E5), size: 22),
                            SizedBox(width: 10),
                            Text('استخدام التطبيق على الهاتف',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أضف النظام إلى الشاشة الرئيسية لفتحه كتطبيق مستقل.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _installApp,
                          icon: const Icon(Icons.add_to_home_screen_rounded),
                          label: const Text('تثبيت التطبيق'),
                        ),
                      ],
                    ),
                  ),
                // Theme Appearance Card
                SolidCard(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            currentThemeMode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: const Color(0xFF4F46E5),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'المظهر البصري والسمة',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('الوضع الليلي (Dark Mode)'),
                        subtitle: Text(
                          currentThemeMode == ThemeMode.dark
                              ? 'الوضع الليلي مفعّل'
                              : 'الوضع النهاري مفعّل',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Switch(
                          value: currentThemeMode == ThemeMode.dark,
                          onChanged: (isDark) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(
                                  isDark ? ThemeMode.dark : ThemeMode.light,
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Service Details Card
                SolidCard(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.church_rounded,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'بيانات الخدمة والكنيسة',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'اسم الخدمة',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: churchController,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'الكنيسة'),
                      ),
                    ],
                  ),
                ),

                // Meeting Schedule Card
                SolidCard(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'جدول ومواعيد الاجتماع',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('لإضافة أكثر من اجتماع بأسماء وأوقات مستقلة، افتح إعدادات الاجتماعات المتعددة.'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/service/${widget.serviceId}/settings/meetings'),
                          icon: const Icon(Icons.event_repeat_rounded),
                          label: const Text('إدارة الاجتماعات المتعددة'),
                        ),
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_rounded),
                        title: const Text('وقت بدء الاجتماع'),
                        subtitle: Text(
                          meetingTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final value = await showTimePicker(
                              context: context,
                              initialTime: meetingTime,
                            );
                            if (value != null && mounted) {
                              setState(() => meetingTime = value);
                            }
                          },
                          child: const Text('تغيير الوقت'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: earlyAttendanceMinutes,
                        decoration: const InputDecoration(
                          labelText: 'مدة الحضور المبكر',
                          helperText: 'تُحسب من وقت بدء الاجتماع المحدد أعلاه.',
                        ),
                        items: [
                          for (var minutes = 0; minutes <= 60; minutes += 5)
                            DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes دقيقة'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => earlyAttendanceMinutes = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: meetingFrequency,
                        decoration: const InputDecoration(
                          labelText: 'تكرار الاجتماع',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('أسبوعي'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('شهري'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => meetingFrequency = value);
                          }
                        },
                      ),
                      if (meetingFrequency == 'weekly') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: meetingWeekday,
                          decoration: const InputDecoration(
                            labelText: 'يوم الاجتماع',
                          ),
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
                            if (value != null) {
                              setState(() => meetingWeekday = value);
                            }
                          },
                        ),
                      ],
                      if (meetingFrequency == 'monthly') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: meetingMonthDay,
                          decoration: const InputDecoration(
                            labelText: 'يوم الشهر',
                          ),
                          items: [
                            for (var day = 1; day <= 31; day++)
                              DropdownMenuItem(value: day, child: Text('$day')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => meetingMonthDay = value);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: saving ? null : _saveMeetingTime,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          saving ? 'جاري الحفظ...' : 'حفظ جدول وموعد الاجتماع',
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Navigation Cards
                SolidCard(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'الإدارة الهيكلية والنظام',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/service/${widget.serviceId}/settings/structure',
                        ),
                        icon: const Icon(Icons.account_tree_outlined),
                        label: const Text('إدارة المراحل والفصول'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/service/${widget.serviceId}/settings/system',
                        ),
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('إعدادات النظام والحساب'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
            ),
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
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _start : _end;
    final value = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('إضافة فترة'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'اسم الفترة'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'النوع'),
            items: const [
              DropdownMenuItem(value: 'semester', child: Text('ترم')),
              DropdownMenuItem(value: 'service_year', child: Text('سنة خدمة')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
          ListTile(
            title: Text('من: ${_start.toIso8601String().split('T').first}'),
            onTap: () => _pickDate(start: true),
          ),
          ListTile(
            title: Text('إلى: ${_end.toIso8601String().split('T').first}'),
            onTap: () => _pickDate(start: false),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.pop(context, (_name.text.trim(), _type, _start, _end)),
        child: const Text('حفظ'),
      ),
    ],
  );
}
