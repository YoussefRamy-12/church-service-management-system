// ignore_for_file: invalid_use_of_protected_member

part of '../spiritual_notebook_page.dart';

extension _LeaderboardSections on _LeaderboardState {



  Widget _buildLeaderboardView(
      BuildContext context, {
      required bool weekly,
      required Map<String, String> classMap,
    }) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final scores = <String, int>{};
      for (final r in widget.submissions) {
        if (!weekly || r['period_start'] == widget.weekStart) {
          scores.update(
            r['student_id'] as String,
            (v) => v + (r['total_points'] as int),
            ifAbsent: () => r['total_points'] as int,
          );
        }
      }

      // Filter students by selected class if set
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

      final scoredStudents =
          classScopedStudents
              .where(
                (s) => scores.containsKey(s['id']) && (scores[s['id']] ?? 0) > 0,
              )
              .toList()
            ..sort(
              (a, b) => (scores[b['id']] ?? 0).compareTo(scores[a['id']] ?? 0),
            );

      if (scoredStudents.isEmpty) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: EmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: weekly
                        ? (selectedClassId != null
                              ? 'لا توجد درجات لهذا الفصل هذا الأسبوع'
                              : 'لا توجد درجات مسجلة لهذا الأسبوع')
                        : (selectedClassId != null
                              ? 'لا توجد بيانات شرف لهذا الفصل بعد'
                              : 'لا توجد بيانات شرف بعد'),
                    message: weekly
                        ? 'قم برصد دفاتر التلاميذ لتظهر أسماء المتفوقين في لوحة الشرف.'
                        : 'ابدأ برصد درجات النوتة الروحية للتلاميذ ليتم حساب الترتيب.',
                  ),
                ),
              ),
            );
          },
        );
      }

      return ListView(
        padding: EdgeInsets.fromLTRB(
          widget.isMobile ? 12 : 20,
          10,
          widget.isMobile ? 12 : 20,
          24,
        ),
        children: [
          // Active class indicator
          if (selectedClassId != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'لوحة شرف فصل: ${classMap[selectedClassId] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => selectedClassId = null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'عرض الكل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Podium for Top 3
          _buildPodium(context, scoredStudents, scores, isDark),
          const SizedBox(height: 14),

          ModernSectionHeader(
            title: selectedClassId != null
                ? 'متفوقو ${classMap[selectedClassId] ?? 'الفصل'}'
                : 'قائمة المتفوقين',
            subtitle: 'ترتيب التلاميذ بحسب مجموع النقاط',
            badge: GlassBadge(
              label: '${scoredStudents.length} تلميذ',
              color: Theme.of(context).colorScheme.primary,
              showDot: false,
            ),
          ),
          const SizedBox(height: 6),

          for (int i = 0; i < scoredStudents.length; i++) ...[
            _buildRankItem(
              context,
              student: scoredStudents[i],
              rank: i + 1,
              score: scores[scoredStudents[i]['id']] ?? 0,
              isDark: isDark,
            ),
          ],
        ],
      );
    }

  Widget _buildPodium(
      BuildContext context,
      List<Map<String, dynamic>> sorted,
      Map<String, int> scores,
      bool isDark,
    ) {
      if (sorted.isEmpty) return const SizedBox.shrink();

      final first = sorted.isNotEmpty ? sorted[0] : null;
      final second = sorted.length > 1 ? sorted[1] : null;
      final third = sorted.length > 2 ? sorted[2] : null;

      final h1 = isMobile ? 85.0 : 130.0;
      final h2 = isMobile ? 68.0 : 105.0;
      final h3 = isMobile ? 55.0 : 90.0;

      return SolidCard(
        borderRadius: 14,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 16,
          vertical: isMobile ? 12 : 16,
        ),
        color: isDark ? AppDesignColors.darkSurface : Colors.white,
        border: Border.all(
          color: isDark ? AppDesignColors.darkSurfaceSubtle : AppDesignColors.lightBorderSubtle,
          width: 1.2,
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: AppDesignColors.lightGold,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'منصة التكريم والتميز',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Rank 2: Silver
                if (second != null)
                  Expanded(
                    child: _podiumColumn(
                      name: second['name'] as String? ?? '',
                      score: scores[second['id']] ?? 0,
                      rank: 2,
                      rankLabel: 'المركز الثاني',
                      accentColor: AppDesignColors.lightMutedInk,
                      icon: Icons.military_tech_rounded,
                      height: h2,
                      isDark: isDark,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),

                // Rank 1: Gold (Center & Taller)
                if (first != null)
                  Expanded(
                    child: _podiumColumn(
                      name: first['name'] as String? ?? '',
                      score: scores[first['id']] ?? 0,
                      rank: 1,
                      rankLabel: 'المركز الأول',
                      accentColor: AppDesignColors.lightGold,
                      icon: Icons.workspace_premium_rounded,
                      height: h1,
                      isDark: isDark,
                      isWinner: true,
                    ),
                  ),

                // Rank 3: Bronze
                if (third != null)
                  Expanded(
                    child: _podiumColumn(
                      name: third['name'] as String? ?? '',
                      score: scores[third['id']] ?? 0,
                      rank: 3,
                      rankLabel: 'المركز الثالث',
                      accentColor: AppColors.light.warning.foreground,
                      icon: Icons.military_tech_rounded,
                      height: h3,
                      isDark: isDark,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        ),
      );
    }

  Widget _podiumColumn({
      required String name,
      required int score,
      required int rank,
      required String rankLabel,
      required Color accentColor,
      required IconData icon,
      required double height,
      required bool isDark,
      bool isWinner = false,
    }) {
      final badgeSize = isMobile
          ? (isWinner ? 38.0 : 32.0)
          : (isWinner ? 48.0 : 40.0);
      final iconSize = isMobile
          ? (isWinner ? 20.0 : 17.0)
          : (isWinner ? 26.0 : 22.0);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: accentColor, size: iconSize),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w700,
              fontSize: isMobile ? 11 : (isWinner ? 14 : 13),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$score ن',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontSize: isMobile ? 12 : (isWinner ? 15 : 13),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.20 : 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile
                        ? (isWinner ? 18 : 14)
                        : (isWinner ? 24 : 18),
                    color: accentColor,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 2),
                  Text(
                    rankLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppDesignColors.darkMutedInk : appMutedInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }


  }
