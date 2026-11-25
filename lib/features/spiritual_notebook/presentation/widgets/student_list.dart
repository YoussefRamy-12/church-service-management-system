part of '../spiritual_notebook_page.dart';

class _StudentList extends StatefulWidget {
  const _StudentList({required this.students, required this.submissions, required this.period, required this.isMobile, required this.onOpen});
  final List<Map<String, dynamic>> students, submissions;
  final WeeklyPeriod period;
  final bool isMobile;
  final void Function(Map<String, dynamic>, List<String>, int) onOpen;
  @override
  State<_StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<_StudentList> {
  String query = '';
  int statusFilter = 2;
  String? selectedClassId;
  final searchController = TextEditingController();
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final week = _date(widget.period.start);
    final weekSubs = widget.submissions.where((r) => r['period_start'] == week);
    final points = <String, int>{for (final row in weekSubs) row['student_id'] as String: row['total_points'] as int? ?? 0};
    final classMap = <String, String>{};
    final classCounts = <String, int>{};
    for (final student in widget.students) {
      final cls = student['classes'] as Map<String, dynamic>?;
      final id = student['current_class_id'] as String? ?? cls?['id'] as String? ?? 'unassigned';
      classMap[id] = cls?['name'] as String? ?? 'بدون فصل';
      classCounts[id] = (classCounts[id] ?? 0) + 1;
    }
    final classes = classMap.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final scoped = selectedClassId == null ? widget.students : widget.students.where((s) {
      final cls = s['classes'] as Map<String, dynamic>?;
      return (s['current_class_id'] as String? ?? cls?['id'] as String? ?? 'unassigned') == selectedClassId;
    }).toList();
    final registered = scoped.where((s) => points.containsKey(s['id'])).length;
    final pending = scoped.length - registered;
    final matches = scoped.where((s) {
      final cls = s['classes'] as Map<String, dynamic>?;
      final q = query.trim().toLowerCase();
      if (!(('${s['name'] ?? ''}').toLowerCase().contains(q) || ('${cls?['name'] ?? ''}').toLowerCase().contains(q))) return false;
      final done = points.containsKey(s['id']);
      return statusFilter == 0 || (statusFilter == 1 && done) || (statusFilter == 2 && !done);
    }).toList();
    final pendingQueue = scoped.where((s) {
      final cls = s['classes'] as Map<String, dynamic>?;
      final q = query.trim().toLowerCase();
      return !points.containsKey(s['id']) && (('${s['name'] ?? ''}').toLowerCase().contains(q) || ('${cls?['name'] ?? ''}').toLowerCase().contains(q));
    }).toList();
    final queueIds = pendingQueue.map((s) => s['id'] as String).toList();

    return Column(children: [
      Padding(
        padding: EdgeInsetsDirectional.fromSTEB(widget.isMobile ? 12 : 20, 4, widget.isMobile ? 12 : 20, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: SizedBox(height: 48, child: AppSearchField(controller: searchController, hintText: 'ابحث باسم التلميذ أو الفصل...', onChanged: (v) => setState(() => query = v)))),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48), padding: const EdgeInsetsDirectional.symmetric(horizontal: 10)),
              onPressed: () => _showClassFilterSheet(context, classes, classCounts),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 105), child: Text('الفصل: ${selectedClassId == null ? 'الكل' : classMap[selectedClassId] ?? 'الفصل'}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 3), const Icon(Icons.expand_more_rounded, size: 18),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _filterChip(label: 'بانتظار التسجيل', count: pending, selected: statusFilter == 2, onTap: () => setState(() => statusFilter = 2)),
            const SizedBox(width: 6),
            _filterChip(label: 'مسجَّل', count: registered, selected: statusFilter == 1, onTap: () => setState(() => statusFilter = 1)),
            const SizedBox(width: 6),
            _filterChip(label: 'الكل', count: scoped.length, selected: statusFilter == 0, onTap: () => setState(() => statusFilter = 0)),
          ])),
        ]),
      ),
      Expanded(child: matches.isEmpty
        ? Center(child: EmptyState(
            icon: Icons.search_off_rounded,
            title: statusFilter == 2 && query.isEmpty ? 'لا يوجد تلاميذ بانتظار التسجيل' : 'لم يتم العثور على تلاميذ',
            message: query.isNotEmpty ? 'لا يوجد تلميذ يطابق بحثك.' : 'جرّب عرض كل التلاميذ أو تغيير الفصل.',
            action: statusFilter != 0 ? OutlinedButton(onPressed: () => setState(() => statusFilter = 0), child: const Text('عرض الكل')) : null,
          ))
        : ListView.builder(
            padding: EdgeInsetsDirectional.fromSTEB(widget.isMobile ? 12 : 20, 4, widget.isMobile ? 12 : 20, 16),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final student = matches[i];
              final cls = student['classes'] as Map<String, dynamic>?;
              final name = student['name'] as String? ?? 'بدون اسم';
              final done = points.containsKey(student['id']);
              final avatar = _avatarColors(context, name);
              final queueIndex = queueIds.indexOf(student['id'] as String);
              return SolidCard(
                margin: const EdgeInsetsDirectional.only(bottom: 6), padding: EdgeInsets.zero, borderRadius: 12,
                child: InkWell(
                  onTap: () => widget.onOpen(student, queueIds, queueIndex < 0 ? 0 : queueIndex),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(minHeight: 64, child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6),
                    child: Row(children: [
                      CircleAvatar(radius: 19, backgroundColor: avatar.bg, foregroundColor: avatar.fg, child: Text(name.trim().isEmpty ? 'ت' : name.trim().characters.first, style: const TextStyle(fontWeight: FontWeight.w700))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, maxLines: 2, softWrap: true, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text(cls?['name'] as String? ?? 'بدون فصل', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ])),
                      if (done) ...[
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: AppColors.of(context).present.background, borderRadius: BorderRadius.circular(99)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_rounded, size: 15, color: AppColors.of(context).present.foreground), const SizedBox(width: 3), Text('+${points[student['id']]} ن', style: TextStyle(color: AppColors.of(context).present.foreground, fontSize: 13, fontWeight: FontWeight.w700))]),
                        ),
                      ],
                    ]),
                  )),
                ),
              );
            },
          )),
    ]);
  }
}
