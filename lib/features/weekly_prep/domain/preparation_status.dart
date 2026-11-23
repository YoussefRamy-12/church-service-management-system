import 'package:flutter/material.dart';

enum PreparationStatus {
  notSubmitted('not_submitted'),
  submitted('submitted'),
  approved('approved'),
  needsRevision('needs_revision');

  const PreparationStatus(this.value);
  final String value;

  static PreparationStatus fromString(String? val) {
    if (val == null) return PreparationStatus.notSubmitted;
    for (final status in PreparationStatus.values) {
      if (status.value == val) return status;
    }
    return PreparationStatus.notSubmitted;
  }

  String get labelArabic => switch (this) {
    PreparationStatus.notSubmitted => 'لم يتم الإرسال',
    PreparationStatus.submitted => 'بانتظار المراجعة',
    PreparationStatus.approved => 'تم الاعتماد',
    PreparationStatus.needsRevision => 'يحتاج إلى تعديل',
  };

  IconData get icon => switch (this) {
    PreparationStatus.notSubmitted => Icons.radio_button_unchecked_rounded,
    PreparationStatus.submitted => Icons.hourglass_top_rounded,
    PreparationStatus.approved => Icons.check_circle_rounded,
    PreparationStatus.needsRevision => Icons.edit_note_rounded,
  };

  Color get color => switch (this) {
    PreparationStatus.notSubmitted => const Color(0xFF94A3B8), // slate
    PreparationStatus.submitted => const Color(0xFFF59E0B), // amber
    PreparationStatus.approved => const Color(0xFF10B981), // emerald
    PreparationStatus.needsRevision => const Color(0xFFEF4444), // red
  };

  Color get backgroundColor => switch (this) {
    PreparationStatus.notSubmitted => const Color(0xFFF1F5F9),
    PreparationStatus.submitted => const Color(0xFFFEF3C7),
    PreparationStatus.approved => const Color(0xFFD1FAE5),
    PreparationStatus.needsRevision => const Color(0xFFFEE2E2),
  };

  /// Allowed transitions state machine
  bool canTransitionTo(PreparationStatus next) => switch (this) {
    PreparationStatus.notSubmitted => next == PreparationStatus.submitted,
    PreparationStatus.submitted =>
      next == PreparationStatus.approved ||
          next == PreparationStatus.needsRevision,
    PreparationStatus.needsRevision => next == PreparationStatus.submitted,
    PreparationStatus.approved => false, // Terminal approved state
  };
}
