import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isPendingSync ? const Color(0xFFF1F5F9) : status.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPendingSync
              ? const Color(0xFF94A3B8)
              : status.color.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPendingSync ? Icons.sync_rounded : status.icon,
            size: 15,
            color: isPendingSync ? const Color(0xFF64748B) : status.color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              isPendingSync
                  ? '${status.labelArabic} (بانتظار المزامنة)'
                  : status.labelArabic,
              style: TextStyle(
                color: isPendingSync ? const Color(0xFF475569) : status.color,
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
