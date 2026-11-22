import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_repository.dart';
import '../domain/entities/service_student.dart';
import 'local_service_student_repository.dart';

/// Offline-first access to service membership records.
///
/// Remote reads are service-scoped by RLS; all reads exposed to the UI come
/// from Drift so the same view remains available without connectivity.
class OfflineFirstServiceStudentRepository {
  OfflineFirstServiceStudentRepository({
    required SupabaseClient client,
    required AppDatabase database,
    required SyncQueueRepository queue,
  }) : _client = client,
       local = LocalServiceStudentRepository(database, queue);

  final SupabaseClient _client;
  final LocalServiceStudentRepository local;

  Stream<List<ServiceStudent>> watchForService(String serviceId) =>
      local.watchForService(serviceId);

  Future<void> refresh(String serviceId) async {
    final rows = await _client
        .from('service_students')
        .select(
          'id,student_id,service_id,class_id,proposed_class_id,enrollment_date,status,school,grade,is_deacon,notes',
        )
        .eq('service_id', serviceId)
        .order('enrollment_date');
    await local.cache(
      rows.map((row) => ServiceStudent.fromMap(row)).toList(),
    );
  }

  Future<void> saveOffline(ServiceStudent membership) =>
      local.saveOffline(membership);

  Future<void> archiveOffline(ServiceStudent membership) =>
      local.archiveOffline(membership);
}
