import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/app_colors.dart';
import '../../../app/ui/app_ui.dart';
import '../../../app/ui/components/empty_state.dart' as comp;
import '../../../app/ui/components/error_state.dart';
import '../../../app/ui/components/status_chip.dart';
import '../../../app/ui/responsive.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/domain/repositories/service_repository.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/entities/student.dart';
import 'add_student_page.dart';
import 'class_students_page.dart';
import 'import_students_excel_page.dart';
import 'student_details_page.dart';
import 'student_providers.dart';

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  String query = '';
  String statusFilter = 'all';
  String view = 'students';
  String _sortColumn = 'name';
  bool _sortAscending = true;
  Map<String, String> _classDisplayNames = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadClassNames();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClassNames() async {
    try {
      final serviceRepo = ref.read(serviceRepositoryProvider);
      final stages = await serviceRepo.getStages(widget.serviceId);
      final map = <String, String>{};
      for (final stage in stages) {
        final classes = await serviceRepo.getClasses(stage.id);
        for (final c in classes) {
          map[c.id] = '${stage.name} • ${c.name}';
        }
      }
      if (mounted) {
        setState(() => _classDisplayNames = map);
      }
    } catch (_) {}
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
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
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
                await _loadClassNames();
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
    await Navigator.of(context, rootNavigator: true).push(
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
            return const LoadingView(message: 'جاري تحميل سجل التلاميذ...');
          }

          if (snapshot.hasError && students.isEmpty) {
            return ErrorState(
              message:
                  'تعذر تحميل سجل التلاميذ. تحقق من الاتصال ثم أعد المحاولة.',
              onRetry: () {
                ref
                    .read(studentRepositoryProvider)
                    .refreshStudentsForService(widget.serviceId);
              },
            );
          }

          if (students.isEmpty) {
            return comp.EmptyState(
              icon: Icons.school_outlined,
              title: 'لا يوجد تلاميذ في هذه الخدمة',
              message: 'ستظهر بيانات التلاميذ هنا بعد تسجيلهم أو استيرادهم.',
              action: OutlinedButton.icon(
                key: const Key('empty_add_student_button'),
                onPressed: _addStudent,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('إضافة تلميذ'),
              ),
            );
          }

          final needle = query.trim().toLowerCase();
          final filtered = students.where((student) {
            final matchesStatus = switch (statusFilter) {
              'pending' => student.isPending,
              'approved' => student.isApproved,
              _ => true,
            };
            final matchesQuery = needle.isEmpty ||
                student.name.toLowerCase().contains(needle) ||
                (student.phone ?? '').contains(needle) ||
                (student.school ?? '').toLowerCase().contains(needle) ||
                (student.grade ?? '').toLowerCase().contains(needle);
            return matchesStatus && matchesQuery;
          }).toList();

          // Sort filtered list
          filtered.sort((a, b) {
            int cmp = 0;
            switch (_sortColumn) {
              case 'class':
                final aClass = _classDisplayNames[
                        a.currentClassId ?? a.proposedClassId] ??
                    '';
                final bClass = _classDisplayNames[
                        b.currentClassId ?? b.proposedClassId] ??
                    '';
                cmp = aClass.compareTo(bClass);
                if (cmp == 0) cmp = a.name.compareTo(b.name);
                break;
              case 'status':
                final aStatus = a.isApproved ? 1 : 0;
                final bStatus = b.isApproved ? 1 : 0;
                cmp = aStatus.compareTo(bStatus);
                if (cmp == 0) cmp = a.name.compareTo(b.name);
                break;
              case 'name':
              default:
                cmp = a.name.compareTo(b.name);
                break;
            }
            return _sortAscending ? cmp : -cmp;
          });

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const Key('service_student_search'),
                          controller: _searchController,
                          onChanged: (value) => setState(() => query = value),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: 'ابحث بالاسم أو الهاتف...',
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => query = '');
                                    },
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
                                students
                                    .where((student) => student.isPending)
                                    .length,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'النتائج (${filtered.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  معتمد: ${students.where((student) => student.isApproved).length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_done_outlined,
                          size: 14,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          classScoped ? 'فصل محفوظ محليًا' : 'سجل محفوظ محليًا',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: comp.EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا توجد نتائج مطابقة',
                    message:
                        'لم يتم العثور على أي تلميذ يطابق كلمات البحث أو حالة الاعتماد.',
                    action: OutlinedButton.icon(
                      key: const Key('clear_student_search'),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          query = '';
                          statusFilter = 'all';
                        });
                      },
                      icon: const Icon(Icons.clear_all_rounded),
                      label: const Text('إعادة ضبط البحث'),
                    ),
                  ),
                )
              else if (context.isMobile)
                ...filtered.map(
                  (student) => Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
                    child: _studentCard(student),
                  ),
                )
              else
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
                  child: _studentDesktopTable(filtered),
                ),
            ],
          );
        },
      );

  Widget _studentCard(Student student) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final primary = scheme.primary;
    final classLabel = _classDisplayNames[
            student.currentClassId ?? student.proposedClassId] ??
        (student.grade != null && student.grade!.isNotEmpty
            ? student.grade!
            : 'غير مسجل');

    return Card(
      key: Key('student_item_${student.id}'),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StudentDetailsPage(student: student),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Text(
                  student.name.isEmpty ? '؟' : student.name.characters.first,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 3),
                    Text(
                      classLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (student.phone != null &&
                        student.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        student.phone!,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                status:
                    student.isPending ? AppStatus.pending : AppStatus.present,
                label: student.isPending ? 'بانتظار الاعتماد' : 'معتمد',
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentDesktopTable(List<Student> students) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 40,
          ),
          child: DataTable(
            sortColumnIndex: switch (_sortColumn) {
              'name' => 0,
              'class' => 1,
              'status' => 2,
              _ => null,
            },
            sortAscending: _sortAscending,
            headingRowColor: WidgetStatePropertyAll(
              theme.brightness == Brightness.dark
                  ? AppDesignColors.darkSurfaceSubtle
                  : AppDesignColors.lightSurfaceSubtle,
            ),
            columns: [
              DataColumn(
                label: const Text('الاسم',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onSort: (columnIndex, ascending) {
                  setState(() {
                    _sortColumn = 'name';
                    _sortAscending = ascending;
                  });
                },
              ),
              DataColumn(
                label: const Text('المرحلة والفصل',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onSort: (columnIndex, ascending) {
                  setState(() {
                    _sortColumn = 'class';
                    _sortAscending = ascending;
                  });
                },
              ),
              DataColumn(
                label: const Text('الحالة',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onSort: (columnIndex, ascending) {
                  setState(() {
                    _sortColumn = 'status';
                    _sortAscending = ascending;
                  });
                },
              ),
              const DataColumn(
                label: Text('الهاتف',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const DataColumn(
                label: Text('', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
            rows: students.map((student) {
              final classLabel = _classDisplayNames[
                      student.currentClassId ?? student.proposedClassId] ??
                  (student.grade != null && student.grade!.isNotEmpty
                      ? student.grade!
                      : 'غير مسجل');
              return DataRow(
                key: ValueKey('student_item_${student.id}'),
                onSelectChanged: (_) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentDetailsPage(student: student),
                    ),
                  );
                },
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              scheme.primary.withValues(alpha: 0.12),
                          child: Text(
                            student.name.isEmpty
                                ? '؟'
                                : student.name.characters.first,
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          student.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(classLabel)),
                  DataCell(
                    StatusChip(
                      status: student.isPending
                          ? AppStatus.pending
                          : AppStatus.present,
                      label: student.isPending ? 'بانتظار الاعتماد' : 'معتمد',
                    ),
                  ),
                  DataCell(
                    Text(
                      student.phone != null && student.phone!.isNotEmpty
                          ? student.phone!
                          : 'غير مسجل',
                    ),
                  ),
                  DataCell(
                    Icon(
                      Icons.chevron_left_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _stageExplorer(ServiceRepository repository) => StreamBuilder(
        stream: repository.watchStages(widget.serviceId),
        builder: (context, snapshot) {
          final stages = snapshot.data ?? const [];
          if (snapshot.connectionState == ConnectionState.waiting &&
              stages.isEmpty) {
            return const LoadingView(message: 'جاري تحميل المراحل والفصول...');
          }
          if (snapshot.hasError && stages.isEmpty) {
            return ErrorState(
              message: 'تعذر تحميل المراحل. تحقق من الاتصال أو حاول مرة أخرى.',
              onRetry: () => repository.refreshStages(widget.serviceId),
            );
          }
          if (stages.isEmpty) {
            return const comp.EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'لا توجد مراحل محفوظة',
              message: 'حدّث بيانات الخدمة أو أضف المراحل من الإعدادات.',
            );
          }
          final primary = Theme.of(context).colorScheme.primary;

          return ListView(
            key: const Key('students_stage_list'),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                'اختر مرحلة لاستعراض الفصول',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final stage in stages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: Key('stage_${stage.id}'),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.layers_outlined,
                            color: primary,
                            size: 20,
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
                                      leading:
                                          const Icon(Icons.groups_outlined),
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

  Widget _filter(String value, String label, int count) => ChoiceChip(
        key: Key('student_filter_$value'),
        selected: statusFilter == value,
        label: Text('$label ($count)'),
        onSelected: (_) => setState(() => statusFilter = value),
      );
}
