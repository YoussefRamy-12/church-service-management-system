import 'package:flutter/material.dart';

import '../../../domain/prep_date_formatter.dart';
import '../../../domain/preparation_review.dart';
import '../../../domain/preparation_status.dart';

class PreparationHistorySheet extends StatelessWidget {
  const PreparationHistorySheet({
    super.key,
    required this.reviews,
    required this.lessonFileName,
  });

  final List<PreparationReview> reviews;
  final String lessonFileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        maxWidth: 580,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سجل مراجعات التحضير',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      lessonFileName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(height: 24),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'لا توجد مراجعات سابقة لهذا الدرس بعد.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  final isApproved =
                      review.action == PreparationStatus.approved;
                  final statusColor = isApproved
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444);
                  final dateFormatted = PrepDateFormatter.formatDateTime(
                    review.reviewedAt,
                  );

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isApproved
                                  ? Icons.check_circle_rounded
                                  : Icons.edit_note_rounded,
                              size: 18,
                              color: statusColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isApproved ? 'تم الاعتماد' : 'طلب تعديل',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: statusColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateFormatted,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        if (review.reviewerName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'المراجع: ${review.reviewerName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        if (review.note != null &&
                            review.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              review.note!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
