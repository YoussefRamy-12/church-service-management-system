import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/service.dart';
import '../domain/entities/service_class.dart';
import '../domain/entities/stage.dart';
import '../domain/repositories/service_repository.dart';
import 'supabase_service_repository.dart';

/// Online-only implementation of [ServiceRepository].
///
/// Dispatches directly to Supabase without local Drift caching or sync queues.
class OnlineServiceRepository implements ServiceRepository {
  const OnlineServiceRepository({
    required SupabaseServiceRepository remote,
    required SupabaseClient client,
  }) : _remote = remote,
       _client = client;

  final SupabaseServiceRepository _remote;
  final SupabaseClient _client;

  @override
  Future<Service?> getService(String serviceId) => _remote.getService(serviceId);

  @override
  Stream<List<Stage>> watchStages(String serviceId) =>
      _remote.watchStages(serviceId);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) =>
      _remote.watchClasses(stageId);

  @override
  Future<List<Stage>> getStages(String serviceId) =>
      _remote.fetchStages(serviceId);

  @override
  Future<List<ServiceClass>> getClasses(String stageId) =>
      _remote.fetchClasses(stageId);

  @override
  Future<void> deleteStage(String id) async {
    final rows = await _client.from('stages').delete().eq('id', id).select('id');
    if (rows.isEmpty) {
      throw StateError('Stage deletion was rejected by server or not found.');
    }
  }

  @override
  Future<void> deleteClass(String id) async {
    final rows = await _client.from('classes').delete().eq('id', id).select('id');
    if (rows.isEmpty) {
      throw StateError('Class deletion was rejected by server or not found.');
    }
  }

  @override
  Future<void> updateMeetingStartTime({
    required String serviceId,
    required String meetingStartTime,
  }) => _remote.updateMeetingStartTime(
    serviceId: serviceId,
    meetingStartTime: meetingStartTime,
  );

  @override
  Future<void> updateMeetingSchedule({
    required String serviceId,
    required String meetingStartTime,
    required String meetingFrequency,
    required int meetingWeekday,
    required int meetingMonthDay,
  }) => _remote.updateMeetingSchedule(
    serviceId: serviceId,
    meetingStartTime: meetingStartTime,
    meetingFrequency: meetingFrequency,
    meetingWeekday: meetingWeekday,
    meetingMonthDay: meetingMonthDay,
  );

  @override
  Future<void> refreshStages(String serviceId) =>
      _remote.fetchStages(serviceId);

  @override
  Future<void> refreshClasses(String stageId) =>
      _remote.fetchClasses(stageId);

  @override
  Future<void> refreshReportingPeriods(String serviceId) =>
      _remote.fetchReportingPeriods(serviceId);

  @override
  Future<List<CachedReportingPeriod>> getReportingPeriods(
    String serviceId,
  ) async {
    final rows = await _remote.fetchReportingPeriods(serviceId);
    return rows
        .map(
          (row) => CachedReportingPeriod(
            id: row['id'] as String,
            serviceId: row['service_id'] as String,
            name: row['name'] as String,
            type: row['type'] as String,
            startDate: row['start_date'] as String,
            endDate: row['end_date'] as String,
            cachedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  @override
  Future<void> addReportingPeriod({
    required String serviceId,
    required String name,
    required String type,
    required String startDate,
    required String endDate,
  }) async {
    final id = const Uuid().v4();
    await _client.from('reporting_periods').insert({
      'id': id,
      'service_id': serviceId,
      'name': name,
      'type': type,
      'start_date': startDate,
      'end_date': endDate,
    });
  }
}
