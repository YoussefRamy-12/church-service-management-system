part of '../spiritual_notebook_page.dart';

extension _LeaderboardControls on _LeaderboardState {

  Widget _classFilterPill({
      required String label,
      required int count,
      required bool selected,
      required VoidCallback onTap,
      required bool isDark,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? appPrimary
                  : (isDark ? AppDesignColors.darkSurfaceSubtle : AppDesignColors.lightSurfaceSubtle),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? appPrimary
                    : (isDark
                          ? AppDesignColors.darkBorder
                          : AppDesignColors.lightBorder),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white : appInk),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark
                              ? AppDesignColors.darkBorder
                              : AppDesignColors.lightBorderSubtle),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : (isDark ? AppDesignColors.darkMutedInk : appMutedInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildRankItem(
      BuildContext context, {
      required Map<String, dynamic> student,
      required int rank,
      required int score,
      required bool isDark,
    }) {
      final cls = student['classes'] as Map<String, dynamic>?;
      final stage = cls?['stages'] as Map<String, dynamic>?;
      final studentName = student['name'] as String? ?? 'بدون اسم';

      final (Color badgeColor, IconData rankIcon) = switch (rank) {
        1 => (AppDesignColors.lightGold, Icons.workspace_premium_rounded),
        2 => (AppDesignColors.lightMutedInk, Icons.military_tech_rounded),
        3 => (AppColors.light.warning.foreground, Icons.military_tech_rounded),
        _ => (appPrimary, Icons.numbers_rounded),
      };

      return SolidCard(
        margin: const EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 10,
        ),
        borderRadius: 10,
        child: Row(
          children: [
            Container(
              width: isMobile ? 28 : 32,
              height: isMobile ? 28 : 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: isDark ? 0.20 : 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: rank <= 3
                  ? Icon(rankIcon, size: isMobile ? 16 : 18, color: badgeColor)
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        fontSize: isMobile ? 11 : 13,
                      ),
                    ),
            ),
            SizedBox(width: isMobile ? 10 : 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                  Text(
                    '${cls?['name'] ?? 'بدون فصل'} • ${stage?['name'] ?? 'بدون مرحلة'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: appPrimary.withValues(alpha: isDark ? 0.20 : 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: appPrimary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '$score ن',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: appPrimary,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
