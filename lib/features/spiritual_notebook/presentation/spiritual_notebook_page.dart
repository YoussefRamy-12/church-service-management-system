import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import '../../../app/ui/app_ui.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../data/spiritual_notebook_repository.dart';
import '../domain/weekly_period.dart';

final spiritualNotebookRepositoryProvider = Provider(
  (ref) => SpiritualNotebookRepository(Supabase.instance.client),
);

class SpiritualNotebookPage extends ConsumerStatefulWidget {
  const SpiritualNotebookPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<SpiritualNotebookPage> createState() =>
      _SpiritualNotebookPageState();
}

class _SpiritualNotebookPageState extends ConsumerState<SpiritualNotebookPage> {
  int tab = 0;
  late Future<_NotebookData> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<_NotebookData> _load() async {
    final repo = ref.read(spiritualNotebookRepositoryProvider);
    final results = await Future.wait([
      repo.students(widget.serviceId),
      repo.activities(widget.serviceId),
      repo.submissions(widget.serviceId),
      repo.settings(widget.serviceId),
    ]);
    return _NotebookData(
      results[0] as List<Map<String, dynamic>>,
      results[1] as List<Map<String, dynamic>>,
      results[2] as List<Map<String, dynamic>>,
      results[3] as Map<String, dynamic>?,
    );
  }

