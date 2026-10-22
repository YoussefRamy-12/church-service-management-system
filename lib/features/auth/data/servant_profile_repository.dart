import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/servant_profile.dart';

class ServantProfileRepository {
  ServantProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ServantProfile?> getCurrentProfile(String authUserId) async {
    final row = await _client
        .from('servant_profiles')
        .select(
          'id, auth_user_id, service_id, name, phone, birth_date, work_study, role, account_status, stage_id, class_id, must_change_password',
        )
        .eq('auth_user_id', authUserId)
        .maybeSingle();

    if (row == null) return null;

    return ServantProfile(
      id: row['id'] as String,
      authUserId: row['auth_user_id'] as String,
      serviceId: row['service_id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      birthDate: row['birth_date'] == null
          ? null
          : DateTime.parse(row['birth_date'] as String),
      workStudy: row['work_study'] as String?,
      role: row['role'] as String,
      accountStatus: row['account_status'] as String,
      stageId: row['stage_id'] as String?,
      classId: row['class_id'] as String?,
      mustChangePassword: row['must_change_password'] as bool? ?? false,
    );
  }

  Future<List<ServantProfile>> getCurrentProfiles(String authUserId) async {
    final rows = await _client
        .from('servant_profiles')
        .select(
          'id, auth_user_id, service_id, name, phone, birth_date, work_study, role, account_status, stage_id, class_id, must_change_password',
        )
        .eq('auth_user_id', authUserId)
        .order('name');
    return rows.map(_map).toList();
  }

  Future<Map<String, dynamic>?> getRegistrationRequest(
    String authUserId,
  ) => _client
      .from('servant_registration_requests')
      .select(
        'auth_user_id, full_name, phone, birth_date, work_study, status, created_at',
      )
      .eq('auth_user_id', authUserId)
      .maybeSingle();

  ServantProfile _map(Map<String, dynamic> row) => ServantProfile(
    id: row['id'] as String,
    authUserId: row['auth_user_id'] as String,
    serviceId: row['service_id'] as String,
    name: row['name'] as String,
    phone: row['phone'] as String?,
    birthDate: row['birth_date'] == null
        ? null
        : DateTime.parse(row['birth_date'] as String),
    workStudy: row['work_study'] as String?,
    role: row['role'] as String,
    accountStatus: row['account_status'] as String,
    stageId: row['stage_id'] as String?,
    classId: row['class_id'] as String?,
    mustChangePassword: row['must_change_password'] as bool? ?? false,
  );
}
