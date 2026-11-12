import 'package:flutter/material.dart';
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(status.icon, size: dense ? 13 : 15, color: status.color),
            SizedBox(width: dense ? 4 : 6),
          ],
          Text(
            status.arabicLabel,
            style: TextStyle(
              color: status.color,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

