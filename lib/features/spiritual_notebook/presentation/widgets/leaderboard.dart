part of '../spiritual_notebook_page.dart';

class _Leaderboard extends StatefulWidget {
  const _Leaderboard({
    required this.students,
    required this.submissions,
    required this.weekStart,
    required this.isMobile,
  });

  final List<Map<String, dynamic>> students, submissions;
  final String weekStart;
  final bool isMobile;

  @override
  State<_Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<_Leaderboard> {
  String? selectedClassId; // null = all classes
  bool get isMobile => widget.isMobile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract all unique classes and counts for Leaderboard
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

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub Tabs (Weekly vs All-Time)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 12 : 24,
              vertical: 4,
            ),
            child: const TabBar(
              indicatorColor: appPrimary,
              labelColor: appPrimary,
              unselectedLabelColor: appMutedInk,
              tabs: [
                Tab(
                  icon: Icon(Icons.calendar_today_rounded, size: 16),
                  text: 'شرف الأسبوع',
                ),
                Tab(
                  icon: Icon(Icons.emoji_events_rounded, size: 16),
                  text: 'الترتيب العام',
                ),
              ],
            ),
          ),

          // Ready Class Filter Buttons for Leaderboard
          if (sortedClasses.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 12 : 24,
                vertical: 4,
              ),
              child: SingleChildScrollView(
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
                    _classFilterPill(
                      label: 'جميع الفصول',
                      count: widget.students.length,
                      selected: selectedClassId == null,
                      onTap: () => setState(() => selectedClassId = null),
                      isDark: isDark,
                    ),
                    for (final entry in sortedClasses) ...[
                      const SizedBox(width: 6),
                      _classFilterPill(
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
            ),

          Expanded(
            child: TabBarView(
              children: [
                _buildLeaderboardView(
                  context,
                  weekly: true,
                  classMap: classMap,
                ),
                _buildLeaderboardView(
                  context,
                  weekly: false,
                  classMap: classMap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget 

  

  

  

  
}
