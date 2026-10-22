import '../../auth/domain/entities/servant_profile.dart';
import '../../service/domain/repositories/service_repository.dart';

/// Returns the class IDs a servant may follow up, or null for service-wide
/// roles and system admins. An empty set means the assignment is incomplete.
class FollowUpScope {
  const FollowUpScope({required this.classIds, required this.stageIds});
  final Set<String>? classIds;
  final Set<String>? stageIds;
}

Future<FollowUpScope> resolveFollowUpClassScope({
  required ServiceRepository services,
  required String serviceId,
  required ServantProfile? profile,
}) async {
  if (profile == null) {
    return const FollowUpScope(classIds: null, stageIds: null);
  }
  if (!profile.isActive || profile.serviceId != serviceId) {
    return const FollowUpScope(classIds: {}, stageIds: {});
  }
  if (profile.role == 'overall_leader' || profile.role == 'overall_helper') {
    return const FollowUpScope(classIds: null, stageIds: null);
  }

  try {
    await services.refreshStages(serviceId);
  } catch (_) {}
  final stages = await services.getStages(serviceId);

  if (profile.role == 'stage_leader') {
    final stageId = profile.stageId;
    if (stageId == null) {
      return const FollowUpScope(classIds: {}, stageIds: {});
    }
    try {
      await services.refreshClasses(stageId);
    } catch (_) {}
    final classes = await services.getClasses(stageId);
    return FollowUpScope(
      classIds: classes.map((item) => item.id).toSet(),
      stageIds: {stageId},
    );
  }

  if (profile.role == 'class_servant' || profile.role == 'class_leader') {
    final classId = profile.classId;
    if (classId == null) {
      return const FollowUpScope(classIds: {}, stageIds: {});
    }
    for (final stage in stages) {
      try {
        await services.refreshClasses(stage.id);
      } catch (_) {}
      final classes = await services.getClasses(stage.id);
      if (classes.any((item) => item.id == classId)) {
        return FollowUpScope(classIds: {classId}, stageIds: {stage.id});
      }
    }
    return const FollowUpScope(classIds: {}, stageIds: {});
  }

  return const FollowUpScope(classIds: {}, stageIds: {});
}
