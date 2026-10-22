import '../../../auth/domain/entities/servant_profile.dart';

/// Domain contract for servant profile operations.
abstract interface class ServantRepository {
  Stream<List<ServantProfile>> watchForService(String serviceId);
  Future<void> refresh(String serviceId);
  Future<void> createProfile({
    required String id,
    required String serviceId,
    required String authUserId,
    required String name,
    required String phone,
    required String role,
    String? stageId,
    String? classId,
  });
  Future<ServantProfile> updateProfile({
    required String servantId,
    required String name,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String role,
    String? stageId,
    String? classId,
    required String accountStatus,
  });
  Future<void> deleteProfile(String servantId);
}
