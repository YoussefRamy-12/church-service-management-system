import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../domain/entities/service.dart';
import '../domain/entities/service_class.dart';
import '../domain/entities/stage.dart';
import '../domain/repositories/service_repository.dart';
import 'local_service_repository.dart';
import 'supabase_service_repository.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';

class OfflineFirstServiceRepository implements ServiceRepository {
  OfflineFirstServiceRepository({
    required this.local,
    required this.remote,
    required this.queue,
  });

  final LocalServiceRepository local;
  final SupabaseServiceRepository remote;
  final SyncQueueRepository queue;

  Future<void> updateMeetingStartTime({
    required String serviceId,
    required String meetingStartTime,
  }) async {
    await local.updateMeetingStartTime(
      serviceId: serviceId,
      meetingStartTime: meetingStartTime,
    );
    await queue.enqueue(
      SyncOperation(
        operationId: 'service-settings-$serviceId',
        entityType: 'service',
        operationType: 'update',
        payloadJson: jsonEncode({
          'id': serviceId,
          'meeting_start_time': meetingStartTime,
        }),
      ),
    );
  }

  Future<void> refreshReportingPeriods(String serviceId) async {
    final rows = await remote.fetchReportingPeriods(serviceId);
    await local.cacheReportingPeriods(
      rows.map((row) => CachedReportingPeriodsCompanion.insert(
        id: row['id'] as String,
        serviceId: row['service_id'] as String,
        name: row['name'] as String,
        type: row['type'] as String,
        startDate: row['start_date'] as String,
        endDate: row['end_date'] as String,
        cachedAt: DateTime.now(),
      )).toList(),
    );
  }

  Future<List<CachedReportingPeriod>> getReportingPeriods(
    String serviceId,
  ) => local.getReportingPeriods(serviceId);

  @override
  Future<Service?> getService(String serviceId) async {
    final cached = await local.getService(serviceId);
    if (cached != null) return cached;

    final remoteValue = await remote.getService(serviceId);
    if (remoteValue != null) {
      await local.cacheService(remoteValue);
    }
    return remoteValue;
  }

  @override
  Stream<List<Stage>> watchStages(String serviceId) => local.watchStages(serviceId);

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) => local.watchClasses(stageId);

  Future<void> refreshStages(String serviceId) async {
    final values = await remote.fetchStages(serviceId);
    await local.cacheStages(values);
  }

  Future<void> refreshClasses(String stageId) async {
    final values = await remote.fetchClasses(stageId);
    await local.cacheClasses(values);
  }
}
