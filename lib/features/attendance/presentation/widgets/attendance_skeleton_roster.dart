import 'package:flutter/material.dart';
import '../../../../app/design/app_colors.dart';
import '../../../../app/design/app_radii.dart';
import '../../../../app/design/app_spacing.dart';

class AttendanceSkeletonRoster extends StatelessWidget {
  const AttendanceSkeletonRoster({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final placeholderColor = isDark
        ? AppDesignColors.darkSurfaceSubtle
        : AppDesignColors.lightSurfaceSubtle;
    final borderColor = isDark
        ? AppDesignColors.darkBorderSubtle
        : AppDesignColors.lightBorderSubtle;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, _) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Avatar placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: placeholderColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Name & subtitle placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: placeholderColor,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 70,
                    height: 10,
                    decoration: BoxDecoration(
                      color: placeholderColor,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Chip placeholder
            Container(
              width: 74,
              height: 28,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
