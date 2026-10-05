import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/system_admin_profile.dart';

class SystemAdminRepository {
  SystemAdminRepository(this._client);

  final SupabaseClient _client;

  Future<SystemAdminProfile?> getCurrentAdmin(String authUserId) async {
    final row = await _client
        .from('system_administrators')
        .select('id, auth_user_id, status')
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    if (row == null) return null;

    return SystemAdminProfile(
      id: row['id'] as String,
      authUserId: row['auth_user_id'] as String,
      status: row['status'] as String,
    );
  }
}
