part of '../spiritual_notebook_page.dart';

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

class _StudentList extends StatefulWidget {
  const _StudentList({
    required this.students,
    required this.submissions,
    required this.period,
    required this.isMobile,
    required this.onOpen,
  });

  final List<Map<String, dynamic>> students, submissions;
  final WeeklyPeriod period;
  final bool isMobile;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  State<_StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<_StudentList> {
  String query = '';
  int statusFilter = 0; // 0 = all, 1 = registered, 2 = pending
  String? selectedClassId; // null = all classes
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekStartStr = _date(widget.period.start);

    final currentSubs = widget.submissions.where(
      (r) => r['period_start'] == weekStartStr,
    );
    final thisWeekPoints = {
      for (final r in currentSubs) r['student_id']: r['total_points'] as int,
    };

    final totalPointsMap = <String, int>{};
    for (final r in widget.submissions) {
      totalPointsMap.update(
        r['student_id'] as String,
        (v) => v + (r['total_points'] as int),
        ifAbsent: () => r['total_points'] as int,
      );
    }

    // Extract all unique classes and counts
    final classMap = <String, String>{};
    final classCounts = <String, int>{};
    for (final s in widget.students) {
      final cls = s['classes'] as Map<String, dynamic>?;
      final classId =
          s['current_class_id'] as String? ??
          cls?['id'] as String? ??
          'unassigned';
      final className = cls?['name'] as String? ?? 'بدون فصل';
      classMap[classId] = className;
      classCounts[classId] = (classCounts[classId] ?? 0) + 1;
    }
    final sortedClasses = classMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Students filtered by class
    final classScopedStudents = selectedClassId == null
        ? widget.students
        : widget.students.where((s) {
            final cls = s['classes'] as Map<String, dynamic>?;
            final classId =
                s['current_class_id'] as String? ??
                cls?['id'] as String? ??
                'unassigned';
            return classId == selectedClassId;
          }).toList();

    final registeredCount = classScopedStudents
        .where((s) => thisWeekPoints.containsKey(s['id']))
        .length;
    final pendingCount = classScopedStudents.length - registeredCount;

    final filteredStudents = classScopedStudents.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final cls = s['classes'] as Map<String, dynamic>?;
      final className = (cls?['name'] as String? ?? '').toLowerCase();

      final matchesQuery =
          name.contains(query.toLowerCase()) ||
          className.contains(query.toLowerCase());
      if (!matchesQuery) return false;

      final isDone = thisWeekPoints.containsKey(s['id']);
      if (statusFilter == 1 && !isDone) return false;
      if (statusFilter == 2 && isDone) return false;

      return true;
    }).toList();

    return Column(
      children: [
        // Controls Row (Search + Status Chips + Class Filter Buttons)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? 12 : 20,
            vertical: 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: AppSearchField(
                  controller: searchController,
                  hintText: 'ابحث باسم التلميذ أو الفصل...',
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              const SizedBox(height: 6),

              // Filter Row 1: Status Chips (الكل، المسجلون، بانتظار التسجيل)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      label: 'الكل',
                      count: classScopedStudents.length,
                      selected: statusFilter == 0,
                      onTap: () => setState(() => statusFilter = 0),
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      label: 'المسجلون',
                      count: registeredCount,
                      color: appSuccess,
                      selected: statusFilter == 1,
                      onTap: () => setState(() => statusFilter = 1),
                    ),
                    const SizedBox(width: 6),
                    _filterChip(
                      label: 'بانتظار التسجيل',
                      count: pendingCount,
                      color: appWarning,
                      selected: statusFilter == 2,
                      onTap: () => setState(() => statusFilter = 2),
                    ),
                  ],
                ),
              ),

              // Filter Row 2: Ready Class Filter Buttons (فصول الخدمة)
              if (sortedClasses.isNotEmpty) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 13,
                              color: isDark
                                  ? AppDesignColors.darkMutedInk
                                  : appMutedInk,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'الفصل:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppDesignColors.darkMutedInk
                                    : appMutedInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      _classFilterChip(
                        label: 'جميع الفصول',
                        count: widget.students.length,
                        selected: selectedClassId == null,
                        onTap: () => setState(() => selectedClassId = null),
                        isDark: isDark,
                      ),
                      for (final entry in sortedClasses) ...[
                        const SizedBox(width: 6),
                        _classFilterChip(
                          label: entry.value,
                          count: classCounts[entry.key] ?? 0,
                          selected: selectedClassId == entry.key,
                          onTap: () =>
                              setState(() => selectedClassId = entry.key),
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Active Class Filter Notification Banner
              if (selectedClassId != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appPrimary.withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: appPrimary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_rounded,
                        size: 14,
                        color: appPrimary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تصفية حسب: ${classMap[selectedClassId] ?? ''} (${filteredStudents.length} تلميذ)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: appPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => selectedClassId = null),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: appPrimary,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: appPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Students Roster
        Expanded(
          child: filteredStudents.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'لم يتم العثور على تلاميذ',
                            message: query.isNotEmpty
                                ? 'لا يوجد تلميذ يطابق بحثك "$query"'
                                : 'لا توجد سجلات تلاميذ تحت هذا التصنيف في هذا الأسبوع.',
                            action: query.isNotEmpty
                                ? OutlinedButton(
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() => query = '');
                                    },
                                    child: const Text('إعادة ضبط البحث'),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    widget.isMobile ? 12 : 20,
                    6,
                    widget.isMobile ? 12 : 20,
                    24,
                  ),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, i) {
                    final s = filteredStudents[i];
                    final cls = s['classes'] as Map<String, dynamic>?;
                    final stage = cls?['stages'] as Map<String, dynamic>?;
                    final done = thisWeekPoints.containsKey(s['id']);
                    final studentName = s['name'] as String? ?? 'بدون اسم';
                    final weekPts = thisWeekPoints[s['id']] ?? 0;
                    final totalPts = totalPointsMap[s['id']] ?? 0;
                    final avatarBg = _avatarColor(studentName);

                    return SolidCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.zero,
                      borderRadius: 12,
                      child: InkWell(
                        onTap: () => widget.onOpen(s),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isMobile ? 12 : 16,
                            vertical: widget.isMobile ? 10 : 12,
                          ),
                          child: Row(
                            children: [
                              // Avatar with Initial
                              CircleAvatar(
                                radius: widget.isMobile ? 18 : 22,
                                backgroundColor: avatarBg.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                ),
                                foregroundColor: avatarBg,
                                child: Text(
                                  studentName.trim().isNotEmpty
                                      ? studentName.trim().characters.first
                                      : 'ت',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: widget.isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: widget.isMobile ? 10 : 14),

                              // Name & Class
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            studentName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: widget.isMobile
                                                  ? 14
                                                  : 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (done)
                                          GlassBadge(
                                            label: widget.isMobile
                                                ? 'مسجل'
                                                : 'تم التسجيل',
                                            color: appSuccess,
                                            icon: Icons.check_circle_rounded,
                                          )
                                        else
                                          GlassBadge(
                                            label: widget.isMobile
                                                ? 'بانتظار'
                                                : 'بانتظار التسجيل',
                                            color: appWarning,
                                            icon: Icons.access_time_rounded,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${cls?['name'] ?? 'بدون فصل'} • ${stage?['name'] ?? 'بدون مرحلة'}',
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: widget.isMobile ? 11 : 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Weekly & Total Points
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: done
                                          ? appSuccess.withValues(alpha: 0.12)
                                          : (isDark
                                                ? AppDesignColors.darkSurfaceSubtle
                                                : AppDesignColors.lightSurfaceSubtle),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      done ? '+$weekPts ن' : '—',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: done
                                            ? appSuccess
                                            : (isDark
                                                  ? AppDesignColors.darkMutedInk
                                                  : appMutedInk),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'إجمالي: $totalPts',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      color: isDark
                                          ? AppDesignColors.darkMutedInk
                                          : appMutedInk,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_left_rounded,
                                color: AppDesignColors.darkMutedInk,
                                size: widget.isMobile ? 18 : 20,
                              ),
                            ],
                          ),
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
