import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../../auth/domain/entities/servant_profile.dart';
import '../domain/repositories/servant_repository.dart';
import 'local_servant_repository.dart';
import 'supabase_servant_repository.dart';

class OfflineFirstServantRepository implements ServantRepository {
  OfflineFirstServantRepository({
    required this.local,
    required this.remote,
    required this.queue,
  });

  final LocalServantRepository local;
  final SupabaseServantRepository remote;
  final SyncQueueRepository queue;

  @override
  Stream<List<ServantProfile>> watchForService(String serviceId) =>
      local.watchForService(serviceId);

  @override
  Future<void> refresh(String serviceId) async {
    final values = await remote.fetchForService(serviceId);
    await local.cacheProfiles(values);
  }

  @override
  Future<void> createProfile({
    required String id,
    required String serviceId,
    required String authUserId,
    required String name,
    required String phone,
    required String role,
    String? stageId,
    String? classId,
  }) async {
    await remote.createProfile(
      id: id,
      serviceId: serviceId,
      authUserId: authUserId,
      name: name,
      phone: phone,
      role: role,
      stageId: stageId,
      classId: classId,
    );
  }

  @override
  Future<ServantProfile> updateProfile({
    required String servantId,
    required String name,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String role,
    String? stageId,
    String? classId,
    required String accountStatus,
  }) async {
    final updated = await local.updateProfile(
      servantId: servantId,
      name: name,
      phone: phone,
      birthDate: birthDate,
      workStudy: workStudy,
      role: role,
      stageId: stageId,
      classId: classId,
      accountStatus: accountStatus,
    );

    await queue.enqueue(
      SyncOperation(
        operationId: const Uuid().v4(),
        entityType: 'servant',
        operationType: 'update',
        payloadJson: jsonEncode({
          'id': updated.id,
          'service_id': updated.serviceId,
          'name': updated.name,
          'phone': updated.phone,
          'birth_date': updated.birthDate?.toIso8601String().split('T').first,
          'work_study': updated.workStudy,
          'role': updated.role,
          'stage_id': updated.stageId,
          'class_id': updated.classId,
          'account_status': updated.accountStatus,
        }),
      ),
    );

    return updated;
  }

  @override
  Future<void> deleteProfile(String servantId) async {
    await local.deleteProfile(servantId);
    await queue.enqueue(
      SyncOperation(
        operationId: const Uuid().v4(),
        entityType: 'servant',
        operationType: 'delete',
        payloadJson: jsonEncode({'id': servantId}),
      ),
    );
  }
}
