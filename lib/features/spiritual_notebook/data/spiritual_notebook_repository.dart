import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/weekly_period.dart';

class SpiritualNotebookRepository {
  SpiritualNotebookRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> students(
    String serviceId,
  ) async {
    final directoryRows = List<Map<String, dynamic>>.from(
      await _client.rpc(
        'get_service_student_directory',
        params: {'p_service_id': serviceId},
      ),
    );
    // Notebook submissions are available only for active service memberships.
    final rows = directoryRows
        .where((row) => row['membership_status'] == 'active')
        .toList();

    final classIds = rows
        .map((row) => row['class_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final classById = <String, Map<String, dynamic>>{};
    if (classIds.isNotEmpty) {
      final classes = List<Map<String, dynamic>>.from(
        await _client
            .from('classes')
            .select('id,name,stage_id,stages(name)')
            .inFilter('id', classIds),
      );
      for (final row in classes) {
        classById[row['id'] as String] = row;
      }
    }

    return rows.map((row) {
      final membershipId = row['membership_id'] as String;
      final classId = row['class_id'] as String?;
      return <String, dynamic>{
        // Keep the view model key stable, but it now identifies a membership.
        'id': membershipId,
        'membership_id': membershipId,
        'student_id': row['student_id'] as String,
        'service_id': row['service_id'] as String,
        'identity_service_id': row['identity_service_id'] as String?,
        'name': row['student_name'] as String? ?? '',
        'current_class_id': classId,
        'proposed_class_id': row['proposed_class_id'] as String?,
        'classes': classId == null ? null : classById[classId],
        'membership_status': row['membership_status'] as String,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> activities(String serviceId) async =>
      List<Map<String, dynamic>>.from(
        await _client
            .from('spiritual_notebook_activities')
            .select('id,name,description,points,category_id,display_order')
            .eq('service_id', serviceId)
            .eq('is_active', true)
            .order('display_order'),
      );

  Future<Map<String, dynamic>?> settings(String serviceId) => _client
      .from('spiritual_notebook_settings')
      .select()
      .eq('service_id', serviceId)
      .maybeSingle();

  Future<List<Map<String, dynamic>>> submissions(
    String serviceId,
  ) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client
          .from('spiritual_notebook_submissions')
          .select(
            'id,student_id,service_student_id,period_start,total_points,bonus_points,submitted_at',
          )
          .eq('service_id', serviceId),
    );
    return rows.map((row) => {
      ...row,
      // The notebook view is keyed by membership, not global identity.
      'student_id': row['service_student_id'],
    }).toList();
  }

  Future<void> submit({
    required String membershipId,
    required WeeklyPeriod period,
    required List<String> activityIds,
    required int bonusPoints,
    String? bonusReason,
  }) async {
    await _client.rpc(
      'submit_spiritual_notebook',
      params: {
        'p_service_student_id': membershipId,
        'p_period_start': _date(period.start),
        'p_activity_ids': activityIds,
        'p_bonus_points': bonusPoints,
        'p_bonus_reason': bonusReason,
      },
    );
  }

  Future<void> addActivity(String serviceId, String name, int points) async {
    await _client.from('spiritual_notebook_activities').insert({
      'service_id': serviceId,
      'name': name.trim(),
      'points': points,
    });
  }

  Future<void> updateActivity({
    required String activityId,
    required String name,
    required int points,
  }) async {
    await _client.from('spiritual_notebook_activities').update({
      'name': name.trim(),
      'points': points,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', activityId);
  }

  Future<void> deleteActivity(String activityId) async {
    // Soft delete: sets is_active = false so that it no longer appears for future
    // submissions while preserving all past weeks' submission records, snapshots, and scores.
    await _client.from('spiritual_notebook_activities').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', activityId);
  }

  Future<void> upsertSettings(
    String serviceId, {
    required int maxBonus,
    required List<String> bonusRoles,
  }) async {
    await _client.from('spiritual_notebook_settings').upsert({
      'service_id': serviceId,
      'max_bonus_points': maxBonus,
      'bonus_roles': bonusRoles,
    });
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
