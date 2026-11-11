import 'preparation_status.dart';

class PreparationReview {
  const PreparationReview({
    required this.id,
    required this.weeklyLessonId,
    required this.servantProfileId,
    required this.reviewerId,
    this.reviewerName,
    required this.action,
    this.note,
    required this.reviewedAt,
  });

  final String id;
  final String weeklyLessonId;
  final String servantProfileId;
  final String reviewerId;
  final String? reviewerName;
  final PreparationStatus action;
  final String? note;
  final DateTime reviewedAt;

  factory PreparationReview.fromJson(Map<String, dynamic> json) =>
      PreparationReview(
        id: json['id'] as String,
        weeklyLessonId: json['weekly_lesson_id'] as String,
        servantProfileId: json['servant_profile_id'] as String,
        reviewerId: json['reviewer_id'] as String,
        reviewerName: json['reviewer_name'] as String?,
        action: PreparationStatus.fromString(json['action'] as String?),
        note: json['note'] as String?,
        reviewedAt: DateTime.parse(json['reviewed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekly_lesson_id': weeklyLessonId,
    'servant_profile_id': servantProfileId,
    'reviewer_id': reviewerId,
    'reviewer_name': reviewerName,
    'action': action.value,
    'note': note,
    'reviewed_at': reviewedAt.toIso8601String(),
  };
}
