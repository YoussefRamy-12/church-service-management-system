import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:church_service_management_system/app/theme.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import '../../../domain/prep_date_formatter.dart';
import '../../../domain/preparation_status.dart';
import '../../../domain/preparation_review.dart';
import '../../../domain/weekly_preparation.dart';
import '../../servant/widgets/preparation_history_sheet.dart';
import '../../servant/widgets/preparation_status_badge.dart';
import '../../weekly_prep_providers.dart';

class PreparationReviewDialog extends ConsumerStatefulWidget {
  const PreparationReviewDialog({
    super.key,
    required this.preparation,
    required this.currentLeader,
    required this.onReviewed,
  });

  final WeeklyPreparation preparation;
  final ServantProfile currentLeader;
  final VoidCallback onReviewed;

  @override
  ConsumerState<PreparationReviewDialog> createState() =>
      _PreparationReviewDialogState();
}

class _PreparationReviewDialogState
    extends ConsumerState<PreparationReviewDialog> {
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isSelf =>
      widget.preparation.servantProfileId == widget.currentLeader.id;

  bool get _canReview =>
      widget.preparation.status == PreparationStatus.submitted && !_isSelf;

  Future<void> _showReviewHistory() async {
    final prep = widget.preparation;
    final historyFuture = ref.read(
      preparationReviewHistoryProvider((
        lessonId: prep.weeklyLessonId,
        servantProfileId: prep.servantProfileId,
      )).future,
    );

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<List<PreparationReview>>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text('تعذر تحميل سجل المراجعات.'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ),
            );
          }
          return PreparationHistorySheet(
            reviews: snapshot.data ?? const [],
            lessonFileName: 'تحضير ${prep.servantName ?? ''}',
          );
        },
      ),
    );
  }

  Future<void> _handleApprove() async {
    if (_isSelf) {
      setState(() => _errorMessage = 'لا يمكن للخادم اعتماد تحضيره الخاص.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاعتماد'),
        content: Text(
          'هل تريد اعتماد تحضير الخادم "${widget.preparation.servantName ?? 'الخادم'}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، اعتماد'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(weeklyPreparationRepositoryProvider);
      await repo.reviewPreparation(
        lessonId: widget.preparation.weeklyLessonId,
        servantProfileId: widget.preparation.servantProfileId,
        action: PreparationStatus.approved,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('تم اعتماد التحضير بنجاح.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'تعذر اعتماد التحضير: $e';
        });
      }
    }
  }

  Future<void> _handleRequestRevision() async {
    if (_isSelf) {
      setState(() => _errorMessage = 'لا يمكن مراجعة تحضيرك الخاص.');
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(
        () => _errorMessage = 'يجب كتابة ملاحظات التعديل والتوجيهات للخادم.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد طلب التعديل'),
        content: Text(
          'هل تريد إعادة التحضير للخادم "${widget.preparation.servantName ?? 'الخادم'}" لإجراء التعديلات؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إعادة للتعديل'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(weeklyPreparationRepositoryProvider);
      await repo.reviewPreparation(
        lessonId: widget.preparation.weeklyLessonId,
        servantProfileId: widget.preparation.servantProfileId,
        action: PreparationStatus.needsRevision,
        note: note,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFEA580C),
            content: Text('تمت إعادة التحضير للخادم مع الملاحظات.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'تعذر تسجيل المراجعة: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prep = widget.preparation;
    final dateStr = prep.submittedAt != null
        ? PrepDateFormatter.formatDateTime(prep.submittedAt)
        : 'لم يسجل تاريخ';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.rate_review_rounded, color: appPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _canReview
                  ? 'مراجعة تحضير: ${prep.servantName ?? 'الخادم'}'
                  : 'تفاصيل مراجعة التحضير: ${prep.servantName ?? 'الخادم'}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Servant & Submission details box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'الخادم:',
                      value: prep.servantName ?? '—',
                      bold: true,
                    ),
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'المرحلة والفصل:',
                      value:
                          '${prep.stageName ?? '—'} - ${prep.className ?? '—'}',
                    ),
                    const SizedBox(height: 6),
                    _DetailRow(label: 'تاريخ الإرسال:', value: dateStr),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'الحالة الحالية:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PreparationStatusBadge(status: prep.status),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_canReview) ...[
                // Feedback input is available only while a submission awaits review.
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  enabled: !_submitting,
                  decoration: InputDecoration(
                    labelText:
                        'ملاحظات وتوجيهات المراجعة (إلزامية في حالة طلب التعديل)',
                    hintText: 'اكتب ملاحظاتك للخادم هنا...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'هذه مراجعة سابقة للقراءة فقط. يمكنك الاطلاع على سجل المراجعات دون تغيير القرار.',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              if (_isSelf) ...[
                const SizedBox(height: 10),
                const Text(
                  'تنبيه: هذا هو تحضيرك الشخصي. لا يمكنك اعتماد أو مراجعة تحضيرك بنفسك.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Button to view history trail
              OutlinedButton.icon(
                onPressed: _submitting ? null : _showReviewHistory,
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('عرض سجل المراجعات السابقة'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(_canReview ? 'إلغاء' : 'إغلاق'),
        ),
        if (_canReview) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: _submitting ? null : _handleRequestRevision,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('طلب تعديل'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            onPressed: _submitting ? null : _handleApprove,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('اعتماد التحضير'),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
