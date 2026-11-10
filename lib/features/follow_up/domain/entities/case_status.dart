import 'package:flutter/material.dart';

/// Status of a follow-up case with Arabic labels and role-based transition rules.
enum CaseStatus {
  open(
    'open',
    'مفتوحة',
    Icons.radio_button_unchecked_rounded,
    Color(0xFF2563EB),
  ),
  assigned(
    'assigned',
    'تم التكليف',
    Icons.assignment_ind_rounded,
    Color(0xFF0284C7),
  ),
  inProgress(
    'in_progress',
    'قيد المتابعة',
    Icons.pending_rounded,
    Color(0xFFD97706),
  ),
  waiting(
    'waiting',
    'في الانتظار',
    Icons.hourglass_top_rounded,
    Color(0xFF7C3AED),
  ),
  resolved(
    'resolved',
    'تم الحل',
    Icons.check_circle_rounded,
    Color(0xFF059669),
  ),
  closed('closed', 'مغلقة', Icons.lock_outline_rounded, Color(0xFF64748B));

  const CaseStatus(this.value, this.arabicLabel, this.icon, this.color);

  final String value;
  final String arabicLabel;
  final IconData icon;
  final Color color;

  static CaseStatus fromString(String? value) {
    return CaseStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CaseStatus.open,
    );
  }

  /// Whether the case is considered active/open in views.
  bool get isActive => this != resolved && this != closed;

  /// Returns valid next statuses a user with [role] can transition this case to.
  List<CaseStatus> allowedTransitions({required String? role}) {
    final isLeader =
        role == 'overall_leader' ||
        role == 'overall_helper' ||
        role == 'stage_leader' ||
        role == 'class_leader' ||
        role == 'system_admin';

    if (isLeader) {
      // Leaders have full authority to reopen, resolve, close, or progress
      return switch (this) {
        CaseStatus.open => [
          CaseStatus.assigned,
          CaseStatus.inProgress,
          CaseStatus.waiting,
          CaseStatus.resolved,
          CaseStatus.closed,
        ],
        CaseStatus.assigned => [
          CaseStatus.inProgress,
          CaseStatus.waiting,
          CaseStatus.resolved,
          CaseStatus.closed,
        ],
        CaseStatus.inProgress => [
          CaseStatus.waiting,
          CaseStatus.resolved,
          CaseStatus.closed,
        ],
        CaseStatus.waiting => [
          CaseStatus.inProgress,
          CaseStatus.resolved,
          CaseStatus.closed,
        ],
        CaseStatus.resolved => [
          CaseStatus.closed,
          CaseStatus.open,
          CaseStatus.inProgress,
        ],
        CaseStatus.closed => [CaseStatus.open],
      };
    } else {
      // Class servants: can record progress or wait, but CANNOT resolve or close or reopen
      return switch (this) {
        CaseStatus.open => [CaseStatus.inProgress, CaseStatus.waiting],
        CaseStatus.assigned => [CaseStatus.inProgress, CaseStatus.waiting],
        CaseStatus.inProgress => [CaseStatus.waiting],
        CaseStatus.waiting => [CaseStatus.inProgress],
        CaseStatus.resolved => const [],
        CaseStatus.closed => const [],
      };
    }
  }
}
