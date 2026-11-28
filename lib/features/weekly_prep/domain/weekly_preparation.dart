import 'preparation_status.dart';

class WeeklyPreparation {
  const WeeklyPreparation({
    required this.weeklyLessonId,
    required this.servantProfileId,
    this.servantName,
    this.stageName,
    this.className,
    this.status = PreparationStatus.notSubmitted,
    this.prepared = false,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewerName,
    this.reviewNote,
    required this.updatedAt,
    this.syncState = 'synced',
  });

  final String weeklyLessonId;
  final String servantProfileId;
  final String? servantName;
  final String? stageName;
  final String? className;
  final PreparationStatus status;
  final bool prepared;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewerName;
  final String? reviewNote;
  final DateTime updatedAt;
  final String syncState; // 'synced', 'pending', 'conflict'

  bool get isPendingSync => syncState == 'pending';
  bool get isAwaitingReview => status == PreparationStatus.submitted;
  bool get isApproved => status == PreparationStatus.approved;
  bool get needsRevision => status == PreparationStatus.needsRevision;
  bool get isNotSubmitted => status == PreparationStatus.notSubmitted;

  WeeklyPreparation copyWith({
    String? weeklyLessonId,
    String? servantProfileId,
    String? servantName,
    String? stageName,
    String? className,
    PreparationStatus? status,
    bool? prepared,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewerName,
    String? reviewNote,
    DateTime? updatedAt,
    String? syncState,
  }) {
    return WeeklyPreparation(
      weeklyLessonId: weeklyLessonId ?? this.weeklyLessonId,
      servantProfileId: servantProfileId ?? this.servantProfileId,
      servantName: servantName ?? this.servantName,
      stageName: stageName ?? this.stageName,
      className: className ?? this.className,
      status: status ?? this.status,
      prepared: prepared ?? this.prepared,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewNote: reviewNote ?? this.reviewNote,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
    );
  }

  factory WeeklyPreparation.fromJson(Map<String, dynamic> json) {
    return WeeklyPreparation(
      weeklyLessonId: json['weekly_lesson_id'] as String,
      servantProfileId: json['servant_profile_id'] as String,
      servantName: json['servant_name'] as String?,
      stageName: json['stage_name'] as String?,
      className: json['class_name'] as String?,
      status: PreparationStatus.fromString(json['status'] as String?),
      prepared: json['prepared'] as bool? ?? false,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewerName: json['reviewer_name'] as String?,
      reviewNote: json['review_note'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncState: json['sync_state'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() => {
    'weekly_lesson_id': weeklyLessonId,
    'servant_profile_id': servantProfileId,
    'servant_name': servantName,
    'stage_name': stageName,
    'class_name': className,
    'status': status.value,
    'prepared': prepared,
    'submitted_at': submittedAt?.toIso8601String(),
    'reviewed_at': reviewedAt?.toIso8601String(),
    'reviewed_by': reviewedBy,
    'reviewer_name': reviewerName,
    'review_note': reviewNote,
    'updated_at': updatedAt.toIso8601String(),
    'sync_state': syncState,
  };
}
