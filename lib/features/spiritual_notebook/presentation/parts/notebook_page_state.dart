part of '../spiritual_notebook_page.dart';

class _SpiritualNotebookPageState extends ConsumerState<SpiritualNotebookPage> {
  int tab = 0;
  int _weekOffset = 0;
  bool _showWeeklyPoints = false;
  late Future<_NotebookData> data;

  @override
  void initState() {
    super.initState();
    data = _load();
  }

  WeeklyPeriod get _selectedPeriod {
    final now = DateTime.now();
    return WeeklyPeriod.offset(now, _weekOffset);
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
    setState(() {
      data = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentServantProfileProvider).value;
    final isSuper = ref.watch(isSuperAdminProvider);
    final canConfigure =
        isSuper ||
        profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper';
    final period = _selectedPeriod;
    final isCurrentWeek = _weekOffset == 0;

    return FutureBuilder<_NotebookData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر تحميل بيانات النوتة الروحية',
                message: 'تعذر تحميل بيانات النوتة الروحية. حاول مرة أخرى.',
                action: FilledButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child: LoadingView(message: 'جاري تحميل سجلات النوتة الروحية...'),
            ),
          );
        }

        final d = snap.data!;
        final weekStartStr = _date(period.start);

        // Calculate weekly metrics
        final currentWeekSubs = d.submissions
            .where((r) => r['period_start'] == weekStartStr)
            .toList();
        final registeredCount = currentWeekSubs.length;
        final totalStudents = d.students.length;
        final weekTotalPoints = currentWeekSubs.fold<int>(
          0,
          (sum, r) => sum + (r['total_points'] as int? ?? 0),
        );

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 12 : 20,
                        2,
                        isMobile ? 12 : 20,
                        isMobile ? 6 : 10,
                      ),
                      child: _buildTabBar(
                        isMobile: isMobile,
                        totalStudents: totalStudents,
                        canConfigure: canConfigure,
                      ),
                    ),

                    if (tab == 0)
                      _buildWeekSummary(
                        period: period,
                        isCurrentWeek: isCurrentWeek,
                        registeredCount: registeredCount,
                        totalStudents: totalStudents,
                        weekTotalPoints: weekTotalPoints,
                      ),

                    // Active Tab Content
                    Expanded(
                      child: isMobile
                          ? switch (tab) {
                              0 => _StudentList(
                                students: d.students,
                                submissions: d.submissions,
                                period: period,
                                isMobile: true,
                                onOpen: (s, studentIds, selectedIndex) => context.go(
                                  '/service/${widget.serviceId}/spiritual-notebook/student/${s['id']}',
                                  extra: {
                                    'studentIds': studentIds,
                                    'studentIndex': selectedIndex,
                                    'weekStart': weekStartStr,
                                  },
                                ),
                              ),
                              1 => _Leaderboard(
                                students: d.students,
                                submissions: d.submissions,
                                weekStart: weekStartStr,
                                isMobile: true,
                              ),
                              _ => _NotebookSettings(
                                serviceId: widget.serviceId,
                                activities: d.activities,
                                settings: d.settings,
                                isMobile: true,
                                onSaved: refresh,
                              ),
                            }
                          : tab == 2 && canConfigure
                          ? _NotebookSettings(
                              serviceId: widget.serviceId,
                              activities: d.activities,
                              settings: d.settings,
                              isMobile: false,
                              onSaved: refresh,
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _StudentList(
                                    students: d.students,
                                    submissions: d.submissions,
                                    period: period,
                                    isMobile: false,
                                    onOpen: (s, studentIds, selectedIndex) => context.go(
                                      '/service/${widget.serviceId}/spiritual-notebook/student/${s['id']}',
                                      extra: {
                                        'studentIds': studentIds,
                                        'studentIndex': selectedIndex,
                                        'weekStart': weekStartStr,
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _Leaderboard(
                                    students: d.students,
                                    submissions: d.submissions,
                                    weekStart: weekStartStr,
                                    isMobile: false,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }






}
