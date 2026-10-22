import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../service/presentation/service_providers.dart';
import '../../service/domain/repositories/service_repository.dart';
import '../domain/entities/student.dart';
import 'class_students_page.dart';
import 'add_student_page.dart';
import 'student_details_page.dart';
import 'student_providers.dart';
import 'import_students_excel_page.dart';
import '../../../app/ui/app_ui.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  String query = '';
  String statusFilter = 'all';
  String view = 'students';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref
            .read(serviceRepositoryProvider)
            .refreshStages(widget.serviceId);
      } catch (_) {
        // Keep the locally cached stages available while offline.
      }
      try {
        await ref
            .read(studentRepositoryProvider)
            .refreshStudentsForService(widget.serviceId);
      } catch (_) {
        // The roster remains available from the local offline-first store.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(serviceRepositoryProvider);
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
    final isClassScoped =
        (profile?.role == 'class_servant' || profile?.role == 'class_leader') &&
        profile?.classId != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('التلاميذ'),
        actions: [
          IconButton(
            key: const Key('students_import_excel'),
            tooltip: 'استيراد الطلاب من Excel',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ImportStudentsExcelPage(
                  serviceId: widget.serviceId,
                  initialClassId: isClassScoped ? profile!.classId : null,
                ),
              ),
            ),
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            key: const Key('students_add'),
            tooltip: 'إضافة تلميذ',
            onPressed: _addStudent,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),

          IconButton(
            key: const Key('students_refresh'),
            tooltip: 'تحديث',
            onPressed: () async {
              try {
                await repository.refreshStages(widget.serviceId);
                await ref
                    .read(studentRepositoryProvider)
                    .refreshStudentsForService(widget.serviceId);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تعذر تحديث البيانات: $error')),
                );
              }
            },
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.5,
        child: Column(
          children: [
            if (!isClassScoped)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'students',
                      icon: Icon(Icons.groups_rounded),
                      label: Text(
                        'سجل التلاميذ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ButtonSegment(
                      value: 'stages',
                      icon: Icon(Icons.account_tree_outlined),
                      label: Text(
                        'المراحل والفصول',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  selected: {view},
                  onSelectionChanged: (selection) =>
                      setState(() => view = selection.first),
                ),
              ),
            Expanded(
              child: isClassScoped
                  ? _studentRegistry(
                      classId: profile!.classId,
                      classScoped: true,
                    )
                  : view == 'students'
                  ? _studentRegistry()
                  : _stageExplorer(repository),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudent() async {
    final profile = await ref.read(currentServantProfileProvider.future);
    final isClassScoped =
        (profile?.role == 'class_servant' || profile?.role == 'class_leader') &&
        profile?.classId != null;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddStudentPage(
          serviceId: widget.serviceId,
          initialClassId: isClassScoped ? profile!.classId : null,
        ),
      ),
    );
  }

  Widget _studentRegistry({
    String? classId,
    bool classScoped = false,
  }) => StreamBuilder<List<Student>>(
    stream: ref
        .watch(studentRepositoryProvider)
        .watchStudentsForService(widget.serviceId),
    builder: (context, snapshot) {
      final allStudents = snapshot.data ?? const <Student>[];
      final students = classId == null
          ? allStudents
          : allStudents
                .where(
                  (student) =>
                      student.currentClassId == classId ||
                      student.proposedClassId == classId,
                )
                .toList();
      if (snapshot.connectionState == ConnectionState.waiting &&
          students.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError && students.isEmpty) {
        return _empty(
          Icons.cloud_off_rounded,
          'تعذر تحميل سجل التلاميذ',
          'تحقق من الاتصال ثم أعد المحاولة.',
        );
      }
      if (students.isEmpty) {
        return _empty(
          Icons.school_outlined,
          'لا توجد بيانات تلاميذ بعد',
          'ستظهر التلاميذ المسجلون في الخدمة هنا.',
        );
      }

      final filtered = students.where((student) {
        final matchesStatus = switch (statusFilter) {
          'pending' => student.isPending,
          'approved' => student.isApproved,
          _ => true,
        };
        final needle = query.trim().toLowerCase();
        final matchesQuery =
            needle.isEmpty ||
            [
              student.name,
              student.phone ?? '',
              student.school ?? '',
              student.grade ?? '',
            ].any((value) => value.toLowerCase().contains(needle));
        return matchesStatus && matchesQuery;
      }).toList();

      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metric(
                  context,
                  classScoped ? 'تلاميذ الفصل' : 'إجمالي التلاميذ',
                  students.length,
                  Icons.school_rounded,
                  const Color(0xFF4F46E5),
                ),
                _metric(
                  context,
                  'معتمدون',
                  students.where((student) => student.isApproved).length,
                  Icons.verified_rounded,
                  const Color(0xFF10B981),
                ),
                _metric(
                  context,
                  'بانتظار الاعتماد',
                  students.where((student) => student.isPending).length,
                  Icons.pending_actions_rounded,
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
            child: GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(14),
              hoverElevation: false,
              child: Column(
                children: [
                  TextField(
                    key: const Key('service_student_search'),
                    onChanged: (value) => setState(() => query = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'ابحث بالاسم أو الهاتف أو المدرسة أو الصف...',
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => query = ''),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _filter('all', 'الكل', students.length),
                        _filter(
                          'approved',
                          'معتمد',
                          students
                              .where((student) => student.isApproved)
                              .length,
                        ),
                        _filter(
                          'pending',
                          'بانتظار الاعتماد',
                          students.where((student) => student.isPending).length,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
            child: Row(
              children: [
                Text(
                  'النتائج المعروضة',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                GlassBadge(
                  label: '${filtered.length} تلميذ',
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Spacer(),
                Text(
                  classScoped
                      ? 'بيانات الفصل المحفوظة'
                      : 'بيانات الخدمة المحفوظة',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (filtered.isEmpty)
            _empty(
                    Icons.search_off_rounded,
                    'لا توجد نتائج مطابقة',
                    'غيّر كلمات البحث أو حالة الاعتماد.',
                  )
          else
            ...filtered.map(
              (student) => Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
                child: _studentRow(student),
              ),
            ),
        ],
      );
    },
  );

  Widget _studentRow(Student student) {
    final statusColor = student.isApproved
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    final details = [
      if ((student.grade ?? '').isNotEmpty) student.grade!,
      if ((student.school ?? '').isNotEmpty) student.school!,
      if ((student.phone ?? '').isNotEmpty) student.phone!,
    ].join(' • ');

    return GlassCard(
      key: Key('student_item_${student.id}'),
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StudentDetailsPage(student: student)),
      ),
      child: Row(
        children: [
          // Glowing initial avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: student.isApproved
                    ? [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]
                    : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (student.isApproved
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                student.name.isEmpty ? '؟' : student.name.characters.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details.isEmpty ? 'لا توجد بيانات إضافية' : details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          GlassBadge(
            label: student.isApproved ? 'معتمد' : 'بانتظار الاعتماد',
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _stageExplorer(ServiceRepository repository) => StreamBuilder(
    stream: repository.watchStages(widget.serviceId),
    builder: (context, snapshot) {
      final stages = snapshot.data ?? const [];
      if (snapshot.connectionState == ConnectionState.waiting &&
          stages.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError && stages.isEmpty) {
        return _empty(
          Icons.cloud_off_rounded,
          'تعذر تحميل المراحل',
          'تحقق من الاتصال أو حاول مرة أخرى.',
        );
      }
      if (stages.isEmpty) {
        return _empty(
          Icons.account_tree_outlined,
          'لا توجد مراحل محفوظة',
          'حدّث بيانات الخدمة أو أضف المراحل من الإعدادات.',
        );
      }
      return ListView(
        key: const Key('students_stage_list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'اختر مرحلة لاستعراض الفصول',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final stage in stages)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                hoverElevation: false,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: Key('stage_${stage.id}'),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers_outlined,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      stage.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    onExpansionChanged: (expanded) {
                      if (expanded) repository.refreshClasses(stage.id);
                    },
                    children: [
                      StreamBuilder(
                        stream: repository.watchClasses(stage.id),
                        builder: (context, classSnapshot) {
                          final classes = classSnapshot.data ?? const [];
                          if (classSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              classes.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (classes.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Text(
                                'لا توجد فصول محفوظة في هذه المرحلة.',
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final item in classes)
                                ListTile(
                                  key: Key('class_${item.id}'),
                                  leading: const Icon(Icons.groups_outlined),
                                  title: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_left_rounded,
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ClassStudentsPage(
                                        classId: item.id,
                                        className: item.name,
                                        serviceId: widget.serviceId,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _metric(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) => SizedBox(
    width: 220,
    child: GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filter(String value, String label, int count) => ChoiceChip(
    key: Key('student_filter_$value'),
    selected: statusFilter == value,
    label: Text('$label ($count)'),
    onSelected: (_) => setState(() => statusFilter = value),
  );

  Widget _empty(IconData icon, String title, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(32),
        hoverElevation: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
