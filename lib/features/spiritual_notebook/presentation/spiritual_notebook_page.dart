import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void refresh() => setState(() => data = _load());

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentServantProfileProvider).value;
    final canConfigure = profile?.role == 'overall_leader';
    final period = WeeklyPeriod.containing(DateTime.now());
    return FutureBuilder<_NotebookData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'تعذر تحميل النوتة الروحية\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'النوتة الروحية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(period.label),
                ],
              ),
            ),
            SegmentedButton<int>(
              segments: [
                const ButtonSegment(
                  value: 0,
                  label: Text('دفاتر التلاميذ'),
                  icon: Icon(Icons.menu_book),
                ),
                const ButtonSegment(
                  value: 1,
                  label: Text('لوحة النقاط'),
                  icon: Icon(Icons.emoji_events),
                ),
                if (canConfigure)
                  const ButtonSegment(
                    value: 2,
                    label: Text('الإعدادات'),
                    icon: Icon(Icons.settings),
                  ),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
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
    final students = widget.students
        .where(
          (s) =>
              (s['name'] as String).toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث عن تلميذ',
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const Center(child: Text('لا يوجد تلاميذ'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final s = students[i];
                    final cls = s['classes'] as Map<String, dynamic>?;
                    final stage = cls?['stages'] as Map<String, dynamic>?;
                    final done = thisWeek.containsKey(s['id']);
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(s['name'] as String),
                      subtitle: Text(
                        '${cls?['name'] ?? '—'} • ${stage?['name'] ?? '—'}\n${done ? 'تم التسجيل هذا الأسبوع' : 'لم يتم التسجيل'}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('الأسبوع ${thisWeek[s['id']] ?? 0}'),
                          Text('الإجمالي ${totals[s['id']] ?? 0}'),
                        ],
                      ),
                      onTap: () => widget.onOpen(s),
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
          .select('id,name,current_class_id,classes(name,stages(name))')
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
    return FutureBuilder<_StudentFormData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('تعذر فتح الدفتر: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
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
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    d.student['name'] as String,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            Text('${cls?['name'] ?? '—'} • ${stage?['name'] ?? '—'}'),
            Text('الأسبوع ${period.label}'),
            const Divider(height: 32),
            if (existing != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('تم تسجيل هذا الأسبوع'),
                  subtitle: Text(
                    'النقاط: ${existing['total_points']} • ${existing['submitted_at']}',
                  ),
                ),
              )
            else ...[
              if (d.activities.isEmpty)
                const Text('لا توجد أنشطة مفعّلة حالياً.'),
              ...d.activities.map(
                (a) => CheckboxListTile(
                  value: selected.contains(a['id']),
                  onChanged: (v) => setState(
                    () => v == true
                        ? selected.add(a['id'] as String)
                        : selected.remove(a['id'] as String),
                  ),
                  title: Text(a['name'] as String),
                  subtitle: Text(
                    '${a['description'] ?? ''}${a['description'] == null ? '' : ' • '} ${a['points']} نقطة',
                  ),
                ),
              ),
              if (bonusAllowed) ...[
                TextField(
                  controller: bonus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'نقاط إضافية (الحد الأقصى $maxBonus)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'سبب الإضافة'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'المجموع: ${selectedPoints + (bonusAllowed ? b : 0)} نقطة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
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
                            title: const Text('تأكيد التسجيل'),
                            content: Text(
                              'تسجيل ${selectedPoints + (bonusAllowed ? b : 0)} نقطة لهذا الأسبوع؟ لن يمكن تعديل السجل بعد الحفظ.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('مراجعة'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('تأكيد'),
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
                                content: Text('تم تسجيل النوتة بنجاح'),
                              ),
                            );
                            setState(() => data = _load());
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
                icon: const Icon(Icons.lock_outline),
                label: Text(saving ? 'جارٍ التسجيل' : 'تأكيد وإغلاق الدفتر'),
              ),
            ],
          ],
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
          const TabBar(
            tabs: [
              Tab(text: 'هذا الأسبوع'),
              Tab(text: 'الإجمالي'),
            ],
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
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, i) => ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text(sorted[i]['name'] as String),
        trailing: Text('${scores[sorted[i]['id']] ?? 0} نقطة'),
      ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'إدارة الأنشطة',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        ...activities.map(
          (a) => ListTile(
            title: Text(a['name'] as String),
            trailing: Text('${a['points']} نقطة'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'اسم النشاط'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: points,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'النقاط'),
              ),
            ),
            IconButton(
              onPressed: () async {
                final p = int.tryParse(points.text);
                if (name.text.trim().isEmpty || p == null || p < 0) {
                  return;
                }
                try {
                  await ref
                      .read(spiritualNotebookRepositoryProvider)
                      .addActivity(serviceId, name.text, p);
                  name.clear();
                  points.clear();
                  onSaved();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
                  }
                }
              },
              icon: const Icon(Icons.add_circle),
            ),
          ],
        ),
        const Divider(),
        TextField(
          controller: max,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'أقصى نقاط إضافية'),
        ),
        const Text('الأدوار المسموح لها بإضافة نقاط'),
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
                  const SnackBar(content: Text('تم حفظ إعدادات النوتة')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
              }
            }
          },
          child: const Text('حفظ إعدادات النقاط'),
        ),
        ...available.map(
          (r) => CheckboxListTile(
            value: roles.contains(r),
            title: Text(_role(r)),
            onChanged: (v) async {
              if (v == true) {
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('تعذر الحفظ: $e')));
                }
              }
            },
          ),
        ),
      ],
    );
  }

  String _role(String r) => switch (r) {
    'overall_leader' => 'مسؤول الخدمة',
    'overall_helper' => 'مساعد مسؤول الخدمة',
    'stage_leader' => 'مسؤول المرحلة',
    'class_leader' => 'أمين الفصل',
    _ => 'خادم الفصل',
  };
}
