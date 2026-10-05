import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/service.dart';
import '../domain/entities/service_class.dart';
import '../domain/entities/stage.dart';
import '../domain/repositories/service_repository.dart';

class SupabaseServiceRepository implements ServiceRepository {
  SupabaseServiceRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Service?> getService(String serviceId) async {
    final row = await _client
        .from('services')
        .select('id, name, church_name, meeting_start_time')
        .eq('id', serviceId)
        .maybeSingle();

    if (row == null) return null;

    return Service(
      id: row['id'] as String,
      name: row['name'] as String,
      churchName: row['church_name'] as String,
      meetingStartTime: row['meeting_start_time'] as String,
    );
  }

  @override
  Stream<List<Stage>> watchStages(String serviceId) async* {
    yield await fetchStages(serviceId);
  }

  Future<List<Stage>> fetchStages(String serviceId) async {
    final rows = await _client
        .from('stages')
        .select('id, service_id, name')
        .eq('service_id', serviceId)
        .order('name');

    return rows
        .map(
          (row) => Stage(
            id: row['id'] as String,
            serviceId: row['service_id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  @override
  Stream<List<ServiceClass>> watchClasses(String stageId) async* {
    yield await fetchClasses(stageId);
  }

  Future<List<ServiceClass>> fetchClasses(String stageId) async {
    final rows = await _client
        .from('classes')
        .select('id, stage_id, name')
        .eq('stage_id', stageId)
        .order('name');

    return rows
        .map(
          (row) => ServiceClass(
            id: row['id'] as String,
            stageId: row['stage_id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }
}