  void refresh() {
    if (!mounted) return;
    final future = _load();
    setState(() {
      data = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentServantProfileProvider).value;
    final isSuper = ref.watch(isSuperAdminProvider);
    final canConfigure = isSuper ||
        profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper';
    final period = WeeklyPeriod.containing(DateTime.now());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<_NotebookData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'تعذر تحميل النوتة الروحية',
              message: '${snap.error}',
              action: OutlinedButton.icon(
                onPressed: refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: LoadingView(message: 'جاري تحميل بيانات النوتة الروحية...'));
        }
        final d = snap.data!;

        return Scaffold(
          body: Column(
            children: [
              // Header Banner with Period Pill
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D33) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: appPrimary.withValues(alpha: isDark ? 0.25 : 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: appPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'النوتة الروحية',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'متابعة وتشجيع الحياة الروحية للتلاميذ',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : appMutedInk,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassBadge(
                      label: period.label,
                      color: appPrimaryContainer,
                      icon: Icons.calendar_month_rounded,
                      showDot: false,
                    ),
                  ],
                ),
              ),

              // Segmented Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: SegmentedButton<int>(
                      segments: [
                        const ButtonSegment(
                          value: 0,
                          label: Text('دفاتر التلاميذ'),
                          icon: Icon(Icons.menu_book_rounded),
                        ),
                        const ButtonSegment(
                          value: 1,
                          label: Text('لوحة الشرف'),
                          icon: Icon(Icons.emoji_events_rounded),
                        ),
                        if (canConfigure)
                          const ButtonSegment(
                            value: 2,
                            label: Text('الإعدادات'),
                            icon: Icon(Icons.settings_rounded),
                          ),
                      ],
                      selected: {tab},
                      onSelectionChanged: (v) => setState(() => tab = v.first),
                    ),
                  ),
                ),
              ),

              // Active Tab Content
              Expanded(
                child: switch (tab) {
                  0 => _StudentList(
                    students: d.students,
                    submissions: d.submissions,
                    period: period,
                    onOpen: (s) => context.go(
                      '/service/${widget.serviceId}/spiritual-notebook/student/${s['id']}',
                    ),
                  ),
                  1 => _Leaderboard(
                    students: d.students,
                    submissions: d.submissions,
                    weekStart: _date(period.start),
                  ),
                  _ => _NotebookSettings(
                    serviceId: widget.serviceId,
                    activities: d.activities,
                    settings: d.settings,
                    onSaved: refresh,
                  ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotebookData {
  const _NotebookData(
    this.students,
    this.activities,
    this.submissions,
    this.settings,
  );
  final List<Map<String, dynamic>> students, activities, submissions;
  final Map<String, dynamic>? settings;
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _StudentList extends StatefulWidget {
  const _StudentList({
    required this.students,
    required this.submissions,
    required this.period,
    required this.onOpen,
  });
  final List<Map<String, dynamic>> students, submissions;
  final WeeklyPeriod period;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  State<_StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<_StudentList> {
  String query = '';
  int statusFilter = 0; // 0 = all, 1 = registered, 2 = not registered
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.submissions.where(
      (r) => r['period_start'] == _date(widget.period.start),
    );
    final thisWeek = {
      for (final r in current) r['student_id']: r['total_points'] as int,
    };
    final totals = <String, int>{};
    for (final r in widget.submissions) {
      totals.update(
        r['student_id'] as String,
        (v) => v + (r['total_points'] as int),
        ifAbsent: () => r['total_points'] as int,
      );
    }

    final filteredStudents = widget.students.where((s) {
      final matchesQuery = (s['name'] as String)
          .toLowerCase()
          .contains(query.toLowerCase());
      if (!matchesQuery) return false;

      final isDone = thisWeek.containsKey(s['id']);
      if (statusFilter == 1 && !isDone) return false;
      if (statusFilter == 2 && isDone) return false;

      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 650;
              final searchWidget = AppSearchField(
                controller: searchController,
                hintText: 'ابحث باسم التلميذ...',
                onChanged: (v) => setState(() => query = v),
              );
              final filterWidget = SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('الكل')),
                  ButtonSegment(value: 1, label: Text('المسجلون')),
                  ButtonSegment(value: 2, label: Text('بانتظار التسجيل')),
                ],
                selected: {statusFilter},
                onSelectionChanged: (v) =>
                    setState(() => statusFilter = v.first),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchWidget,
                    const SizedBox(height: 10),
                    Center(child: filterWidget),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchWidget),
                  const SizedBox(width: 12),
                  filterWidget,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredStudents.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لم يتم العثور على تلاميذ',
                    message: query.isNotEmpty
                        ? 'لا يوجد تلميذ يطابق بحثك "$query"'
                        : 'لا يوجد تلاميذ في هذه القائمة حالياً.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, i) {
                    final s = filteredStudents[i];
                    final cls = s['classes'] as Map<String, dynamic>?;
                    final stage = cls?['stages'] as Map<String, dynamic>?;
                    final done = thisWeek.containsKey(s['id']);
                    final studentName = s['name'] as String;
                    final weekPoints = thisWeek[s['id']] ?? 0;
                    final totalPoints = totals[s['id']] ?? 0;

                    return SolidCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: 14,
                      child: InkWell(
                        onTap: () => widget.onOpen(s),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            // Initial Avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: appPrimary.withValues(alpha: 0.12),
                              foregroundColor: appPrimary,
                              child: Text(
                                studentName.trim().isNotEmpty
                                    ? studentName.trim().characters.first
                                    : 'ت',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (done)
                                        const GlassBadge(
                                          label: 'تم التسجيل',
                                          color: appSuccess,
                                        )
                                      else
                                        const GlassBadge(
                                          label: 'بانتظار التسجيل',
                                          color: appWarning,
                                          showDot: true,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cls?['name'] ?? '—'} • ${stage?['name'] ?? '—'}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Points badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'الأسبوع: $weekPoints ن',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: done ? appSuccess : appMutedInk,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'الإجمالي: $totalPoints ن',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: appMutedInk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_left_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class SpiritualNotebookStudentPage extends ConsumerStatefulWidget {
  const SpiritualNotebookStudentPage({
    super.key,
    required this.serviceId,
    required this.studentId,
  });
  final String serviceId, studentId;

  @override
  ConsumerState<SpiritualNotebookStudentPage> createState() =>
      _SpiritualNotebookStudentPageState();
}

class _SpiritualNotebookStudentPageState
    extends ConsumerState<SpiritualNotebookStudentPage> {
  late Future<_StudentFormData> data;
  final selected = <String>{};
  final bonus = TextEditingController();
  final reason = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  Future<_StudentFormData> _load() async {
    final client = Supabase.instance.client;
    final repo = ref.read(spiritualNotebookRepositoryProvider);
    final results = await Future.wait<dynamic>([
      client
          .from('students')
          .select('id,name,current_class_id,classes!students_current_class_id_fkey(name,stages(name))')
          .eq('id', widget.studentId)
          .single(),
      repo.activities(widget.serviceId),
      repo.submissions(widget.serviceId),
      repo.settings(widget.serviceId),
    ]);
    final period = WeeklyPeriod.containing(DateTime.now());
    final existing = (results[2] as List<Map<String, dynamic>>)
        .where(
          (r) =>
              r['student_id'] == widget.studentId &&
              r['period_start'] == _date(period.start),
        )
        .firstOrNull;
    return _StudentFormData(
      results[0] as Map<String, dynamic>,
      results[1] as List<Map<String, dynamic>>,
      existing,
      results[3] as Map<String, dynamic>?,
    );
  }

  @override
  void dispose() {
    bonus.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentServantProfileProvider).value?.role;
    final period = WeeklyPeriod.containing(DateTime.now());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<_StudentFormData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر فتح الدفتر',
                message: '${snap.error}',
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: LoadingView(message: 'جاري فتح دفتر التلميذ...')),
          );
        }
        final d = snap.data!;
        final cls = d.student['classes'] as Map<String, dynamic>?;
        final stage = cls?['stages'] as Map<String, dynamic>?;
        final existing = d.existing;
        final bonusAllowed =
            (d.settings?['bonus_roles'] as List<dynamic>? ?? []).contains(role);
        final maxBonus = (d.settings?['max_bonus_points'] as int?) ?? 0;
        final b = int.tryParse(bonus.text) ?? 0;
        final selectedPoints = d.activities
            .where((a) => selected.contains(a['id']))
            .fold<int>(0, (sum, a) => sum + (a['points'] as int));
        final grandTotal = selectedPoints + (bonusAllowed ? b : 0);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع',
              onPressed: () => context.pop(),
            ),
            title: const Text('دفتر التلميذ الروحي'),
          ),
          body: AppContent(
            maxWidth: 720,
            child: ListView(
              children: [
                // Student Profile Header Card
                SolidCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: appPrimary.withValues(alpha: 0.12),
                        foregroundColor: appPrimary,
                        child: Text(
                          (d.student['name'] as String).trim().characters.first,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.student['name'] as String,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cls?['name'] ?? '—'} • ${stage?['name'] ?? '—'}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassBadge(
                        label: period.label,
                        color: appPrimaryContainer,
                        icon: Icons.calendar_today_rounded,
                        showDot: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (existing != null) ...[
                  StatusBanner(
                    icon: Icons.lock_rounded,
                    tone: StatusTone.success,
                    title: 'تم تسجيل النوتة لهذا الأسبوع',
                    message:
                        'تم رصد ${existing['total_points']} نقطة للتلميذ في هذا الأسبوع.\nتاريخ الحفظ: ${existing['submitted_at'] ?? '—'}',
                  ),
                ] else ...[
                  const ModernSectionHeader(
                    title: 'الأنشطة الروحية',
                    subtitle: 'حدد الأنشطة التي قام بها التلميذ خلال الأسبوع',
                  ),
                  const SizedBox(height: 8),

                  if (d.activities.isEmpty)
                    const SolidCard(
                      child: Text('لا توجد أنشطة روحية مفعلة حالياً في النظام.'),
                    ),

                  for (final a in d.activities) ...[
                    Builder(
                      builder: (context) {
                        final isChecked = selected.contains(a['id']);
                        return SolidCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: isChecked
                              ? appPrimary.withValues(alpha: isDark ? 0.12 : 0.05)
                              : null,
                          border: isChecked
                              ? Border.all(color: appPrimaryContainer, width: 1.5)
                              : null,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: isChecked,
                            onChanged: (v) => setState(
                              () => v == true
                                  ? selected.add(a['id'] as String)
                                  : selected.remove(a['id'] as String),
                            ),
                            title: Text(
                              a['name'] as String,
                              style: TextStyle(
                                fontWeight: isChecked ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                            subtitle: a['description'] != null
                                ? Text(a['description'].toString())
                                : null,
                            secondary: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: appPrimaryContainer.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${a['points']} ن',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: appPrimaryContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  if (bonusAllowed) ...[
                    const SizedBox(height: 16),
                    SolidCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ModernSectionHeader(
                            title: 'نقاط تشجيعية إضافية',
                            subtitle: 'يمكنك إضافة نقاط إضافية بناء على سلوك أو تميز التلميذ',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: bonus,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'النقاط (أقصى $maxBonus)',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: reason,
                                  decoration: const InputDecoration(
                                    labelText: 'سبب الإضافة (مطلوب عند وضع نقاط)',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Summary Card with Confirm Action
                  SolidCard(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(20),
                    color: isDark ? const Color(0xFF1E293B) : appSoftBlue,
                    border: Border.all(color: appPrimary.withValues(alpha: 0.25)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مجموع نقاط الأسبوع',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: appMutedInk,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$grandTotal نقطة',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                  color: appPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (selected.isEmpty &&
                                      (d.settings?['allow_zero_submissions'] != true)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('اختر نشاطاً واحداً على الأقل'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (b < 0 ||
                                      b > maxBonus ||
                                      (b > 0 && reason.text.trim().isEmpty)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تحقق من النقاط الإضافية وسببها'),
                                      ),
                                    );
                                    return;
                                  }
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('تأكيد رصد النوتة الروحية'),
                                      content: Text(
                                        'هل تود اعتماد $grandTotal نقطة للتلميذ لهذا الأسبوع؟\nيرجى الملاحظة أنه لا يمكن تعديل السجل بعد الاعتماد.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          child: const Text('مراجعة'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('تأكيد واعتماد'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true) return;
                                  setState(() => saving = true);
                                  try {
                                    await ref
                                        .read(spiritualNotebookRepositoryProvider)
                                        .submit(
                                          studentId: widget.studentId,
                                          period: period,
                                          activityIds: selected.toList(),
                                          bonusPoints: bonusAllowed ? b : 0,
                                          bonusReason: reason.text.trim(),
                                        );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم اعتماد النوتة الروحية بنجاح'),
                                        ),
                                      );
                                      final future = _load();
                                      setState(() {
                                        data = future;
                                      });
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('تعذر التسجيل: $e')),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => saving = false);
                                  }
                                },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(saving ? 'جارٍ الاعتماد...' : 'اعتماد وحفظ السجل'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StudentFormData {
  const _StudentFormData(
    this.student,
    this.activities,
    this.existing,
    this.settings,
  );
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? existing, settings;
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({
    required this.students,
    required this.submissions,
    required this.weekStart,
  });
  final List<Map<String, dynamic>> students, submissions;
  final String weekStart;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: const TabBar(
              tabs: [
                Tab(text: 'لوحة شرف الأسبوع'),
                Tab(text: 'الترتيب الإجمالي العام'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _rows(context, weekly: true),
                _rows(context, weekly: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rows(BuildContext context, {required bool weekly}) {
    final scores = <String, int>{};
    for (final r in submissions) {
      if (!weekly || r['period_start'] == weekStart) {
        scores.update(
          r['student_id'] as String,
          (v) => v + (r['total_points'] as int),
          ifAbsent: () => r['total_points'] as int,
        );
      }
    }
    final sorted = [...students]
      ..sort((a, b) => (scores[b['id']] ?? 0).compareTo(scores[a['id']] ?? 0));

    if (sorted.isEmpty || scores.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'لا توجد بيانات شرف بعد',
          message: 'ابدأ برصد درجات النوتة الروحية للتلاميذ لتظهر أسمائهم هنا.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final s = sorted[i];
        final rank = i + 1;
        final studentName = s['name'] as String;
        final score = scores[s['id']] ?? 0;

        // Rank badge & medal colors
        final (Color badgeColor, String rankEmoji) = switch (rank) {
          1 => (const Color(0xFFEAB308), '🥇'),
          2 => (const Color(0xFF94A3B8), '🥈'),
          3 => (const Color(0xFFD97706), '🥉'),
          _ => (appPrimaryContainer, '$rank'),
        };

        return SolidCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 14,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  rankEmoji,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: appPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$score نقطة',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: appPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotebookSettings extends ConsumerWidget {
  const _NotebookSettings({
    required this.serviceId,
    required this.activities,
    required this.settings,
    required this.onSaved,
  });

  final String serviceId;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? settings;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final points = TextEditingController();
    final max = TextEditingController(
      text: '${settings?['max_bonus_points'] ?? 0}',
    );
    final roles = (settings?['bonus_roles'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    const available = [
      'overall_leader',
      'overall_helper',
      'stage_leader',
      'class_leader',
      'class_servant',
    ];

    return AppContent(
      maxWidth: 800,
      child: ListView(
        children: [
          // Current Activities Section
          SolidCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernSectionHeader(
                  title: 'الأنشطة الروحية المفعلة',
                  subtitle: 'قائمة الأنشطة المتاحة للتسجيل أسبوعياً',
                  badge: GlassBadge(
                    label: '${activities.length} نشاط',
                    color: appPrimaryContainer,
                    showDot: false,
                  ),
                ),
                const SizedBox(height: 12),
                if (activities.isEmpty)
                  const Text('لم تتم إضافة أنشطة روحية بعد.')
                else
                  for (final a in activities)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: appSoftBlue.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: appSuccess, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              a['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: appPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${a['points']} نقاط',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: appPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: appPrimary,
                            tooltip: 'تعديل النشاط',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showEditActivityDialog(context, ref, a),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            color: appError,
                            tooltip: 'حذف النشاط',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showDeleteActivityDialog(context, ref, a),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'إضافة نشاط روحي جديد',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 600;
                    final nameField = TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'اسم النشاط (مثلاً: قراءة الإنجيل)'),
                    );
                    final pointsField = TextField(
                      controller: points,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'النقاط'),
                    );
                    final addButton = FilledButton.icon(
                      onPressed: () async {
                        final p = int.tryParse(points.text);
                        if (name.text.trim().isEmpty || p == null || p < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('أدخل اسم النشاط وعدد نقاط صالح')),
                          );
                          return;
                        }
                        try {
                          await ref
                              .read(spiritualNotebookRepositoryProvider)
                              .addActivity(serviceId, name.text.trim(), p);
                          name.clear();
                          points.clear();
                          onSaved();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر الحفظ: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة'),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          nameField,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: pointsField),
                              const SizedBox(width: 10),
                              addButton,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 3, child: nameField),
                        const SizedBox(width: 10),
                        Expanded(flex: 1, child: pointsField),
                        const SizedBox(width: 10),
                        addButton,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bonus & Roles Section
          SolidCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernSectionHeader(
                  title: 'قواعد النقاط الإضافية',
                  subtitle: 'حدد سقف النقاط الإضافية والأدوار المخول لها الإضافة',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: max,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الحد الأقصى للنقاط الإضافية',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        final value = int.tryParse(max.text);
                        if (value == null || value < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('أدخل حداً صحيحاً للنقاط')),
                          );
                          return;
                        }
                        try {
                          await ref
                              .read(spiritualNotebookRepositoryProvider)
                              .upsertSettings(
                                serviceId,
                                maxBonus: value,
                                bonusRoles: roles.toList(),
                              );
                          onSaved();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حفظ إعدادات النقاط بنجاح')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر الحفظ: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('حفظ الحد الأقصى'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'الأدوار المسموح لها بمنح نقاط إضافية:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: available.map((r) {
                    final isChecked = roles.contains(r);
                    return FilterChip(
                      selected: isChecked,
                      label: Text(_role(r)),
                      onSelected: (v) async {
                        if (v) {
                          roles.add(r);
                        } else {
                          roles.remove(r);
                        }
                        final m = int.tryParse(max.text) ?? 0;
                        try {
                          await ref
                              .read(spiritualNotebookRepositoryProvider)
                              .upsertSettings(
                                serviceId,
                                maxBonus: m,
                                bonusRoles: roles.toList(),
                              );
                          onSaved();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر الحفظ: $e')),
                            );
                          }
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _role(String r) => switch (r) {
    'overall_leader' => 'مسؤول الخدمة',
    'overall_helper' => 'مساعد مسؤول الخدمة',
    'stage_leader' => 'مسؤول المرحلة',
    'class_leader' => 'أمين الفصل',
    _ => 'خادم الفصل',
  };

  Future<void> _showEditActivityDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> activity,
  ) async {
    final editName = TextEditingController(text: activity['name'] as String? ?? '');
    final editPoints = TextEditingController(text: '${activity['points'] ?? 0}');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: appPrimary),
              SizedBox(width: 8),
              Text(
                'تعديل النشاط الروحي',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: editName,
                    decoration: const InputDecoration(
                      labelText: 'اسم النشاط الروحي',
                      hintText: 'مثلاً: صلاة باكر',
                      prefixIcon: Icon(Icons.bookmark_outline_rounded),
                    ),
                    autofocus: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم النشاط';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: editPoints,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'النقاط',
                      hintText: 'مثلاً: 5',
                      prefixIcon: Icon(Icons.stars_rounded),
                    ),
                    validator: (v) {
                      final p = int.tryParse(v ?? '');
                      if (p == null || p < 0) {
                        return 'يرجى إدخال عدد نقاط صحيح (0 أو أكثر)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: appPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ملاحظة: تعديل النقاط ينطبق على الأسابيع والتسجيلات القادمة، مع بقاء درجات الأسابيع السابقة المسجلة للطلاب كما هي دون تغيير.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final p = int.parse(editPoints.text.trim());
      try {
        await ref.read(spiritualNotebookRepositoryProvider).updateActivity(
              activityId: activity['id'] as String,
              name: editName.text.trim(),
              points: p,
            );
        onSaved();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث النشاط الروحي بنجاح'),
              backgroundColor: appSuccess,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر تعديل النشاط: $e'),
              backgroundColor: appError,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteActivityDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> activity,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: appError),
              SizedBox(width: 8),
              Text(
                'حذف النشاط الروحي',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل أنت متأكد من حذف النشاط «${activity['name']}»؟',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appSuccess.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: appSuccess.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, size: 20, color: appSuccess),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'حفظ الدرجات السابقة:\nسيتم حذف النشاط من قائمة الأنشطة المتاحة للتسجيل في الأسابيع القادمة، مع الاحتفاظ الكامل بجميع درجات وسجلات الأسابيع السابقة المحسوبة للتلاميذ دون أي تغيير.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF0F5132),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: appError,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تأكيد الحذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(spiritualNotebookRepositoryProvider).deleteActivity(
              activity['id'] as String,
            );
        onSaved();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف النشاط بنجاح مع الحفاظ على درجات الأسابيع السابقة'),
              backgroundColor: appSuccess,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر حذف النشاط: $e'),
              backgroundColor: appError,
            ),
          );
        }
      }
    }
  }
}
