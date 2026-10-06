import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../../auth/domain/entities/servant_profile.dart';
import 'local_servant_repository.dart';
import 'supabase_servant_repository.dart';

class OfflineFirstServantRepository {
  OfflineFirstServantRepository({
    required this.local,
    required this.remote,
    required this.queue,
  });

  final LocalServantRepository local;
  final SupabaseServantRepository remote;
  final SyncQueueRepository queue;

  Stream<List<ServantProfile>> watchForService(String serviceId) =>
      local.watchForService(serviceId);

  Future<void> refresh(String serviceId) async {
    final values = await remote.fetchForService(serviceId);
    await local.cacheProfiles(values);
  }

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
}
