import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('attendance_review_bottom'),
                onPressed: onReview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('مراجعة الحضور'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('attendance_scan_qr_bottom'),
                onPressed: readOnly || openingQrScanner ? null : onOpenQrScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('مسح QR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
