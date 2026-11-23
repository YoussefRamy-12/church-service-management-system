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
  return selectAttendanceRecorderProfileId(
    preferredProfileId: preferredProfileId,
    eligibleProfiles: rows,
  );
}

/// Keeps the original recorder identity when replaying an offline check-in.
/// If that profile is not available to the signed-in account in this service,
/// defer replay instead of attributing the historical action to another user.
String selectAttendanceRecorderProfileId({
  required String preferredProfileId,
  required List<Map<String, dynamic>> eligibleProfiles,
}) {
  if (eligibleProfiles.isEmpty) {
    throw StateError('لا يوجد ملف خادم نشط مرتبط بهذه الخدمة.');
  }

  for (final profile in eligibleProfiles) {
    if (profile['id'] == preferredProfileId) {
      return profile['id'] as String;
    }
  }

  throw StateError(
    'Queued attendance belongs to another account or an inactive service profile; '
    'sign in with the original account to sync it.',
  );
}
