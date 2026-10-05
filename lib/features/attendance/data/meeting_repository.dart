import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/meeting.dart';
import 'local_meeting_repository.dart';

class MeetingRepository {
  MeetingRepository(this.local, this.client, this.queue);
  final LocalMeetingRepository local;
  final SupabaseClient client;
  final SyncQueueRepository queue;

  Stream<List<Meeting>> watchMeetings(String serviceId) => local.watchMeetings(serviceId);

  Future<void> refresh(String serviceId) async {
    final rows = await client.from('meetings').select('id, service_id, meeting_date, start_time').eq('service_id', serviceId).order('meeting_date', ascending: false);
    await local.cacheMeetings(rows.map((r) => Meeting(id: r['id'] as String, serviceId: r['service_id'] as String, meetingDate: DateTime.parse(r['meeting_date'].toString()), startTime: r['start_time'] as String)).toList());
  }

  Future<Meeting> create({required String serviceId, required DateTime date, required String startTime}) async {
    final id = const Uuid().v4();
    final item = Meeting(id: id, serviceId: serviceId, meetingDate: date, startTime: startTime);
    await local.cacheMeetings([item]);
    await queue.enqueue(SyncOperation(
      operationId: const Uuid().v4(),
      entityType: 'meeting',
      operationType: 'insert',
      payloadJson: jsonEncode({
        'id': id,
        'service_id': serviceId,
        'meeting_date': date.toIso8601String().substring(0, 10),
        'start_time': startTime,
      }),
    ));
    return item;
  }
}
