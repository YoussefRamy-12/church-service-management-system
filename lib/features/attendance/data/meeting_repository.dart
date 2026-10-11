import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/meeting.dart';
import '../../service/domain/entities/service.dart';
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

  Future<Meeting> create({required String serviceId, required DateTime date, required String startTime, String? id}) async {
    id ??= const Uuid().v4();
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

  Future<void> ensureConfiguredSchedule(Service service) async {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    final existing = await local.watchMeetings(service.id).first;
    final existingDates = existing.map((meeting) => _dateKey(meeting.meetingDate)).toSet();
    final endDate = DateTime(firstDay.year, firstDay.month + 12, firstDay.day);
    final parts = service.meetingStartTime.split(':');
    final time = '${parts.first.padLeft(2, '0')}:${(parts.length > 1 ? parts[1] : '00').padLeft(2, '0')}:00';

    for (var date = firstDay; !date.isAfter(endDate); date = date.add(const Duration(days: 1))) {
      final scheduled = service.meetingFrequency == 'monthly'
          ? date.day == service.meetingMonthDay.clamp(1, DateTime(date.year, date.month + 1, 0).day)
          : date.weekday == service.meetingWeekday;
      if (!scheduled || existingDates.contains(_dateKey(date))) continue;
      final dateKey = _dateKey(date);
      final id = const Uuid().v5(Uuid.NAMESPACE_URL, '${service.id}:$dateKey');
      await create(serviceId: service.id, date: date, startTime: time, id: id);
      existingDates.add(dateKey);
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
