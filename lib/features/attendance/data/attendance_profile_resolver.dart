import 'package:supabase_flutter/supabase_flutter.dart';

Future<String> resolveAttendanceRecorderProfileId(
  SupabaseClient client, {
  required String meetingId,
  required String preferredProfileId,
}) async {
  final authUserId = client.auth.currentUser?.id;
  if (authUserId == null) {
    throw StateError('يجب تسجيل الدخول لتسجيل الحضور.');
  }

  final meeting = await client
      .from('meetings')
      .select('service_id')
      .eq('id', meetingId)
      .single();
  final profiles = await client
      .from('servant_profiles')
      .select('id')
      .eq('auth_user_id', authUserId)
      .eq('service_id', meeting['service_id'] as String)
      .eq('account_status', 'active');
  if ((profiles as List).isEmpty) {
    throw StateError('لا يوجد ملف خادم نشط مرتبط بهذه الخدمة.');
  }

  final rows = profiles.cast<Map<String, dynamic>>();
  for (final profile in rows) {
    if (profile['id'] == preferredProfileId) return profile['id'] as String;
  }
  return rows.first['id'] as String;
}
