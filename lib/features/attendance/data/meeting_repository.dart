import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/connectivity_service_impl.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/meeting.dart';
import '../domain/repositories/meeting_repository.dart';
import '../../service/domain/entities/service.dart';
import 'local_meeting_repository.dart';

class OfflineFirstMeetingRepository implements MeetingRepository {
  OfflineFirstMeetingRepository(
    this.local,
    this.client,
    this.queue, [
    ConnectivityService? connectivity,
  ]) : _connectivity = connectivity ?? ConnectivityServiceImpl();

  final LocalMeetingRepository local;
  final SupabaseClient client;
  final SyncQueueRepository queue;
  final ConnectivityService _connectivity;

  @override
  Stream<List<Meeting>> watchMeetings(String serviceId) =>
      local.watchMeetings(serviceId);

  @override
  Future<void> refresh(String serviceId) async {
    final rows = await client
        .from('meetings')
        .select('id, service_id, meeting_date, start_time, name, schedule_id')
        .eq('service_id', serviceId)
        .order('meeting_date', ascending: true);
    await local.clearMeetings(serviceId);
    await local.cacheMeetings(
      rows
          .map(
            (r) => Meeting(
              id: r['id'] as String,
              serviceId: r['service_id'] as String,
              meetingDate: DateTime.parse(r['meeting_date'].toString()),
              startTime: r['start_time'] as String,
              name: (r['name'] as String?) ?? 'اجتماع الخدمة',
              scheduleId: r['schedule_id'] as String?,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<Meeting> create({
    required String serviceId,
    required DateTime date,
    required String startTime,
    String name = 'اجتماع الخدمة',
    String? scheduleId,
    String? id,
  }) async {
    id ??= const Uuid().v4();
    final item = Meeting(
      id: id,
      serviceId: serviceId,
      meetingDate: date,
      startTime: startTime,
      name: name,
      scheduleId: scheduleId,
    );

    final isOnline = await _connectivity.isOnline;
    if (isOnline) {
      final existing = await client
          .from('meetings')
          .select('id, service_id, meeting_date, start_time, name, schedule_id')
          .eq('service_id', serviceId)
          .eq('meeting_date', _dateKey(date));
      Map<String, dynamic>? matched;
      for (final raw in existing) {
        final row = Map<String, dynamic>.from(raw as Map);
        final sameSchedule = scheduleId != null
            ? row['schedule_id'] == scheduleId
            : row['schedule_id'] == null &&
                ((row['name'] as String?) ?? 'اجتماع الخدمة') == name;
        if (sameSchedule) {
          matched = row;
          break;
        }
      }
      if (matched != null) {
        final row = matched;
        final shared = Meeting(
          id: row['id'] as String,
          serviceId: row['service_id'] as String,
          meetingDate: DateTime.parse(row['meeting_date'].toString()),
          startTime: row['start_time'] as String,
          name: (row['name'] as String?) ?? 'اجتماع الخدمة',
          scheduleId: row['schedule_id'] as String?,
        );
        await local.cacheMeetings([shared]);
        return shared;
      }
      await client.from('meetings').upsert({
        'id': id,
        'service_id': serviceId,
        'meeting_date': _dateKey(date),
        'start_time': startTime,
        'name': name,
        'schedule_id': scheduleId,
      }, onConflict: 'id');
      await local.cacheMeetings([item]);
      return item;
    }

    await local.cacheMeetings([item]);
    await queue.enqueue(
      SyncOperation(
        operationId: const Uuid().v4(),
        entityType: 'meeting',
        operationType: 'insert',
        payloadJson: jsonEncode({
          'id': id,
          'service_id': serviceId,
          'meeting_date': _dateKey(date),
          'start_time': startTime,
          'name': name,
          'schedule_id': scheduleId,
        }),
      ),
    );
    return item;
  }

  @override
  Future<void> ensureConfiguredSchedule(Service service) async {
    var schedule = await client
        .from('meeting_schedules')
        .select('id, name, frequency, weekday, month_day, start_time')
        .eq('service_id', service.id)
        .eq('name', 'اجتماع الخدمة')
        .maybeSingle();

    if (schedule == null) {
      schedule = await client.from('meeting_schedules').insert({
        'service_id': service.id,
        'name': 'اجتماع الخدمة',
        'frequency': service.meetingFrequency,
        'weekday': service.meetingWeekday,
        'month_day': service.meetingMonthDay,
        'start_time': service.meetingStartTime,
      }).select('id, name, frequency, weekday, month_day, start_time').single();
    }

    await client.from('meeting_schedules').update({
      'frequency': service.meetingFrequency,
      'weekday': service.meetingWeekday,
      'month_day': service.meetingMonthDay,
      'start_time': service.meetingStartTime,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', schedule['id'] as String);
    schedule = {
      ...schedule,
      'frequency': service.meetingFrequency,
      'weekday': service.meetingWeekday,
      'month_day': service.meetingMonthDay,
      'start_time': service.meetingStartTime,
    };
    final scheduleId = schedule['id'] as String;
    final rows = await client
        .from('meetings')
        .select('meeting_date')
        .eq('service_id', service.id)
        .eq('schedule_id', scheduleId);
    final existingDates = rows
        .map((r) => r['meeting_date'].toString().split('T').first)
        .toSet();
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(firstDay.year, firstDay.month + 12, firstDay.day);
    final parts = (schedule['start_time'] as String).split(':');
    final time =
        '${parts.first.padLeft(2, '0')}:${(parts.length > 1 ? parts[1] : '00').padLeft(2, '0')}:00';

    for (
      var date = firstDay;
      !date.isAfter(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      final scheduled = schedule['frequency'] == 'monthly'
          ? date.day == (schedule['month_day'] as int).clamp(
              1, DateTime(date.year, date.month + 1, 0).day)
          : date.weekday == schedule['weekday'];
      final dateKey = _dateKey(date);
      if (!scheduled || existingDates.contains(dateKey)) continue;
      final id = const Uuid().v5(Namespace.url.value, '${scheduleId}:$dateKey');
      await create(
        serviceId: service.id,
        date: date,
        startTime: time,
        name: schedule['name'] as String,
        scheduleId: scheduleId,
        id: id,
      );
      existingDates.add(dateKey);
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
