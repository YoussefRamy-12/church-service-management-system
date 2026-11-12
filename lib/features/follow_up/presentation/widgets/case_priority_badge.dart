import 'package:flutter/material.dart';
import '../../domain/entities/case_priority.dart';

class CasePriorityBadge extends StatelessWidget {
  const CasePriorityBadge({
    super.key,
    required this.priority,
    this.showIcon = true,
    this.dense = false,
  });

  final CasePriority priority;
  final bool showIcon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: priority.color.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(priority.icon, size: dense ? 12 : 14, color: priority.color),
            SizedBox(width: dense ? 3 : 5),
          ],
          Text(
            priority.arabicLabel,
            style: TextStyle(
              color: priority.color,
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

