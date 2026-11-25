import 'package:flutter/material.dart';
import '../../../../app/design/app_colors.dart';
import '../../domain/entities/case_status.dart';

class CaseStatusBadge extends StatelessWidget {
  const CaseStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.dense = false,
  });

  final CaseStatus status;
  final bool showIcon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final semantic = switch (status) {
      CaseStatus.open || CaseStatus.assigned => palette.excused,
      CaseStatus.inProgress => palette.warning,
      CaseStatus.waiting => palette.pending,
      CaseStatus.resolved => palette.present,
      CaseStatus.closed => palette.notMarked,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: semantic.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: semantic.foreground.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              status.icon,
              size: dense ? 13 : 15,
              color: semantic.foreground,
            ),
            SizedBox(width: dense ? 4 : 6),
          ],
          Text(
            status.arabicLabel,
            style: TextStyle(
              color: semantic.foreground,
              fontSize: dense ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

