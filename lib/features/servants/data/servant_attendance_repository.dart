import 'package:supabase_flutter/supabase_flutter.dart';

class ServantAttendanceRecord {
  const ServantAttendanceRecord({
    required this.id,
    required this.meetingId,
    required this.servantProfileId,
    required this.checkedInAt,
    required this.recordedBy,
  });

  final String id;
  final String meetingId;
  final String servantProfileId;
  final DateTime checkedInAt;
  final String recordedBy;

  factory ServantAttendanceRecord.fromJson(Map<String, dynamic> row) =>
      ServantAttendanceRecord(
        id: row['id'] as String,
        meetingId: row['meeting_id'] as String,
        servantProfileId: row['servant_profile_id'] as String,
        checkedInAt: DateTime.parse(row['checked_in_at'] as String),
        recordedBy: row['recorded_by'] as String,
      );
}

/// Servant attendance is stored directly in Supabase. Only the database RLS
/// policy grants write access to an active overall leader.
class ServantAttendanceRepository {
  const ServantAttendanceRepository(this._client);

  final SupabaseClient _client;

  Future<List<ServantAttendanceRecord>> listForServant(
    String servantProfileId,
  ) async {
    final rows = await _client
        .from('servant_attendance_records')
        .select()
        .eq('servant_profile_id', servantProfileId)
        .order('checked_in_at', ascending: false);
    return (rows as List)
        .map((row) => ServantAttendanceRecord.fromJson(
              row as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> checkIn({
    required String meetingId,
    required String servantProfileId,
    required String recordedBy,
  }) async {
    await _client.from('servant_attendance_records').upsert({
      'meeting_id': meetingId,
      'servant_profile_id': servantProfileId,
      'recorded_by': recordedBy,
      'checked_in_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'meeting_id,servant_profile_id');
  }
}
