import '../../auth/domain/entities/servant_profile.dart';
import '../domain/repositories/servant_repository.dart';
import 'supabase_servant_repository.dart';

/// Online-only implementation of [ServantRepository].
///
/// Communicates directly with Supabase via [SupabaseServantRepository],
/// bypassing local Drift caching and sync mutation queues.
class OnlineServantRepository implements ServantRepository {
  const OnlineServantRepository(this._remote);

  final SupabaseServantRepository _remote;

  @override
  Stream<List<ServantProfile>> watchForService(String serviceId) async* {
    yield await _remote.fetchForService(serviceId);
  }

  @override
  Future<void> refresh(String serviceId) async {
    await _remote.fetchForService(serviceId);
  }

  @override
  Future<void> createProfile({
    required String id,
    required String serviceId,
    required String authUserId,
    required String name,
    required String phone,
    required String role,
    String? stageId,
    String? classId,
  }) {
    return _remote.createProfile(
      id: id,
      serviceId: serviceId,
      authUserId: authUserId,
      name: name,
      phone: phone,
      role: role,
      stageId: stageId,
      classId: classId,
    );
  }

  @override
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
  }) {
    return _remote.updateProfile(
      servantId: servantId,
      name: name,
      phone: phone,
      birthDate: birthDate,
      workStudy: workStudy,
      role: role,
      stageId: stageId,
      classId: classId,
      accountStatus: accountStatus,
    );
  }

  @override
  Future<void> deleteProfile(String servantId) {
    return _remote.deleteProfile(servantId);
  }
}
