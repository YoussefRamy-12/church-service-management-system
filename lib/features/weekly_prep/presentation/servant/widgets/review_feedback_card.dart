import 'package:flutter/material.dart';

import '../../../domain/prep_date_formatter.dart';
import '../../../domain/preparation_status.dart';
import '../../../domain/weekly_preparation.dart';

class ReviewFeedbackCard extends StatelessWidget {
  const ReviewFeedbackCard({super.key, required this.preparation});

  final WeeklyPreparation preparation;

  @override
  Widget build(BuildContext context) {
    if (preparation.status == PreparationStatus.notSubmitted ||
        preparation.status == PreparationStatus.submitted) {
      return const SizedBox.shrink();
    }

    final isRevision = preparation.status == PreparationStatus.needsRevision;
    final dateStr = preparation.reviewedAt != null
        ? PrepDateFormatter.formatDateTime(preparation.reviewedAt)
        : null;

    final primaryColor = isRevision
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final bgColor = isRevision
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);
    final borderColor = isRevision
        ? const Color(0xFFFECACA)
        : const Color(0xFFA7F3D0);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRevision ? Icons.feedback_outlined : Icons.verified_rounded,
                color: primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRevision
                      ? 'ملاحظات القائد المراجع — مطلوب تعديل'
                      : 'تم اعتماد التحضير بنجاح',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (preparation.reviewNote != null &&
              preparation.reviewNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                preparation.reviewNote!,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (preparation.reviewerName != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'المراجع: ${preparation.reviewerName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              if (dateStr != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
