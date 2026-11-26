import 'package:flutter/material.dart';

import '../../../../../app/design/app_colors.dart';
import '../../../domain/preparation_status.dart';

class PreparationStatusBadge extends StatelessWidget {
  const PreparationStatusBadge({
    super.key,
    required this.status,
    this.isPendingSync = false,
  });

  final PreparationStatus status;
  final bool isPendingSync;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pair = switch (status) {
      PreparationStatus.notSubmitted => colors.notMarked,
      PreparationStatus.submitted => colors.warning,
      PreparationStatus.approved => colors.present,
      // Needs-revision is a correction/error state, distinct from all others.
      PreparationStatus.needsRevision => colors.absent,
    };
    final foreground = isPendingSync ? colors.synced.foreground : pair.foreground;
    final background = isPendingSync ? colors.synced.background : pair.background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: foreground.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPendingSync ? Icons.sync_rounded : status.icon,
            size: 15,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              isPendingSync
                  ? '${status.labelArabic} (بانتظار المزامنة)'
                  : status.labelArabic,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
