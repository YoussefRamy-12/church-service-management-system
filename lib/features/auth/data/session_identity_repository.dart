import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/session_identity.dart';
import 'servant_profile_repository.dart';
import 'system_admin_repository.dart';

class SessionIdentityRepository {
  SessionIdentityRepository(this._client)
      : _servants = ServantProfileRepository(_client),
        _admins = SystemAdminRepository(_client);

  final SupabaseClient _client;
  final ServantProfileRepository _servants;
  final SystemAdminRepository _admins;

  Future<SessionIdentity?> resolve(String authUserId) async {
    final admin = await _admins.getCurrentAdmin(authUserId);
    if (admin != null && admin.isActive) {
      return SuperAdminIdentity(admin);
    }

    final servant = await _servants.getCurrentProfile(authUserId);
    if (servant == null || !servant.isActive) {
      return null;
    }

    return ServantIdentity(servant);
  }
}
