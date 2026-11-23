import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';

/// Compact semantic status: icon, Arabic label and AA foreground/background.
enum AppStatus { present, absent, lateArrival, excused, pending, synced, conflict }

extension AppStatusPresentation on AppStatus {
  String get arabicLabel => switch (this) {
        AppStatus.present => 'حاضر',
        AppStatus.absent => 'غائب',
        AppStatus.lateArrival => 'متأخر',
        AppStatus.excused => 'معتذر',
        AppStatus.pending => 'قيد الانتظار',
        AppStatus.synced => 'تمت المزامنة',
        AppStatus.conflict => 'تعارض يحتاج مراجعة',
      };

  IconData get icon => switch (this) {
        AppStatus.present => Icons.check_circle,
        AppStatus.absent => Icons.cancel,
        AppStatus.lateArrival => Icons.schedule,
        AppStatus.excused => Icons.info,
        AppStatus.pending => Icons.hourglass_top,
        AppStatus.synced => Icons.cloud_done,
        AppStatus.conflict => Icons.warning,
      };

  AppSemanticColors colors(AppColors palette) => switch (this) {
        AppStatus.present => palette.present,
        AppStatus.absent => palette.absent,
        AppStatus.lateArrival => palette.late,
        AppStatus.excused => palette.excused,
        AppStatus.pending => palette.pending,
        AppStatus.synced => palette.synced,
        AppStatus.conflict => palette.conflict,
      };
}

/// Displays a status without relying on color alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.label});

  final AppStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final semantic = status.colors(AppColors.of(context));
    final visibleLabel = label ?? status.arabicLabel;
    return Semantics(
      label: visibleLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: semantic.background,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: semantic.foreground.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 16, color: semantic.foreground),
            const SizedBox(width: 4),
            Text(
              visibleLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: semantic.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
