import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/session_identity.dart';
import 'servant_profile_repository.dart';
import 'system_admin_repository.dart';

class SessionIdentityRepository {
  SessionIdentityRepository(SupabaseClient client)
    : _servants = ServantProfileRepository(client),
      _admins = SystemAdminRepository(client);

  final ServantProfileRepository _servants;
  final SystemAdminRepository _admins;

  Future<SessionIdentity?> resolve(String authUserId) async {
    final admin = await _admins.getCurrentAdmin(authUserId);
    if (admin != null && admin.isActive) {
      return SuperAdminIdentity(admin);
    }

    final profiles = (await _servants.getCurrentProfiles(
      authUserId,
    )).where((profile) => profile.isActive).toList();
    if (profiles.length == 1) return ServantIdentity(profiles.single);
    if (profiles.length > 1) return MultiServiceServantIdentity(profiles);

    final registration = await _servants.getRegistrationRequest(authUserId);
    if (registration != null) {
      return PendingServantIdentity(
        name: registration['full_name'] as String? ?? 'خادم',
        status: registration['status'] as String? ?? 'pending',
        phone: registration['phone'] as String?,
        birthDate: registration['birth_date'] == null
            ? null
            : DateTime.tryParse(registration['birth_date'] as String),
        workStudy: registration['work_study'] as String?,
      );
    }
    return null;
  }
}
