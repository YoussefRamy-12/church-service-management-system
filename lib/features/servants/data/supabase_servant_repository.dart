import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/domain/entities/servant_profile.dart';

class SupabaseServantRepository {
  SupabaseServantRepository(this._client);

  final SupabaseClient _client;

  Future<List<ServantProfile>> fetchForService(String serviceId) async {
    final rows = await _client
        .from('servant_profiles')
        .select(
          'id, auth_user_id, service_id, name, phone, birth_date, work_study, role, account_status, stage_id, class_id, must_change_password',
        )
        .eq('service_id', serviceId)
        .order('name');

    return (rows as List)
        .map((row) => _map(row as Map<String, dynamic>))
        .toList();
  }

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
  }) async {
    final rows = await _client
        .from('servant_profiles')
        .update({
          'name': name,
          'phone': phone,
          'birth_date': birthDate.toIso8601String().split('T').first,
          'work_study': workStudy,
          'role': role,
          'stage_id': stageId,
          'class_id': classId,
          'account_status': accountStatus,
        })
        .eq('id', servantId)
        .select(
          'id, auth_user_id, service_id, name, phone, birth_date, work_study, role, account_status, stage_id, class_id, must_change_password',
        );

    if (rows.isEmpty) {
      throw const PostgrestException(
        message: 'Servant update was rejected or is no longer accessible.',
      );
    }

    return _map(rows.first);
  }

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
