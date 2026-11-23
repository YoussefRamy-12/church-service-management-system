import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';

/// Sync status with a visible Arabic label; pending items can show their count.
enum SyncState { synced, pending, conflict }

class SyncBadge extends StatelessWidget {
  const SyncBadge({
    super.key,
    required this.state,
    this.count = 0,
    this.onTap,
  });

  final SyncState state;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final semantic = switch (state) {
      SyncState.synced => palette.synced,
      SyncState.pending => palette.pending,
      SyncState.conflict => palette.conflict,
    };
    final icon = switch (state) {
      SyncState.synced => Icons.cloud_done,
      SyncState.pending => Icons.hourglass_top,
      SyncState.conflict => Icons.warning,
    };
    final label = switch (state) {
      SyncState.synced => 'تمت المزامنة',
      SyncState.pending => count > 0
          ? 'في انتظار المزامنة ($count)'
          : 'في انتظار المزامنة',
      SyncState.conflict => 'تعارض يحتاج مراجعة',
    };
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: semantic.background,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: semantic.foreground.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: semantic.foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: semantic.foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
    if (onTap == null) return Semantics(label: label, child: badge);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(child: badge),
        ),
      ),
    );
  }
}
