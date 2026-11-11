import '../../auth/domain/entities/servant_profile.dart';

class WeeklyPrepPermissions {
  const WeeklyPrepPermissions._();

  /// Whether a user can upload, edit, or delete lesson PDFs.
  /// Allowed for: SuperAdmin, overall_leader, overall_helper,
  /// or stage_leader for their assigned stage.
  static bool canManageLessons({
    required ServantProfile? profile,
    required bool isSuperAdmin,
    String? stageId,
  }) {
    if (isSuperAdmin) return true;
    if (profile == null) return false;
    final role = profile.role;
    if (role == 'overall_leader' || role == 'overall_helper') return true;
    if (role == 'stage_leader') {
      if (stageId == null) return true; // Has management rights in general
      return profile.stageId == stageId;
    }
    return false;
  }

  /// Whether a user can view the leadership dashboard for preparations.
  static bool canViewLeadershipDashboard({
    required ServantProfile? profile,
    required bool isSuperAdmin,
  }) {
    if (isSuperAdmin) return true;
    if (profile == null) return false;
    final role = profile.role;
    return role == 'overall_leader' ||
        role == 'overall_helper' ||
        role == 'stage_leader';
  }

  /// Whether a leader can review (approve / return for revision) a specific preparation.
  /// Rules:
  /// 1. Must be overall_leader, overall_helper, or stage_leader for that stage.
  /// 2. Must NEVER approve/review their own preparation.
  /// 3. class_servant and class_leader cannot review.
  static bool canReviewPreparation({
    required ServantProfile? profile,
    required bool isSuperAdmin,
    required String targetServantProfileId,
    required String stageId,
  }) {
    if (isSuperAdmin) {
      // Super admin can review if not self
      return profile?.id != targetServantProfileId;
    }
    if (profile == null) return false;

    // Servant cannot review themselves under any circumstances
    if (profile.id == targetServantProfileId) return false;

    final role = profile.role;
    if (role == 'overall_leader' || role == 'overall_helper') return true;
    if (role == 'stage_leader') {
      return profile.stageId == stageId;
    }
    return false;
  }

  /// Servants can submit/resubmit only their own preparation
  static bool canSubmitPreparation({
    required ServantProfile? profile,
    required String targetServantProfileId,
    required bool isCurrentWeek,
  }) {
    if (profile == null) return false;
    if (!isCurrentWeek) return false; // Past weeks are read-only
    return profile.id == targetServantProfileId;
  }
}
