part of '../spiritual_notebook_page.dart';

extension _StudentListFilterBuilders on _StudentListState {

  Widget _filterChip({
      required String label,
      required int count,
      required bool selected,
      required VoidCallback onTap,
      Color? color,
    }) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final activeColor = color ?? appPrimary;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? AppDesignColors.darkSurfaceSubtle : AppDesignColors.lightSurfaceSubtle),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? activeColor
                    : (isDark
                          ? AppDesignColors.darkBorder
                          : AppDesignColors.lightBorder),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? (isDark ? Colors.white : activeColor)
                        : (isDark ? AppDesignColors.darkMutedInk : appMutedInk),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _classFilterChip({
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
  }
