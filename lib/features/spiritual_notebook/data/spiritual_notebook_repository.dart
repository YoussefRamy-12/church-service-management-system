import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/weekly_period.dart';

class SpiritualNotebookRepository {
  SpiritualNotebookRepository(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> students(
    String serviceId,
  ) async => List<Map<String, dynamic>>.from(
    await _client
        .from('students')
        .select(
          'id,name,current_class_id,classes!students_current_class_id_fkey(id,name,stage_id,stages(name))',
        )
        .eq('service_id', serviceId)
        .eq('approval_status', 'approved')
        .order('name'),
  );

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
  ) async => List<Map<String, dynamic>>.from(
    await _client
        .from('spiritual_notebook_submissions')
        .select(
          'id,student_id,period_start,total_points,bonus_points,submitted_at',
        )
        .eq('service_id', serviceId),
  );

  Future<void> submit({
    required String studentId,
    required WeeklyPeriod period,
    required List<String> activityIds,
    required int bonusPoints,
    String? bonusReason,
  }) async {
    await _client.rpc(
      'submit_spiritual_notebook',
      params: {
        'p_student_id': studentId,
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
