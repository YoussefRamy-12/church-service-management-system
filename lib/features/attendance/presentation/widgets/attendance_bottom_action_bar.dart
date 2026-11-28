import 'package:flutter/material.dart';
import '../../../../app/design/app_radii.dart';
import '../../../../app/design/app_spacing.dart';

class AttendanceBottomActionBar extends StatelessWidget {
  const AttendanceBottomActionBar({
    super.key,
    required this.readOnly,
    required this.openingQrScanner,
    required this.onOpenQrScanner,
    required this.onReview,
  });

  final bool readOnly;
  final bool openingQrScanner;
  final VoidCallback onOpenQrScanner;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Review button
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('attendance_review_bottom'),
                onPressed: onReview,
                icon: const Icon(Icons.fact_check_outlined, size: 20),
                label: const Text('مراجعة الحضور'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Scan QR button
            Expanded(
              child: FilledButton.icon(
                key: const Key('attendance_scan_qr_bottom'),
                onPressed: readOnly || openingQrScanner ? null : onOpenQrScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: const Text('مسح QR'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
