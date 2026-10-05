import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/meeting.dart';
import 'local_meeting_repository.dart';

class MeetingRepository {
  MeetingRepository(this.local, this.client);
  final LocalMeetingRepository local;
  final SupabaseClient client;

  Stream<List<Meeting>> watchMeetings(String serviceId) => local.watchMeetings(serviceId);

  Future<void> refresh(String serviceId) async {
    final rows = await client.from('meetings').select('id, service_id, meeting_date, start_time').eq('service_id', serviceId).order('meeting_date', ascending: false);
    await local.cacheMeetings(rows.map((r) => Meeting(id: r['id'] as String, serviceId: r['service_id'] as String, meetingDate: DateTime.parse(r['meeting_date'].toString()), startTime: r['start_time'] as String)).toList());
  }

  Future<Meeting> create({required String serviceId, required DateTime date, required String startTime}) async {
    final row = await client.from('meetings').insert({'service_id': serviceId, 'meeting_date': date.toIso8601String().substring(0, 10), 'start_time': startTime}).select('id, service_id, meeting_date, start_time').single();
    final item = Meeting(id: row['id'] as String, serviceId: row['service_id'] as String, meetingDate: DateTime.parse(row['meeting_date'].toString()), startTime: row['start_time'] as String);
    await local.cacheMeetings([item]);
    return item;
  }
}
